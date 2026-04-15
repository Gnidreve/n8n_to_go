import '../api_client.dart';

Future<void> deleteExecution(String id) {
  return const ApiClient().delete('/executions/$id');
}
