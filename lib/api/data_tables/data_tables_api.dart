import 'get.dart';
import 'get_all.dart';
import 'rows/rows_api.dart';

class DataTablesApi {
  const DataTablesApi();

  final rows = const DataTableRowsApi();

  Future<Map<String, dynamic>> get(String id) {
    return getDataTable(id);
  }

  Future<Map<String, dynamic>> getAll() {
    return getAllDataTables();
  }
}
