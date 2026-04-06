import 'delete.dart';
import 'get_all.dart';
import 'insert.dart';
import 'update.dart';

class DataTableRowsApi {
  const DataTableRowsApi();

  Future<Map<String, dynamic>> getAll(
    String dataTableId, {
    int? limit,
    String? cursor,
    String? sortBy,
    String? search,
    String? filter,
  }) {
    return getAllDataTableRows(
      dataTableId,
      limit: limit,
      cursor: cursor,
      sortBy: sortBy,
      search: search,
      filter: filter,
    );
  }

  Future<Map<String, dynamic>> insert(
    String dataTableId, {
    required List<Map<String, dynamic>> data,
    String returnType = 'all',
  }) {
    return insertDataTableRows(
      dataTableId,
      data: data,
      returnType: returnType,
    );
  }

  Future<Map<String, dynamic>> update(
    String dataTableId, {
    required Map<String, dynamic> filter,
    required Map<String, dynamic> data,
    bool returnData = false,
    bool dryRun = false,
  }) {
    return updateDataTableRows(
      dataTableId,
      filter: filter,
      data: data,
      returnData: returnData,
      dryRun: dryRun,
    );
  }

  Future<void> delete(
    String dataTableId, {
    required String filter,
    bool returnData = false,
    bool dryRun = false,
  }) {
    return deleteDataTableRows(
      dataTableId,
      filter: filter,
      returnData: returnData,
      dryRun: dryRun,
    );
  }
}
