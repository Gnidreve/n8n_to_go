import '../api_client.dart';

Future<Map<String, dynamic>> postAuditReport({
  Map<String, dynamic>? body,
}) {
  return const ApiClient().post(
    '/audit',
    body: body,
  );
}
