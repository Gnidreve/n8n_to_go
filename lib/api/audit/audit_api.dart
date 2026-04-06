import 'report.dart';
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

  Future<Map<String, dynamic>> report({
    Map<String, dynamic>? body,
  }) {
    return postAuditReport(body: body);
  }
}
