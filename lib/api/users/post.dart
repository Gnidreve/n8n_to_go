import '../api_client.dart';

Future<List<dynamic>> postUser(Map<String, dynamic> body) {
  return const ApiClient().postArray('/users', body: [body]);
}
