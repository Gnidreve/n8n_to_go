import '../api_client.dart';

Future<Map<String, dynamic>> retryExecution(
  String id, {
  bool loadWorkflow = true,
}) {
  return const ApiClient().post(
    '/executions/$id/retry',
    body: {'loadWorkflow': loadWorkflow},
  );
}
