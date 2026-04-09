/// Central datetime formatting utility.
/// Output format: "17.09.2017 - 17:30"
String formatDateTime(DateTime? value) {
  if (value == null) return '—';
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day.$month.$year - $hour:$minute';
}

/// Parses an ISO-8601 string to a local DateTime, returns null on failure.
DateTime? parseDateTime(dynamic value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}

/// Convenience: parse + format in one call.
String formatDateTimeString(dynamic value) {
  return formatDateTime(parseDateTime(value));
}
