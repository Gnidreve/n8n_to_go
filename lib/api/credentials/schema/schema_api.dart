import 'get.dart';

class CredentialsSchemaApi {
  const CredentialsSchemaApi();

  Future<Map<String, dynamic>> get(String credentialTypeName) {
    return getCredentialSchema(credentialTypeName);
  }
}
