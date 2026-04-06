import '../api_client.dart';

Future<Map<String, dynamic>> getAllUsers({
  int? limit,
  String? cursor,
  bool includeRole = false,
  String? projectId,
}) {
  return const ApiClient().get(
    '/users',
    queryParameters: {
      'limit': limit,
      'cursor': cursor,
      'includeRole': includeRole,
      'projectId': projectId,
    },
  );
}
