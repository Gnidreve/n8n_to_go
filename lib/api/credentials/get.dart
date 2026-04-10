import '../api_client.dart';

Future<Map<String, dynamic>> getCredential(String id) {
  return const ApiClient().get('/credentials/$id');
}
