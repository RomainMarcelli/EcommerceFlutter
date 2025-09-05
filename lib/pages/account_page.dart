import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/app_scaffold.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _nameCtrl = TextEditingController();
  bool _loadingName = false;
  bool _loadingVerify = false;
  bool _loadingDelete = false;

  @override
  void initState() {
    super.initState();
    final u = FirebaseAuth.instance.currentUser;
    _nameCtrl.text = u?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  User get _user => FirebaseAuth.instance.currentUser!;

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return "Email invalide.";
      case 'email-already-in-use':
        return "Email déjà utilisé.";
      case 'requires-recent-login':
        return "Action sensible : reconnecte-toi.";
      case 'wrong-password':
        return "Mot de passe actuel incorrect.";
      case 'user-mismatch':
        return "L’utilisateur ne correspond pas.";
      case 'user-not-found':
        return "Utilisateur introuvable.";
      case 'network-request-failed':
        return "Problème réseau. Réessaie.";
      default:
        return e.message ?? e.code;
    }
  }

  Future<void> _updateDisplayName() async {
    setState(() => _loadingName = true);
    try {
      await _user.updateDisplayName(_nameCtrl.text.trim());
      await _user.reload();
      _showSnack('Nom mis à jour ✅');
    } on FirebaseAuthException catch (e) {
      _showSnack('Erreur: ${_mapAuthError(e)}');
    } finally {
      if (mounted) setState(() => _loadingName = false);
    }
  }

  Future<void> _sendVerifyEmail() async {
    setState(() => _loadingVerify = true);
    try {
      await _user.sendEmailVerification();
      _showSnack('Email de vérification envoyé 📧');
    } on FirebaseAuthException catch (e) {
      _showSnack('Erreur: ${_mapAuthError(e)}');
    } finally {
      if (mounted) setState(() => _loadingVerify = false);
    }
  }

  Future<void> _changeEmail() async {
    final emailCtrl = TextEditingController(text: _user.email ?? '');
    final pwdCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Changer d’email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Nouvel email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pwdCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe actuel',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Valider')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final cred = EmailAuthProvider.credential(email: _user.email!, password: pwdCtrl.text);
      await _user.reauthenticateWithCredential(cred);
      await _user.updateEmail(emailCtrl.text.trim());
      await _user.sendEmailVerification();
      _showSnack('Email mis à jour. Vérifie ta boîte mail 📧');
      setState(() {}); // refresh UI
    } on FirebaseAuthException catch (e) {
      _showSnack('Erreur: ${_mapAuthError(e)}');
    }
  }

  Future<void> _changePassword() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          bool obscure1 = true, obscure2 = true, obscure3 = true;
          return AlertDialog(
            title: const Text('Changer le mot de passe'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PwdField(label: 'Mot de passe actuel', controller: currentCtrl, obscure: obscure1,
                    onToggle: () => setStateDialog(() => obscure1 = !obscure1)),
                const SizedBox(height: 12),
                _PwdField(label: 'Nouveau mot de passe', controller: newCtrl, obscure: obscure2,
                    onToggle: () => setStateDialog(() => obscure2 = !obscure2)),
                const SizedBox(height: 12),
                _PwdField(label: 'Confirmer le nouveau', controller: confirmCtrl, obscure: obscure3,
                    onToggle: () => setStateDialog(() => obscure3 = !obscure3)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Mettre à jour')),
            ],
          );
        },
      ),
    );
    if (ok != true) return;

    if (newCtrl.text.length < 6) {
      _showSnack('Le nouveau mot de passe doit faire au moins 6 caractères.');
      return;
    }
    if (newCtrl.text != confirmCtrl.text) {
      _showSnack('La confirmation ne correspond pas.');
      return;
    }

    try {
      final cred = EmailAuthProvider.credential(email: _user.email!, password: currentCtrl.text);
      await _user.reauthenticateWithCredential(cred);
      await _user.updatePassword(newCtrl.text);
      _showSnack('Mot de passe mis à jour ✅');
    } on FirebaseAuthException catch (e) {
      _showSnack('Erreur: ${_mapAuthError(e)}');
    }
  }

  Future<void> _deleteAccount() async {
    final pwdCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Cette action est irréversible. Entrez votre mot de passe pour confirmer."),
            const SizedBox(height: 12),
            TextField(
              controller: pwdCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe actuel',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _loadingDelete = true);
    try {
      final cred = EmailAuthProvider.credential(email: _user.email!, password: pwdCtrl.text);
      await _user.reauthenticateWithCredential(cred);
      await _user.delete();
      if (!mounted) return;
      _showSnack('Compte supprimé');
      // L’authStateChanges() te renverra vers /login automatiquement
    } on FirebaseAuthException catch (e) {
      _showSnack('Erreur: ${_mapAuthError(e)}');
    } finally {
      if (mounted) setState(() => _loadingDelete = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final email = user.email ?? '—';
    final verified = user.emailVerified;
    final photo = user.photoURL;

    return AppScaffold(
      title: 'Mon compte',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: (photo != null && photo.isNotEmpty) ? NetworkImage(photo) : null,
                child: (photo == null || photo.isEmpty)
                    ? Text((user.displayName?.isNotEmpty ?? false)
                        ? user.displayName!.characters.first.toUpperCase()
                        : (email.isNotEmpty ? email.characters.first.toUpperCase() : '?'))
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(email, style: Theme.of(context).textTheme.titleMedium),
                    verified
                        ? const Chip(label: Text('Email vérifié'), avatar: Icon(Icons.verified, size: 16))
                        : const Chip(label: Text('Email non vérifié'), avatar: Icon(Icons.warning_amber, size: 16)),
                    if (!verified)
                      FilledButton.tonal(
                        onPressed: _loadingVerify ? null : _sendVerifyEmail,
                        child: _loadingVerify
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Vérifier mon email'),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),

          // Nom d'affichage
          Text('Nom d’affichage', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Votre nom',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _loadingName ? null : _updateDisplayName,
                child: _loadingName
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Enregistrer'),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(),

          // Sécurité
          Text('Sécurité', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.alternate_email),
            title: const Text('Changer d’email'),
            subtitle: Text(email),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changeEmail,
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Changer le mot de passe'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changePassword,
          ),

          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
            title: const Text('Supprimer mon compte'),
            textColor: Colors.red,
            iconColor: Colors.red,
            trailing: _loadingDelete
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right),
            onTap: _loadingDelete ? null : _deleteAccount,
          ),
        ],
      ),
    );
  }
}

class _PwdField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const _PwdField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
        ),
      ),
    );
  }
}
