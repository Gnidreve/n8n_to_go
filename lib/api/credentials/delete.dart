import '../api_client.dart';

Future<void> deleteCredential(String id) {
  return const ApiClient().delete('/credentials/$id');
}
