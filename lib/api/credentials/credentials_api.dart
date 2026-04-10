import 'delete.dart';
import 'get.dart';
import 'get_all.dart';
import 'patch.dart';
import 'post.dart';
import 'schema/schema_api.dart';

class CredentialsApi {
  const CredentialsApi();

  CredentialsSchemaApi get schema => const CredentialsSchemaApi();

  Future<Map<String, dynamic>> getAll({
    int? limit,
  }) {
    return getAllCredentials(limit: limit);
  }

  Future<Map<String, dynamic>> get(String id) {
    return getCredential(id);
  }

  Future<Map<String, dynamic>> post(Map<String, dynamic> body) {
    return postCredential(body);
  }

  Future<Map<String, dynamic>> patch(
    String id,
    Map<String, dynamic> body,
  ) {
    return patchCredential(id, body);
  }

  Future<void> delete(String id) {
    return deleteCredential(id);
  }
}
