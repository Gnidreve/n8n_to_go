import '../api_client.dart';

Future<int> postAudit({
  required String baseUrl,
  required String apiKey,
}) {
  return const ApiClient().postStatus(
    '/audit',
    baseUrl: baseUrl,
    apiKey: apiKey,
  );
}
