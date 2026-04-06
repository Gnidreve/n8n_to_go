import '../../api_client.dart';

Future<Map<String, dynamic>> getCredentialSchema(String credentialTypeName) {
  return const ApiClient().get('/credentials/schema/$credentialTypeName');
}
