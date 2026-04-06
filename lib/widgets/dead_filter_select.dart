import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _filterOptions = <String, String>{
  'favorites': 'Favorites',
  'recent': 'Recent',
  'active': 'Active',
  'archived': 'Archived',
  'shared': 'Shared',
};

class DeadFilterSelect extends StatefulWidget {
  const DeadFilterSelect({super.key});

  @override
  State<DeadFilterSelect> createState() => _DeadFilterSelectState();
}

class _DeadFilterSelectState extends State<DeadFilterSelect> {
  String _searchValue = '';
  Set<String> _selectedValues = <String>{};

  Map<String, String> get _filteredOptions => <String, String>{
        for (final option in _filterOptions.entries)
          if (option.value.toLowerCase().contains(_searchValue.toLowerCase()))
            option.key: option.value,
      };

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return ShadSelect<String>.multipleWithSearch(
      minWidth: 240,
      maxWidth: 360,
      closeOnSelect: false,
      allowDeselection: true,
      placeholder: const Text('Select filters'),
      searchPlaceholder: const Text('Search filters'),
      onSearchChanged: (value) => setState(() => _searchValue = value),
      onChanged: (values) => setState(() => _selectedValues = values),
      options: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            'Filters',
            style: theme.textTheme.large,
            textAlign: TextAlign.start,
          ),
        ),
        if (_filteredOptions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 24),
            child: Text('No filters found'),
          ),
        ..._filterOptions.entries.map(
          (option) => Offstage(
            offstage: !_filteredOptions.containsKey(option.key),
            child: ShadOption(
              value: option.key,
              child: Text(option.value),
            ),
          ),
        ),
      ],
      selectedOptionsBuilder: (context, values) {
        if (values.isEmpty) return const Text('Select filters');
        return Text(
          values
              .map((value) => _filterOptions[value] ?? value)
              .join(', '),
        );
      },
      initialValues: _selectedValues,
    );
  }
}
