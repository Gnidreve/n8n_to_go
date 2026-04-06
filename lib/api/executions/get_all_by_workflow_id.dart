import '../api_client.dart';

Future<Map<String, dynamic>> getAllExecutionsByWorkflowId(String workflowId) {
  return const ApiClient().get(
    '/executions',
    queryParameters: {'workflowId': workflowId},
  );
}
