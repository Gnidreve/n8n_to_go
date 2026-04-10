import '../api_client.dart';

Future<Map<String, dynamic>> getAllDataTables() {
  return const ApiClient().get('/data-tables');
}
