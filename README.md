# tp_ecommerce

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# test

## Déploiement

- **GitHub Pages** : https://romainmarcelli.github.io/EcommerceFlutter/
  - Déployé automatiquement via GitHub Actions (branche `main`).
  - Build : `flutter build web --release --pwa-strategy offline-first --base-href "/EcommerceFlutter/"`.

### Comment ça marche
1. À chaque `push` sur `main`, l’action build l’app web.
2. Les fichiers de `build/web` sont publiés sur GitHub Pages.
3. L’URL publique : https://romainmarcelli.github.io/EcommerceFlutter/
