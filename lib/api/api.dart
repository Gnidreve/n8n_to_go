import 'credentials/credentials_api.dart';
import 'data_tables/data_tables_api.dart';
import 'executions/executions_api.dart';
import 'workflows/workflows_api.dart';

final credentials = const CredentialsApi();
final workflows = const WorkflowsApi();
final executions = const ExecutionsApi();
final dataTables = const DataTablesApi();
