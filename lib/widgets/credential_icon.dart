import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _credentialIconsRoot = 'lib/assets/credentials';
const _credentialFallbackIcon = 'lib/assets/appbar-logo.svg';

class CredentialIcon extends StatefulWidget {
  const CredentialIcon({
    super.key,
    required this.type,
    this.size = 24,
  });

  final String? type;
  final double size;

  @override
  State<CredentialIcon> createState() => _CredentialIconState();
}

class _CredentialIconState extends State<CredentialIcon> {
  static final Map<String, Future<bool>> _assetExistsCache = {};

  Future<bool>? _assetExists;

  @override
  void initState() {
    super.initState();
    _assetExists = _loadAssetExists();
  }

  @override
  void didUpdateWidget(CredentialIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type) {
      _assetExists = _loadAssetExists();
    }
  }

  Future<bool> _loadAssetExists() {
    final assetPath = _assetPathForType(widget.type);
    if (assetPath == null) {
      return Future.value(false);
    }

    return _assetExistsCache.putIfAbsent(assetPath, () async {
      try {
        await rootBundle.load(assetPath);
        return true;
      } catch (_) {
        return false;
      }
    });
  }

  String? _assetPathForType(String? type) {
    final normalizedType = type?.trim();
    if (normalizedType == null || normalizedType.isEmpty) {
      return null;
    }

    return '$_credentialIconsRoot/$normalizedType.svg';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _assetExists,
      initialData: false,
      builder: (context, snapshot) {
        final assetPath = snapshot.data == true
            ? _assetPathForType(widget.type)
            : _credentialFallbackIcon;

        return SvgPicture.asset(
          assetPath ?? _credentialFallbackIcon,
          width: widget.size,
          height: widget.size,
        );
      },
    );
  }
}
