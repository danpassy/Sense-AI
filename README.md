# sens_ia

Isen Project

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# Sense-AI

## CI/CD

Le projet est maintenant prêt pour une base CI/CD avec GitHub Actions:

- CI: `.github/workflows/ci.yml`
  - Exécution sur `push` et `pull_request`
  - `flutter analyze --no-fatal-infos --no-fatal-warnings`
  - `flutter test`
  - Build APK release et upload en artifact
- CD release Android: `.github/workflows/release-android.yml`
  - Exécution sur push d'un tag `v*` (ex: `v1.0.0`)
  - Build APK release
  - Publication automatique d'une GitHub Release avec l'APK attaché

Exemple pour déclencher une release:

```bash
git tag v1.0.0
git push origin v1.0.0
```
