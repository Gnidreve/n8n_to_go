import 'get_all.dart';
import 'get_all_by_workflow_id.dart';
import 'get.dart';
import 'retry.dart';
import 'delete.dart';

class ExecutionsApi {
  const ExecutionsApi();

  Future<Map<String, dynamic>> getAll() {
    return getAllExecutions();
  }

  Future<Map<String, dynamic>> getAllByWorkflowId(String workflowId) {
    return getAllExecutionsByWorkflowId(workflowId);
  }

  Future<Map<String, dynamic>> get(String id, {bool includeData = false}) {
    return getExecution(id, includeData: includeData);
  }

  Future<Map<String, dynamic>> retry(String id, {bool loadWorkflow = true}) {
    return retryExecution(id, loadWorkflow: loadWorkflow);
  }

  Future<void> delete(String id) {
    return deleteExecution(id);
  }
}
