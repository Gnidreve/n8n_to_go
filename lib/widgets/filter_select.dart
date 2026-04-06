import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class FilterSelectOption {
  const FilterSelectOption({
    required this.value,
    required this.label,
    this.leading,
  });

  final String value;
  final String label;
  final Widget? leading;
}

class FilterSelect extends StatefulWidget {
  const FilterSelect({
    super.key,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    this.searchPlaceholder = 'Search',
    this.emptyLabel = 'No options found',
  });

  final List<FilterSelectOption> options;
  final Set<String> selectedValues;
  final ValueChanged<Set<String>> onChanged;
  final String searchPlaceholder;
  final String emptyLabel;

  @override
  State<FilterSelect> createState() => _FilterSelectState();
}

class _FilterSelectState extends State<FilterSelect> {
  String _searchValue = '';

  List<FilterSelectOption> get _filteredOptions {
    final query = _searchValue.trim().toLowerCase();
    if (query.isEmpty) return widget.options;
    return widget.options
        .where((option) => option.label.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ShadSelect<String>.multipleWithSearch(
      minWidth: 240,
      maxWidth: 360,
      closeOnSelect: false,
      allowDeselection: true,
      placeholder: const SizedBox.shrink(),
      searchPlaceholder: Text(widget.searchPlaceholder),
      onSearchChanged: (value) => setState(() => _searchValue = value),
      onChanged: widget.onChanged,
      options: [
        if (_filteredOptions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
            child: Text(widget.emptyLabel),
          ),
        ...widget.options.map(
          (option) => Offstage(
            offstage: !_filteredOptions.contains(option),
            child: ShadOption(
              value: option.value,
              child: Row(
                children: [
                  if (option.leading != null) ...[
                    option.leading!,
                    const SizedBox(width: 8),
                  ],
                  Expanded(child: Text(option.label)),
                ],
              ),
            ),
          ),
        ),
      ],
      selectedOptionsBuilder: (context, values) {
        if (values.isEmpty) return const SizedBox.shrink();
        final labels = widget.options
            .where((option) => values.contains(option.value))
            .map((option) => option.label)
            .join(', ');
        return Text(labels);
      },
      initialValues: widget.selectedValues,
    );
  }
}
