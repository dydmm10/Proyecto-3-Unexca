# Flutter Login (Flutter + Node.js + MariaDB)

Proyecto de login y registro en Flutter conectado a backend Node.js/Express.

## Requisitos

- Flutter SDK
- Node.js LTS (incluye `node` y `npm`)
- MariaDB o MySQL

## 1) Levantar backend

Ver guía completa en [backend/README.md](backend/README.md).

## 2) Ejecutar Flutter

1. Instala dependencias:

```bash
flutter pub get
```

2. Ejecuta la app:

```bash
flutter run
```

## URL del backend según plataforma

- Web / Windows / Linux / macOS: `http://localhost:3000`
- Emulador Android: `http://10.0.2.2:3000`

Actualmente `AuthService` está configurado con `http://localhost:3000` en:
- [lib/main.dart](lib/main.dart)
- [lib/register_page.dart](lib/register_page.dart)

Si usas emulador Android, cambia temporalmente esa URL en ambos archivos.
