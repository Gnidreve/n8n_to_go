import '../api_client.dart';

Future<Map<String, dynamic>> postCredential(Map<String, dynamic> body) {
  return const ApiClient().post('/credentials', body: body);
}
