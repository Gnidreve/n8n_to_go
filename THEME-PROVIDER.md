# Theme Provider

How the theme system works in this project and how to replicate it in another Flutter + shadcn_ui project.

---

## Color scheme

This project uses **Zinc** as the base color palette — the same as shadcn/ui's default Zinc scale in Tailwind/CSS projects.

### What Zinc is

Zinc is a neutral gray-toned scale (not warm like Stone/Sand, not cool like Slate). It maps to Tailwind's `zinc-*` values:

| Tailwind token | Approx hex  | Used for          |
|----------------|-------------|-------------------|
| zinc-50        | `#fafafa`   | light backgrounds |
| zinc-100       | `#f4f4f5`   | muted surfaces    |
| zinc-200       | `#e4e4e7`   | borders (light)   |
| zinc-400       | `#a1a1aa`   | muted foreground  |
| zinc-700       | `#3f3f46`   | dark borders      |
| zinc-800       | `#27272a`   | dark surfaces     |
| zinc-900       | `#18181b`   | dark card         |
| zinc-950       | `#09090b`   | dark foreground   |

In `shadcn_ui` Flutter this is `ShadZincColorScheme.light()` / `ShadZincColorScheme.dark()`.

### Project overrides on top of Zinc

The app customises a small number of tokens on top of the Zinc base:

| Token               | Light                  | Dark                   | Purpose                      |
|---------------------|------------------------|------------------------|------------------------------|
| `background`        | `#FCFCFC`              | `#171717`              | slightly off-white / near-black |
| `card`              | `#FFFFFF`              | `#212121`              | card surface                 |
| `primary`           | `#FF4B33`              | `#FF4B33`              | n8n brand red                |
| `primaryForeground` | `#171717`              | `#171717`              | text on brand red            |

Everything else — `border`, `mutedForeground`, `destructive`, `ring`, etc. — stays at the Zinc defaults.

### Why not Neutral?

Tailwind's **Neutral** scale is nearly identical to Zinc but slightly warmer. Shadcn/ui's web default ships Neutral; this project explicitly uses Zinc (`ShadZincColorScheme`) because it renders better with the JetBrains Mono typeface at small sizes.

If you are porting this to a project that already uses Neutral, swap `ShadZincColorScheme` for `ShadNeutralColorScheme` — the structure is identical, only the exact hex values differ slightly.

---

## Stack

- **shadcn_ui** — provides `ShadApp`, `ShadThemeData`, `ShadColorScheme`, `ShadTextTheme`
- **google_fonts** — JetBrains Mono as the global typeface
- **Flutter ThemeMode** — stored in `PreferencesService`, applied at the `ShadApp` level

---

## Entry point: `lib/main.dart`

`ShadApp` is the root widget. It replaces the standard `MaterialApp`:

```dart
ShadApp(
  theme: appTheme,          // light
  darkTheme: appDarkTheme,  // dark
  themeMode: PreferencesService.instance.themeMode,  // system | light | dark
  materialThemeBuilder: (context, theme) {
    // bridge: make Material widgets (AppBar, etc.) read the shadcn theme
    final shadTheme = ShadTheme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: shadTheme.colorScheme.card,
        ...
      ),
    );
  },
  home: const SplashPage(),
)
```

`materialThemeBuilder` is the key bridge — it lets native Flutter widgets pick up shadcn color tokens so they don't fall back to the Material default blue.

---

## Theme definitions: `lib/styles.dart`

Both themes are `ShadThemeData` instances:

```dart
final appTheme = ShadThemeData(
  brightness: Brightness.light,
  colorScheme: const ShadZincColorScheme.light().copyWith(
    background: Color(0xFFFCFCFC),
    card:        Color(0xFFFFFFFF),
    primary:     Color(0xFFFF4B33),   // n8n brand red
    primaryForeground: Color(0xFF171717),
  ),
  textTheme: ShadTextTheme.fromGoogleFont(_jbm),  // JetBrains Mono
  radius: BorderRadius.circular(6.72),
  primaryToastTheme:     ShadToastTheme(alignment: Alignment.bottomCenter),
  destructiveToastTheme: ShadToastTheme(alignment: Alignment.bottomCenter),
);
```

Dark theme mirrors this with dark values:
- `background`: `Color(0xFF171717)`
- `card`:        `Color(0xFF212121)`

---

## Accessing theme values inside widgets

```dart
final theme = ShadTheme.of(context);

// Colors
theme.colorScheme.background
theme.colorScheme.foreground
theme.colorScheme.card
theme.colorScheme.border          // used for AppBar bottom border
theme.colorScheme.mutedForeground // secondary text
theme.colorScheme.destructive     // error red
theme.colorScheme.primary         // brand color

// Shape
theme.radius  // BorderRadius — use for InkWell / Card borderRadius
```

Never hardcode colors in widgets. Always read from `ShadTheme.of(context)`.

---

## Toggle persistence: `lib/services/preferences_service.dart`

`PreferencesService` is a `ChangeNotifier` singleton backed by `shared_preferences`:

```dart
PreferencesService.instance.themeMode         // current ThemeMode
PreferencesService.instance.setThemeMode(mode) // persists + notifies
```

`MainApp` listens to `PreferencesService` and calls `setState` on change, which re-evaluates the `themeMode` prop on `ShadApp` — Flutter then switches themes automatically.

```dart
// in _MainAppState.initState:
PreferencesService.instance.addListener(_onPrefsChanged);

void _onPrefsChanged() {
  _applySystemUI(); // sync status/nav bar colors
  setState(() {});  // triggers ShadApp rebuild with new themeMode
}
```

---

## System UI sync

`_applySystemUI()` in `_MainAppState` calls `SystemChrome.setSystemUIOverlayStyle` to keep the Android status bar and navigation bar in sync with the active theme:

```dart
SystemChrome.setSystemUIOverlayStyle(
  isDark
    ? SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0xFF171717), // == darkBackground
        statusBarIconBrightness: Brightness.light,
      )
    : SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0xFFfafafa),
        statusBarIconBrightness: Brightness.dark,
      ),
);
```

Also called in `didChangePlatformBrightness` to handle OS-level changes when using `ThemeMode.system`.

---

## Applying this in another project

1. Add the same dependencies: `shadcn_ui`, `google_fonts`, `shared_preferences`.
2. Copy `styles.dart` — adjust brand colors and radii as needed.
3. Replace `MaterialApp` with `ShadApp` using `theme` / `darkTheme` / `themeMode`.
4. Add `materialThemeBuilder` to bridge AppBar and other Material widgets.
5. Create a `PreferencesService` (ChangeNotifier + shared_preferences) and wire its `themeMode` into `ShadApp`.
6. Call `SystemChrome.setSystemUIOverlayStyle` in the root widget to keep system bars in sync.
7. In all widgets: use `ShadTheme.of(context).colorScheme.*` — never hardcode colors.

The toggle will work correctly as long as `ShadApp` re-builds when the stored `ThemeMode` changes. The `ChangeNotifier` + `setState` pattern in step 5 is what makes this happen.
