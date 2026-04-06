import 'audit/audit_api.dart';
import 'credentials/credentials_api.dart';
import 'data_tables/data_tables_api.dart';
import 'executions/executions_api.dart';
import 'workflows/workflows_api.dart';

final audit = const AuditApi();
final credentials = const CredentialsApi();
final workflows = const WorkflowsApi();
final executions = const ExecutionsApi();
final dataTables = const DataTablesApi();
