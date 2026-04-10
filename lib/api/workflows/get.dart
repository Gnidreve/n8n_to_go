import '../api_client.dart';

Future<Map<String, dynamic>> getWorkflow(String id) {
  return const ApiClient().get('/workflows/$id');
}
