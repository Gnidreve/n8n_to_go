import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../api/api.dart';

class CredentialSchemaForm extends StatefulWidget {
  const CredentialSchemaForm({
    super.key,
    required this.credentialType,
    this.initialSchema,
  });

  final String credentialType;
  final Map<String, dynamic>? initialSchema;

  @override
  State<CredentialSchemaForm> createState() => CredentialSchemaFormState();
}

class CredentialSchemaFormState extends State<CredentialSchemaForm> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _properties = {};
  Set<String> _required = {};
  List<_ConditionalRule> _conditionalRules = [];
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _checkboxValues = {};
  final Map<String, String?> _selectValues = {};

  @override
  void initState() {
    super.initState();
    final initialSchema = widget.initialSchema;
    if (initialSchema != null) {
      _applySchema(initialSchema);
    } else {
      _fetchSchema();
    }
  }

  @override
  void didUpdateWidget(CredentialSchemaForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.credentialType != widget.credentialType ||
        oldWidget.initialSchema != widget.initialSchema) {
      _disposeControllers();
      _checkboxValues.clear();
      _selectValues.clear();
      final initialSchema = widget.initialSchema;
      if (initialSchema != null) {
        _applySchema(initialSchema);
      } else {
        _fetchSchema();
      }
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  Future<void> _fetchSchema() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final decoded = await credentials.schema.get(widget.credentialType);
      _applySchema(decoded);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _applySchema(Map<String, dynamic> decoded) {
    final properties = decoded['properties'] as Map<String, dynamic>? ?? {};
    final required = (decoded['required'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toSet();
    final conditionalRules = _parseConditionalRules(
      decoded['allOf'] as List<dynamic>? ?? const [],
    );

    _primeFieldState(properties);

    setState(() {
      _loading = false;
      _error = null;
      _properties = properties;
      _required = required;
      _conditionalRules = conditionalRules;
    });
  }

  void _primeFieldState(Map<String, dynamic> properties) {
    for (final entry in properties.entries) {
      final key = entry.key;
      final schema = _normalizeFieldSchema(entry.value);
      final fieldType = schema['type'] as String?;
      final enumValues = (schema['enum'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList();

      switch (fieldType) {
        case 'boolean':
          _checkboxValues.putIfAbsent(key, () => false);
          break;
        case 'string':
          if (enumValues.isNotEmpty) {
            _selectValues.putIfAbsent(key, () => null);
          } else {
            _controllers.putIfAbsent(key, () => TextEditingController());
          }
          break;
        default:
          _controllers.putIfAbsent(key, () => TextEditingController());
      }
    }
  }

  List<_ConditionalRule> _parseConditionalRules(List<dynamic> rawRules) {
    final rules = <_ConditionalRule>[];

    for (final rawRule in rawRules) {
      final rule = rawRule as Map<String, dynamic>?;
      if (rule == null) continue;

      final ifBlock = rule['if'] as Map<String, dynamic>?;
      final properties = ifBlock?['properties'] as Map<String, dynamic>?;
      if (properties == null || properties.length != 1) continue;

      final conditionEntry = properties.entries.first;
      final conditionSchema = conditionEntry.value as Map<String, dynamic>?;
      final expectedValues = conditionSchema?['enum'] as List<dynamic>?;
      if (expectedValues == null || expectedValues.length != 1) continue;

      final requiredWhenMatched = _extractRequiredFields(rule['then']);
      final hiddenWhenUnmatched = _extractNotRequiredFields(rule['else']);
      final controlledFields = {...requiredWhenMatched, ...hiddenWhenUnmatched};
      if (controlledFields.isEmpty) continue;

      rules.add(
        _ConditionalRule(
          conditionField: conditionEntry.key,
          expectedValue: expectedValues.first,
          controlledFields: controlledFields,
          requiredWhenMatched: requiredWhenMatched,
        ),
      );
    }

    return rules;
  }

  Set<String> _extractRequiredFields(dynamic block) {
    final fields = <String>{};
    final allOf = (block as Map<String, dynamic>?)?['allOf'] as List<dynamic>?;
    if (allOf == null) return fields;

    for (final entry in allOf) {
      final required = (entry as Map<String, dynamic>?)?['required'] as List<dynamic>?;
      if (required == null) continue;
      fields.addAll(required.whereType<String>());
    }

    return fields;
  }

  Set<String> _extractNotRequiredFields(dynamic block) {
    final fields = <String>{};
    final allOf = (block as Map<String, dynamic>?)?['allOf'] as List<dynamic>?;
    if (allOf == null) return fields;

    for (final entry in allOf) {
      final notBlock = (entry as Map<String, dynamic>?)?['not'] as Map<String, dynamic>?;
      final required = notBlock?['required'] as List<dynamic>?;
      if (required == null) continue;
      fields.addAll(required.whereType<String>());
    }

    return fields;
  }

  Map<String, dynamic> _normalizeFieldSchema(dynamic rawSchema) {
    if (rawSchema is Map<String, dynamic>) return rawSchema;
    return const {};
  }

  bool _isFieldVisible(String key) {
    for (final rule in _conditionalRules) {
      if (!rule.controlledFields.contains(key)) continue;
      if (!_doesRuleMatch(rule)) return false;
    }
    return true;
  }

  bool _doesRuleMatch(_ConditionalRule rule) {
    final actualValue = _currentValueForField(rule.conditionField);
    return actualValue == rule.expectedValue;
  }

  bool _isFieldRequired(String key) {
    if (_required.contains(key)) return true;

    for (final rule in _conditionalRules) {
      if (!rule.requiredWhenMatched.contains(key)) continue;
      if (_doesRuleMatch(rule)) return true;
    }

    return false;
  }

  dynamic _currentValueForField(String key) {
    final schema = _normalizeFieldSchema(_properties[key]);
    final fieldType = schema['type'] as String?;
    final enumValues = (schema['enum'] as List<dynamic>? ?? const []);

    if (fieldType == 'boolean') {
      return _checkboxValues[key] ?? false;
    }

    if (fieldType == 'string' && enumValues.isNotEmpty) {
      return _selectValues[key];
    }

    return _controllers[key]?.text.trim();
  }

  bool _isSecretField(String key) {
    final lower = key.toLowerCase();
    return lower.contains('token') ||
        lower.contains('key') ||
        lower.contains('secret') ||
        lower.contains('password') ||
        lower.contains('passphrase');
  }

  String _labelForField(String key) {
    final words = key
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .split(RegExp(r'[_\s]+'))
        .where((word) => word.isNotEmpty)
        .map((word) {
          final lower = word.toLowerCase();
          if (lower == 'ssl' || lower == 'ssh') return word.toUpperCase();
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .toList();

    return words.join(' ');
  }

  String _optionLabel(String value) {
    return value
        .split(RegExp(r'[_\s-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  /// Returns the current form values as a typed Map — pass this as `data` to the API.
  Map<String, dynamic> getData() {
    final data = <String, dynamic>{};

    for (final entry in _properties.entries) {
      final key = entry.key;
      if (!_isFieldVisible(key)) continue;

      final schema = _normalizeFieldSchema(entry.value);
      final fieldType = schema['type'] as String?;
      final enumValues = (schema['enum'] as List<dynamic>? ?? const []);

      if (fieldType == 'boolean') {
        data[key] = _checkboxValues[key] ?? false;
        continue;
      }

      if (fieldType == 'string' && enumValues.isNotEmpty) {
        final selectedValue = _selectValues[key];
        if (selectedValue != null && selectedValue.isNotEmpty) {
          data[key] = selectedValue;
        }
        continue;
      }

      final rawValue = _controllers[key]?.text.trim() ?? '';
      if (rawValue.isEmpty) continue;

      if (fieldType == 'number') {
        final numericValue = num.tryParse(rawValue);
        if (numericValue != null) {
          data[key] = numericValue;
        }
        continue;
      }

      data[key] = rawValue;
    }

    return data;
  }

  bool get isLoading => _loading;

  Widget _buildField(String key, Map<String, dynamic> schema) {
    final fieldType = schema['type'] as String?;
    final isRequired = _isFieldRequired(key);
    final label = _labelForField(key);
    final enumValues = (schema['enum'] as List<dynamic>? ?? const [])
        .map((value) => value.toString())
        .toList();

    if (fieldType == 'boolean') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          _FieldLabel(label: label, isRequired: isRequired),
          ShadCheckbox(
            value: _checkboxValues[key] ?? false,
            onChanged: (value) {
              setState(() {
                _checkboxValues[key] = value;
              });
            },
          ),
        ],
      );
    }

    if (fieldType == 'string' && enumValues.isNotEmpty) {
      final selectedValue = _selectValues[key];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          _FieldLabel(label: label, isRequired: isRequired),
          ShadSelect<String>(
            initialValue: selectedValue,
            placeholder: Text(isRequired ? 'Select an option' : 'Optional'),
            onChanged: (value) {
              setState(() {
                _selectValues[key] = value;
              });
            },
            options: enumValues
                .map(
                  (value) => ShadOption<String>(
                    value: value,
                    child: Text(_optionLabel(value)),
                  ),
                )
                .toList(),
            selectedOptionBuilder: (context, value) => Text(_optionLabel(value)),
          ),
        ],
      );
    }

    final keyboardType = fieldType == 'number'
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        _FieldLabel(label: label, isRequired: isRequired),
        ShadInput(
          controller: _controllers[key],
          placeholder: Text(isRequired ? 'Required' : 'Optional'),
          keyboardType: keyboardType,
          obscureText: _isSecretField(key),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Failed to load schema: $_error',
          style: TextStyle(color: ShadTheme.of(context).colorScheme.destructive),
        ),
      );
    }
    if (_properties.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No fields found for this type.'),
      );
    }

    final visibleFields = _properties.entries
        .where((entry) => _isFieldVisible(entry.key))
        .map((entry) => _buildField(entry.key, _normalizeFieldSchema(entry.value)))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: visibleFields,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.label,
    required this.isRequired,
  });

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        if (isRequired) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: TextStyle(
              color: ShadTheme.of(context).colorScheme.destructive,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _ConditionalRule {
  const _ConditionalRule({
    required this.conditionField,
    required this.expectedValue,
    required this.controlledFields,
    required this.requiredWhenMatched,
  });

  final String conditionField;
  final dynamic expectedValue;
  final Set<String> controlledFields;
  final Set<String> requiredWhenMatched;
}
