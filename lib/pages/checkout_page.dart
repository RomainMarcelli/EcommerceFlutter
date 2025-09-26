import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../widgets/app_scaffold.dart';
import '../services/cart_service.dart';
import '../models/cart_item.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final items = cart.items;
    final total = cart.subtotal;

    return AppScaffold(
      title: 'Checkout',
      actions: const [_CartBadgeAction()],
      body: items.isEmpty
          ? const _EmptyCheckout()
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final it = items[i];
                      return ListTile(
                        leading:
                            (it.thumbnail != null && it.thumbnail!.isNotEmpty)
                            ? Image.network(
                                it.thumbnail!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image_outlined),
                        title: Text(
                          it.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${it.price.toStringAsFixed(2)} € • x${it.quantity}',
                        ),
                        trailing: Text(it.lineTotal.toStringAsFixed(2) + ' €'),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        top: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Total : ${total.toStringAsFixed(2)} €',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        FilledButton.icon(
                          icon: const Icon(Icons.lock),
                          label: const Text('Payer'),
                          onPressed: items.isEmpty
                              ? null
                              : () => showDialog(
                                  context: context,
                                  barrierDismissible: true,
                                  builder: (_) =>
                                      StripeLikePaymentDialog(total: total),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

//stripe interface
enum _PayMethod { card, ideal, bancontact }

class StripeLikePaymentDialog extends StatefulWidget {
  const StripeLikePaymentDialog({super.key, required this.total});
  final double total;

  @override
  State<StripeLikePaymentDialog> createState() =>
      _StripeLikePaymentDialogState();
}

class _StripeLikePaymentDialogState extends State<StripeLikePaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  _PayMethod _method = _PayMethod.card;

  final _card = TextEditingController();
  final _exp = TextEditingController();
  final _cvc = TextEditingController();

  bool _processing = false;

  @override
  void dispose() {
    _card.dispose();
    _exp.dispose();
    _cvc.dispose();
    super.dispose();
  }

  String get amountLabel => 'Payer ${widget.total.toStringAsFixed(2)} €';

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Paiement',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _MethodSelector(
                      value: _method,
                      onChanged: (m) => setState(() => _method = m),
                    ),
                    const SizedBox(height: 16),

                    if (_method == _PayMethod.card) ...[
                      // Card number
                      _StripeField(
                        label: 'Numéro de carte',
                        hint: '4242 4242 4242 4242',
                        controller: _card,
                        prefixIcon: Icons.credit_card,
                        trailing: const _BrandBadges(),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(19),
                          _CardNumberFormatter(),
                        ],
                        validator: (v) {
                          final digits = (v ?? '').replaceAll(' ', '');
                          if (digits.length < 16) return 'Numero invaldie';
                          if (!_luhnOk(digits)) return 'Carte non valide';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _StripeField(
                              label: 'Date Expiration',
                              hint: 'MM / YY',
                              controller: _exp,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                                _ExpiryFormatter(),
                              ],
                              validator: _validateExpiry,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StripeField(
                              label: 'Code Securité',
                              hint: 'CVC',
                              controller: _cvc,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              validator: (v) => (v == null || v.length < 3)
                                  ? 'CVC Invalide'
                                  : null,
                              suffixIcon: Icons.credit_card_outlined,
                            ),
                          ),
                        ],
                      ),
                    ] else
                      _MethodPlaceholder(method: _method),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _processing ? null : _onSubmit,
                        child: _processing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(amountLabel),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, size: 16, color: c.outline),
                        const SizedBox(width: 6),
                        Text(
                          'Paiement sécurisé',
                          style: TextStyle(color: c.outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSubmit() async {
    if (_method == _PayMethod.card) {
      final ok = _formKey.currentState?.validate() ?? false;
      if (!ok) return;
    }
    setState(() => _processing = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _processing = false);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Paiement validé ✅')));
  }

  bool _luhnOk(String digits) {
    int sum = 0;
    bool alt = false;
    for (int i = digits.length - 1; i >= 0; i--) {
      int n = int.parse(digits[i]);
      if (alt) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alt = !alt;
    }
    return sum % 10 == 0;
  }

  String? _validateExpiry(String? v) {
    if (v == null || v.length != 7 || !v.contains('/')) return 'Date Invalide';
    final mm = int.tryParse(v.substring(0, 2)) ?? -1;
    final yy = int.tryParse(v.substring(5, 7)) ?? -1;
    if (mm < 1 || mm > 12) return 'Mois Invalide';
    return null;
  }
}

class _MethodSelector extends StatelessWidget {
  const _MethodSelector({required this.value, required this.onChanged});
  final _PayMethod value;
  final ValueChanged<_PayMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    Widget chip(
      _PayMethod m,
      IconData icon,
      String label, {
      bool enabled = true,
    }) {
      final selected = value == m;
      return Expanded(
        child: InkWell(
          onTap: enabled ? () => onChanged(m) : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 44,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected ? c.primary.withOpacity(0.08) : c.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? c.primary : c.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? c.primary : c.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? c.primary : c.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(_PayMethod.card, Icons.credit_card, 'Carte'),
        const SizedBox(width: 8),
        chip(_PayMethod.ideal, Icons.account_balance, 'iDEAL', enabled: true),
        const SizedBox(width: 8),
        chip(
          _PayMethod.bancontact,
          Icons.account_balance_wallet_outlined,
          'bancontact',
          enabled: true,
        ),
      ],
    );
  }
}

class _StripeField extends StatelessWidget {
  const _StripeField({
    required this.label,
    required this.hint,
    required this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.trailing,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.centerRight,
          children: [
            TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              validator: validator,
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
                suffixIcon: suffixIcon != null
                    ? Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(suffixIcon),
                      )
                    : null,
                filled: true,
                fillColor: c.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: c.primary, width: 1.6),
                ),
              ),
            ),
            if (trailing != null) Positioned(right: 10, child: trailing!),
          ],
        ),
      ],
    );
  }
}

class _BrandBadges extends StatelessWidget {
  const _BrandBadges();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    Widget b(String t) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      margin: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.outlineVariant),
      ),
      child: Text(
        t,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
    return Row(children: [b('VISA'), b('MC'), b('AMEX'), b('CB')]);
  }
}

/// Placeholder pour iDEAL / bancontact (démo)
class _MethodPlaceholder extends StatelessWidget {
  const _MethodPlaceholder({required this.method});
  final _PayMethod method;

  @override
  Widget build(BuildContext context) {
    final name = method == _PayMethod.ideal ? 'iDEAL' : 'bancontact';
    final c = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.outlineVariant),
      ),
      child: Text('$name arrive bientot sur notre plateforme.'),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var t = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (t.length > 2) t = '${t.substring(0, 2)} / ${t.substring(2)}';
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

class _EmptyCheckout extends StatelessWidget {
  const _EmptyCheckout();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shopping_bag_outlined, size: 64),
          const SizedBox(height: 12),
          const Text('Aucun article à payer'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/catalog'),
            child: const Text('Retour au catalogue'),
          ),
        ],
      ),
    );
  }
}

class _CartBadgeAction extends StatelessWidget {
  const _CartBadgeAction();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Panier',
      icon: const Icon(Icons.shopping_cart_outlined),
      onPressed: () => Navigator.pushNamed(context, '/cart'),
    );
  }
}
