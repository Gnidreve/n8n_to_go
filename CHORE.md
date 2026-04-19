# Chore: Credential Type Consistency

This file documents the recurring maintenance task for credential-type consistency.

## Goal

Keep these three sources aligned at all times:

1. The `type` string returned by the n8n API
2. The right-hand programmatic value in `lib/CREDENTIAL_TYPES.dart`
3. The icon asset file name in `lib/assets/credentials/`

The API `type` is the single source of truth.

## Hard rules

- Never treat the left-hand display label in `lib/CREDENTIAL_TYPES.dart` as the source of truth.
- Never adapt the app logic to a mismatched asset file name.
- Always adapt `lib/CREDENTIAL_TYPES.dart` and asset file names to the API `type`.
- The right-hand value in `lib/CREDENTIAL_TYPES.dart` must match the API `type` exactly, including casing.
- Credential icon files must use the exact API type as the base filename.
- Allowed exact-name icon files are:
  - `lib/assets/credentials/<type>.svg`
  - `lib/assets/credentials/<type>.png`
  - optional dark-mode variants:
  - `lib/assets/credentials/<type>.dark.svg`
  - `lib/assets/credentials/<type>.dark.png`
- If a `.dark.svg` or `.dark.png` file exists, it is a dedicated dark-theme asset, not a tint instruction.
- Do not introduce a manual mapping layer for icon lookup unless explicitly requested.

## Files involved

- `lib/CREDENTIAL_TYPES.dart`
- `lib/widgets/credential_icon.dart`
- `lib/assets/credentials/`

## What to do when checking consistency

1. Get the current credential `type` values from the real API response or from a current sample provided by the user.
2. For each relevant API `type`, verify that:
   - the type is present in `lib/CREDENTIAL_TYPES.dart` if it should be available in the create flow
   - the right-hand value in `lib/CREDENTIAL_TYPES.dart` exactly matches the API `type`
   - an icon exists at either `lib/assets/credentials/<type>.svg` or `lib/assets/credentials/<type>.png`
   - if a dark variant exists, it is named `lib/assets/credentials/<type>.dark.svg` or `lib/assets/credentials/<type>.dark.png`
3. Rename asset files to the API type when needed.
4. Uncomment or add entries in `lib/CREDENTIAL_TYPES.dart` when the type should be selectable in the create flow.
5. Comment out entries only when they should intentionally not be available in the create flow.
6. Re-run verification after the change.

## Decision policy

- If the API says `openAiApi`, then the programmatic type must be `openAiApi` and the icon file must be named exactly `openAiApi.svg` or `openAiApi.png`.
- If the asset currently exists under another name like `OpenAI.svg`, rename the asset. Do not change the type away from the API value.
- If the create-flow entry currently uses the wrong programmatic value, fix the right-hand value. Do not bend the asset rule around it.
- If a current API type has no exact asset yet, add or rename the closest correct asset. If no proper branded asset exists yet, use a temporary exact-name placeholder only when necessary and clearly note it.
- PNG and SVG are both valid. Do not force-convert a PNG to SVG just to satisfy the convention.

## Why this matters

- `CredentialTypeSelectPage` depends on `lib/CREDENTIAL_TYPES.dart` for the create flow.
- `CredentialIcon` resolves icons directly from the API type naming convention.
- Inconsistency between API type, credential type value, and asset file name causes missing icons, wrong create options, and unnecessary maintenance overhead.

## Expected end state

For every active credential type:

- API `type` == right-hand value in `lib/CREDENTIAL_TYPES.dart`
- API `type` == asset base filename in `lib/assets/credentials/`

Example:

- API: `httpBearerAuth`
- `lib/CREDENTIAL_TYPES.dart`: `'Bearer Auth': 'httpBearerAuth'`
- assets:
  - `lib/assets/credentials/httpBearerAuth.svg`
  - or `lib/assets/credentials/httpBearerAuth.png`
  - optional `lib/assets/credentials/httpBearerAuth.dark.svg`
  - optional `lib/assets/credentials/httpBearerAuth.dark.png`
