import '../api_client.dart';

Future<Map<String, dynamic>> getExecution(
  String id, {
  bool includeData = false,
}) {
  return const ApiClient().get(
    '/executions/$id',
    queryParameters: {'includeData': includeData},
  );
}
