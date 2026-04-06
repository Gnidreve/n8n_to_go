import '../api_client.dart';

Future<Map<String, dynamic>> getAllWorkflows() {
  return const ApiClient().get('/workflows');
}
