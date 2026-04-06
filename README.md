# n8n to go (unofficial)

> An unofficial mobile client for [n8n](https://n8n.io) — browse workflows, monitor executions, and manage credentials from your Android device.

---

## Features

- **Workflows** — list all workflows, view details and execution history per workflow
- **Executions** — monitor recent executions across all workflows
- **Data Tables** — browse n8n data tables
- **Credentials** — list, inspect, create, update, and delete credentials with type-based SVG icons when a matching asset exists, using a type-selection step before the schema-driven create form opens
- **Settings** — configure your instance connection at runtime

---

## Getting started

### Prerequisites

- Flutter SDK `^3.11.0`
- An n8n instance with API access enabled
- An n8n API key ([how to create one](https://docs.n8n.io/api/authentication/))

### Option A — build-time credentials via `.env`

Create a `.env` file in the project root:

```env
BASE_URL=https://your-n8n-instance.com
API_KEY=your_api_key_here
```

These values are baked in at build time and will pre-fill the settings fields (which are then shown as read-only).

### Option B — runtime credentials

Leave `.env` empty or skip it entirely. On first launch the app shows a setup screen where you enter your Base URL and API Key. These are saved securely on the device and persist across restarts.

### Run

```bash
flutter pub get
flutter run
```

---

## Configuration & local storage

The app resolves credentials in the following priority order:

| Priority | Source | Details |
|----------|--------|---------|
| 1 (highest) | Device secure storage | Values entered by the user at runtime |
| 2 | `.env` file | `BASE_URL` and `API_KEY` set at build time |

If neither source has values, the app navigates to a setup screen before showing the home screen.

**Transparency — where data is stored:**

| What | How | Where in code |
|------|-----|---------------|
| Base URL & API Key | `flutter_secure_storage` (Android Keystore) | [`lib/services/config_service.dart`](lib/services/config_service.dart#L8) |
| Config resolution logic | `ConfigService.load()` | [`lib/services/config_service.dart`](lib/services/config_service.dart#L20) |
| First-launch gate | `SplashPage._init()` | [`lib/pages/splash_page.dart`](lib/pages/splash_page.dart#L18) |
| Setup screen | `SetupPage` | [`lib/pages/setup_page.dart`](lib/pages/setup_page.dart) |

No analytics, no external tracking, no data leaves your device beyond calls to your own n8n instance.

---

## Stack

| | |
|-|--|
| Framework | Flutter |
| UI components | [shadcn_ui](https://pub.dev/packages/shadcn_ui) |
| Font | JetBrains Mono via `google_fonts` |
| HTTP | `package:http` |
| Secure storage | `flutter_secure_storage` |
| Build-time config | `flutter_dotenv` |

---

## Roadmap

- Continued extraction of API calls into a reusable `lib/api` SDK-style layer

---

## Disclaimer

This is an **unofficial** app and is not affiliated with or endorsed by n8n GmbH.
