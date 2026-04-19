# n8n to go (unofficial)

> An unofficial mobile client for [n8n](https://n8n.io) — browse workflows, monitor executions, and manage credentials from your Android device.
>
> Source-available for noncommercial use under the [PolyForm Noncommercial License 1.0.0](LICENSE). This project is not released under an OSI-approved open source license.

---

## Features

- **Workflows** — list all workflows, view details and execution history per workflow
- **Executions** — monitor recent executions across all workflows, inspect execution details, and retry failed runs
- **Data Tables** — browse n8n data tables
- **Credentials** — list, inspect, create, update, and delete credentials with schema-driven create/edit form
- **Settings** — configure your instance connection, theme, and push notifications at runtime
- **Push Notifications** — enable FCM for the current Android device, copy the device token, receive foreground notifications in-app, and open failed execution details from notification taps

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

### Firebase Cloud Messaging setup

Push notifications are Android-first and require your own Firebase project.

1. Add your Firebase Android app config as `android/app/google-services.json`
2. Open the app, go to `Settings`, and enable `Push Notifications`
3. Copy the generated device token and use it in your n8n FCM request body
4. Send a test notification from n8n to verify delivery

---

**Transparency — where data is stored:**

| What                    | How                                         | Where in code                                                              |
| ----------------------- | ------------------------------------------- | -------------------------------------------------------------------------- |
| Base URL & API Key      | `flutter_secure_storage` (Android Keystore) | [`lib/services/config_service.dart`](lib/services/config_service.dart#L11) |
| Config resolution logic | `ConfigService.load()`                      | [`lib/services/config_service.dart`](lib/services/config_service.dart#L18) |
| Push notifications flag | `shared_preferences`                        | [`lib/services/preferences_service.dart`](lib/services/preferences_service.dart#L43) |
| FCM device token        | `shared_preferences`                        | [`lib/services/preferences_service.dart`](lib/services/preferences_service.dart#L50) |
| Push setup and handlers | `PushNotificationsService`                  | [`lib/services/push_notifications_service.dart`](lib/services/push_notifications_service.dart#L38) |
| First-launch gate       | `SplashPage._init()`                        | [`lib/pages/splash_page.dart`](lib/pages/splash_page.dart#L23)             |
| Setup screen            | `SetupPage`                                 | [`lib/pages/setup_page.dart`](lib/pages/setup_page.dart)                   |

No analytics, no external tracking, and no device token leaves your phone unless you explicitly copy it into your own n8n workflow.

---

## Stack

|                   |                                                 |
| ----------------- | ----------------------------------------------- |
| Framework         | Flutter                                         |
| UI components     | [shadcn_ui](https://pub.dev/packages/shadcn_ui) |
| HTTP              | `package:http`                                  |
| Secure storage    | `flutter_secure_storage`                        |
| Local preferences | `shared_preferences`                            |
| Push notifications| `firebase_core`, `firebase_messaging`           |
| Build-time config | `flutter_dotenv`                                |

---

## Roadmap

- Login via Autentification, not only API-Key
- Push-Notifications on Error or Success
- User Management directly in the app
- Dynamic Up to Date Widgets for your homescreen (android-first)
- Maybe Templates Integrations, but i dont think i will care about that when i get to it

- n8n chat after beta is completed

> [!NOTE]
> Support for basically everything the current n8n API allows, except features that are unavailable on freemium self-hosted instances, such as variables.

---

## Disclaimer

This is an **unofficial** app and is not affiliated with or endorsed by n8n GmbH.

## License

This project is source-available under the [PolyForm Noncommercial License 1.0.0](LICENSE).

You may use, copy, modify, and distribute this software for noncommercial purposes under that license. Commercial use is not permitted under this project's license.

This repository is not released under an OSI-approved open source license.
