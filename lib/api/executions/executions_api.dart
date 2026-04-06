import 'get_all.dart';
import 'get_all_by_workflow_id.dart';

class ExecutionsApi {
  const ExecutionsApi();

  Future<Map<String, dynamic>> getAll() {
    return getAllExecutions();
  }

  Future<Map<String, dynamic>> getAllByWorkflowId(String workflowId) {
    return getAllExecutionsByWorkflowId(workflowId);
  }
}
