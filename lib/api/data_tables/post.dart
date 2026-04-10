import '../api_client.dart';

Future<Map<String, dynamic>> postDataTable({
  required String name,
  required List<Map<String, dynamic>> columns,
}) {
  return const ApiClient().post(
    '/data-tables',
    body: {
      'name': name,
      'columns': columns,
    },
  );
}
