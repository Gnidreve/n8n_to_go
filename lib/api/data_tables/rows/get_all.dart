import '../../api_client.dart';

Future<Map<String, dynamic>> getAllDataTableRows(
  String dataTableId, {
  int? limit,
  String? cursor,
  String? sortBy,
  String? search,
  String? filter,
}) {
  return const ApiClient().get(
    '/data-tables/$dataTableId/rows',
    queryParameters: {
      'limit': limit,
      'cursor': cursor,
      'sortBy': sortBy,
      'search': search,
      'filter': filter,
    },
  );
}
