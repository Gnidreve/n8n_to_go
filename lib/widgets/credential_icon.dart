import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _credentialIconsRoot = 'lib/assets/credentials';
const _credentialFallbackIcon = 'lib/assets/appbar-logo.svg';

class CredentialIcon extends StatefulWidget {
  const CredentialIcon({super.key, required this.type, this.size = 24});

  final String? type;
  final double size;

  @override
  State<CredentialIcon> createState() => _CredentialIconState();
}

class _CredentialIconState extends State<CredentialIcon> {
  static final Map<String, Future<bool>> _assetExistsCache = {};

  Future<String>? _resolvedAssetPath;
  Brightness? _lastBrightness;

  @override
  void initState() {
    super.initState();
    _resolvedAssetPath = Future.value(_credentialFallbackIcon);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    if (_lastBrightness != brightness) {
      _lastBrightness = brightness;
      _resolvedAssetPath = _resolveAssetPath();
    }
  }

  @override
  void didUpdateWidget(CredentialIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type) {
      _resolvedAssetPath = _resolveAssetPath();
    }
  }

  Future<bool> _assetExists(String assetPath) {
    return _assetExistsCache.putIfAbsent(assetPath, () async {
      try {
        await rootBundle.load(assetPath);
        return true;
      } catch (_) {
        return false;
      }
    });
  }

  Future<String> _resolveAssetPath() async {
    final lightAssetPath = _lightAssetPathForType(widget.type);
    if (lightAssetPath == null) {
      return _credentialFallbackIcon;
    }

    final prefersDark = _lastBrightness == Brightness.dark;
    final darkAssetPath = _darkAssetPathForType(widget.type);

    if (prefersDark &&
        darkAssetPath != null &&
        await _assetExists(darkAssetPath)) {
      return darkAssetPath;
    }

    if (await _assetExists(lightAssetPath)) {
      return lightAssetPath;
    }

    return _credentialFallbackIcon;
  }

  String? _lightAssetPathForType(String? type) {
    final normalizedType = type?.trim();
    if (normalizedType == null || normalizedType.isEmpty) {
      return null;
    }

    return '$_credentialIconsRoot/$normalizedType.svg';
  }

  String? _darkAssetPathForType(String? type) {
    final normalizedType = type?.trim();
    if (normalizedType == null || normalizedType.isEmpty) {
      return null;
    }

    return '$_credentialIconsRoot/$normalizedType.dark.svg';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _resolvedAssetPath,
      initialData: _credentialFallbackIcon,
      builder: (context, snapshot) {
        final assetPath = snapshot.data ?? _credentialFallbackIcon;

        return SvgPicture.asset(
          assetPath,
          width: widget.size,
          height: widget.size,
        );
      },
    );
  }
}
