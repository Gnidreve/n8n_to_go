import '../api_client.dart';

Future<Map<String, dynamic>> patchCredential(
  String id,
  Map<String, dynamic> body,
) {
  return const ApiClient().patch('/credentials/$id', body: body);
}
