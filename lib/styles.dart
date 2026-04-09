import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _brandPrimary = Color(0xFFFF4B33);
const _brandPrimaryForeground = Color(0xFF171717);
const _lightBackground = Color(0xFFFCFCFC);
const _lightCard = Color(0xFFFFFFFF);
const _darkBackground = Color(0xFF171717);
const _darkCard = Color(0xFF212121);

TextStyle _inter({
  TextStyle? textStyle,
  Color? color,
  Color? backgroundColor,
  double? fontSize,
  FontWeight? fontWeight,
  FontStyle? fontStyle,
  double? letterSpacing,
  double? wordSpacing,
  TextBaseline? textBaseline,
  double? height,
  Locale? locale,
  Paint? foreground,
  Paint? background,
  List<Shadow>? shadows,
  List<FontFeature>? fontFeatures,
  TextDecoration? decoration,
  Color? decorationColor,
  TextDecorationStyle? decorationStyle,
  double? decorationThickness,
}) => (textStyle ?? const TextStyle()).copyWith(
  fontFamily: 'InterVariable',
  fontFamilyFallback: const ['sans-serif'],
  color: color,
  backgroundColor: backgroundColor,
  fontSize: fontSize,
  fontStyle: fontStyle,
  fontWeight: fontWeight,
  letterSpacing: letterSpacing,
  wordSpacing: wordSpacing,
  textBaseline: textBaseline,
  height: height,
  locale: locale,
  foreground: foreground,
  background: background,
  shadows: shadows,
  fontFeatures: fontFeatures,
  decoration: decoration,
  decorationColor: decorationColor,
  decorationStyle: decorationStyle,
  decorationThickness: decorationThickness,
);

final appTheme = ShadThemeData(
  brightness: Brightness.light,
  colorScheme: const ShadZincColorScheme.light().copyWith(
    background: _lightBackground,
    card: _lightCard,
    primary: _brandPrimary,
    primaryForeground: _brandPrimaryForeground,
  ),
  textTheme: ShadTextTheme.fromGoogleFont(_inter),
  radius: BorderRadius.circular(6.72),
  primaryToastTheme: const ShadToastTheme(alignment: Alignment.bottomCenter),
  destructiveToastTheme: const ShadToastTheme(
    alignment: Alignment.bottomCenter,
  ),
);

final appDarkTheme = ShadThemeData(
  brightness: Brightness.dark,
  colorScheme: const ShadZincColorScheme.dark().copyWith(
    background: _darkBackground,
    card: _darkCard,
    primary: _brandPrimary,
    primaryForeground: _brandPrimaryForeground,
  ),
  textTheme: ShadTextTheme.fromGoogleFont(_inter),
  radius: BorderRadius.circular(6.72),
  primaryToastTheme: const ShadToastTheme(alignment: Alignment.bottomCenter),
  destructiveToastTheme: const ShadToastTheme(
    alignment: Alignment.bottomCenter,
  ),
);
