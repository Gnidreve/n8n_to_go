import '../api_client.dart';

Future<Map<String, dynamic>> getAllCredentials({
  int? limit,
}) {
  return const ApiClient().get(
    '/credentials',
    queryParameters: {
      'limit': limit,
    },
  );
}
