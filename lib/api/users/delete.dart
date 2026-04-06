import '../api_client.dart';

Future<void> deleteUser(String id) {
  return const ApiClient().delete('/users/$id');
}
