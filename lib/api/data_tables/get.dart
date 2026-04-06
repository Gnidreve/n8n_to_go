import '../api_client.dart';

Future<Map<String, dynamic>> getDataTable(String id) {
  return const ApiClient().get('/data-tables/$id');
}
