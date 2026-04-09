import 'date_time_formatter.dart';

DateTime? parseExecutionDate(dynamic value) => parseDateTime(value);

String formatExecutionDateTime(DateTime? value) =>
    value == null ? 'Unknown date' : formatDateTime(value);

bool isExecutionError(Map<String, dynamic> item) {
  final raw = (item['status'] ?? '').toString().toLowerCase();
  return raw.contains('error') || raw.contains('fail');
}

String executionStatusLabel(Map<String, dynamic> item) {
  final raw = (item['status'] ?? '').toString();
  if (raw.isEmpty) return 'Unknown';
  return raw[0].toUpperCase() + raw.substring(1);
}

String executionDurationLabel(Map<String, dynamic> item) {
  final explicit = item['runTime'] ?? item['duration'] ?? item['executionTime'];
  if (explicit is num) {
    final seconds = explicit >= 1000 ? explicit / 1000 : explicit.toDouble();
    return _formatSeconds(seconds);
  }

  final startedAt = parseExecutionDate(item['startedAt']);
  final stoppedAt = parseExecutionDate(item['stoppedAt'] ?? item['finishedAt']);
  if (startedAt != null && stoppedAt != null) {
    final seconds = stoppedAt.difference(startedAt).inMilliseconds / 1000;
    return _formatSeconds(seconds);
  }

  return '—';
}

String _formatSeconds(double seconds) {
  if (seconds >= 10) return '${seconds.toStringAsFixed(2)}s';
  if (seconds >= 1) return '${seconds.toStringAsFixed(3)}s';
  return '${seconds.toStringAsFixed(0)}ms';
}
