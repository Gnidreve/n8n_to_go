import '../api_client.dart';

Future<Map<String, dynamic>> getUser(
  String id, {
  bool includeRole = false,
}) {
  return const ApiClient().get(
    '/users/$id',
    queryParameters: {
      'includeRole': includeRole,
    },
  );
}
