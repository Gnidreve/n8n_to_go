import 'delete.dart';
import 'get.dart';
import 'get_all.dart';

class UsersApi {
  const UsersApi();

  Future<Map<String, dynamic>> getAll({
    int? limit,
    String? cursor,
    bool includeRole = false,
    String? projectId,
  }) {
    return getAllUsers(
      limit: limit,
      cursor: cursor,
      includeRole: includeRole,
      projectId: projectId,
    );
  }

  Future<Map<String, dynamic>> get(
    String id, {
    bool includeRole = false,
  }) {
    return getUser(
      id,
      includeRole: includeRole,
    );
  }

  Future<void> delete(String id) {
    return deleteUser(id);
  }
}
