import 'get.dart';
import 'get_all.dart';
import 'post.dart';
import 'delete.dart';
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

  Future<Map<String, dynamic>> post({
    required String name,
    required List<Map<String, dynamic>> columns,
  }) {
    return postDataTable(
      name: name,
      columns: columns,
    );
  }

  Future<void> delete(String id) {
    return deleteDataTable(id);
  }
}
