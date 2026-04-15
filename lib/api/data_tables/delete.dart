import '../api_client.dart';

Future<void> deleteDataTable(String id) {
  return const ApiClient().delete('/data-tables/$id');
}
