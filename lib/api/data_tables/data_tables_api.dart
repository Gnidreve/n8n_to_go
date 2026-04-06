import 'get_all.dart';

class DataTablesApi {
  const DataTablesApi();

  Future<Map<String, dynamic>> getAll() {
    return getAllDataTables();
  }
}
