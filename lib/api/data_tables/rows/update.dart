import '../../api_client.dart';

Future<Map<String, dynamic>> updateDataTableRows(
  String dataTableId, {
  required Map<String, dynamic> filter,
  required Map<String, dynamic> data,
  bool returnData = false,
  bool dryRun = false,
}) {
  return const ApiClient().patch(
    '/data-tables/$dataTableId/rows/update',
    body: {
      'filter': filter,
      'data': data,
      'returnData': returnData,
      'dryRun': dryRun,
    },
  );
}
