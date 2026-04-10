import '../api_client.dart';

Future<Map<String, dynamic>> getAllExecutions() {
  return const ApiClient().get('/executions');
}
