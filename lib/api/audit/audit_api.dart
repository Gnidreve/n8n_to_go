import 'post.dart';

class AuditApi {
  const AuditApi();

  Future<int> post({
    required String baseUrl,
    required String apiKey,
  }) {
    return postAudit(
      baseUrl: baseUrl,
      apiKey: apiKey,
    );
  }
}
