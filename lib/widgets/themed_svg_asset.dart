import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ThemedSvgAsset extends StatelessWidget {
  const ThemedSvgAsset({
    super.key,
    required this.lightAsset,
    this.darkAsset,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final String lightAsset;
  final String? darkAsset;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final assetPath =
        brightness == Brightness.dark && (darkAsset?.isNotEmpty ?? false)
        ? darkAsset!
        : lightAsset;

    return SvgPicture.asset(assetPath, width: width, height: height, fit: fit);
  }
}
