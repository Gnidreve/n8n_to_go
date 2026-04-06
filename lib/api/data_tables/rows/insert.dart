import '../../api_client.dart';

Future<Map<String, dynamic>> insertDataTableRows(
  String dataTableId, {
  required List<Map<String, dynamic>> data,
  String returnType = 'all',
}) {
  return const ApiClient().post(
    '/data-tables/$dataTableId/rows',
    body: {
      'data': data,
      'returnType': returnType,
    },
  );
}
