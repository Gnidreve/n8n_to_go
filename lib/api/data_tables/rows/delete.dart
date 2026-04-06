import '../../api_client.dart';

Future<void> deleteDataTableRows(
  String dataTableId, {
  required String filter,
  bool returnData = false,
  bool dryRun = false,
}) {
  return const ApiClient().delete(
    '/data-tables/$dataTableId/rows/delete',
    queryParameters: {
      'filter': filter,
      'returnData': returnData,
      'dryRun': dryRun,
    },
  );
}
