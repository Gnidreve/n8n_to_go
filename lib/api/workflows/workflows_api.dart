import 'get.dart';
import 'get_all.dart';
import 'delete.dart';

class WorkflowsApi {
  const WorkflowsApi();

  Future<Map<String, dynamic>> getAll() {
    return getAllWorkflows();
  }

  Future<Map<String, dynamic>> get(String id) {
    return getWorkflow(id);
  }

  Future<void> delete(String id) {
    return deleteWorkflow(id);
  }
}
