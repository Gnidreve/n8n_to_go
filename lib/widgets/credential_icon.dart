import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _credentialIconsRoot = 'lib/assets/credentials';
const _credentialFallbackIcon = 'lib/assets/appbar-logo.svg';
const _credentialSupportedExtensions = ['svg', 'png'];

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
    final lightAssetPaths = _lightAssetPathsForType(widget.type);
    if (lightAssetPaths.isEmpty) {
      return _credentialFallbackIcon;
    }

    final prefersDark = _lastBrightness == Brightness.dark;
    final darkAssetPaths = _darkAssetPathsForType(widget.type);

    if (prefersDark) {
      for (final darkAssetPath in darkAssetPaths) {
        if (await _assetExists(darkAssetPath)) {
          return darkAssetPath;
        }
      }
    }

    for (final lightAssetPath in lightAssetPaths) {
      if (await _assetExists(lightAssetPath)) {
        return lightAssetPath;
      }
    }

    return _credentialFallbackIcon;
  }

  List<String> _lightAssetPathsForType(String? type) {
    final normalizedType = type?.trim();
    if (normalizedType == null || normalizedType.isEmpty) {
      return const [];
    }

    return _credentialSupportedExtensions
        .map((extension) => '$_credentialIconsRoot/$normalizedType.$extension')
        .toList(growable: false);
  }

  List<String> _darkAssetPathsForType(String? type) {
    final normalizedType = type?.trim();
    if (normalizedType == null || normalizedType.isEmpty) {
      return const [];
    }

    return _credentialSupportedExtensions
        .map(
          (extension) =>
              '$_credentialIconsRoot/$normalizedType.dark.$extension',
        )
        .toList(growable: false);
  }

  Widget _buildIcon(String assetPath) {
    final normalizedPath = assetPath.toLowerCase();

    if (normalizedPath.endsWith('.png')) {
      return Image.asset(
        assetPath,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      );
    }

    return SvgPicture.asset(
      assetPath,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _resolvedAssetPath,
      initialData: _credentialFallbackIcon,
      builder: (context, snapshot) {
        final assetPath = snapshot.data ?? _credentialFallbackIcon;

        return SizedBox.square(
          dimension: widget.size,
          child: _buildIcon(assetPath),
        );
      },
    );
  }
}
