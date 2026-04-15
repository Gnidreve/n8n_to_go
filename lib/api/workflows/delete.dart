import '../api_client.dart';

Future<void> deleteWorkflow(String id) {
  return const ApiClient().delete('/workflows/$id');
}
