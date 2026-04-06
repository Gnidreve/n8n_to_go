({String url, String port}) splitBaseUrl(String rawValue) {
  final normalizedValue = rawValue.trim();
  final uri = Uri.tryParse(normalizedValue);
  if (uri == null || uri.host.isEmpty) {
    return (url: normalizedValue, port: '');
  }

  final hasExplicitPort = normalizedValue.contains(':${uri.port}');
  return (
    url: uri.replace(port: null).toString().replaceAll(RegExp(r'/$'), ''),
    port: hasExplicitPort ? '${uri.port}' : '',
  );
}

String buildBaseUrl(String rawUrl, String rawPort) {
  final normalizedUrl = rawUrl.trim().replaceAll(RegExp(r'/$'), '');
  final uri = Uri.tryParse(normalizedUrl);
  if (uri == null || uri.host.isEmpty) return normalizedUrl;

  final port = rawPort.trim();
  if (port.isEmpty) {
    return uri.replace(port: null).toString().replaceAll(RegExp(r'/$'), '');
  }

  final parsedPort = int.tryParse(port);
  if (parsedPort == null) return normalizedUrl;
  return uri.replace(port: parsedPort).toString().replaceAll(RegExp(r'/$'), '');
}
