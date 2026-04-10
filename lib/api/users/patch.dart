import '../api_client.dart';

Future<Map<String, dynamic>> patchUser(
  String id,
  Map<String, dynamic> body,
) {
  return const ApiClient().patch('/users/$id', body: body);
}
