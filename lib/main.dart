import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Theme ─────────────────────────────────────────────────────────────────────

TextStyle _jbm({
  TextStyle? textStyle, Color? color, Color? backgroundColor,
  double? fontSize, FontWeight? fontWeight, FontStyle? fontStyle,
  double? letterSpacing, double? wordSpacing, TextBaseline? textBaseline,
  double? height, Locale? locale, Paint? foreground, Paint? background,
  List<Shadow>? shadows, List<FontFeature>? fontFeatures,
  TextDecoration? decoration, Color? decorationColor,
  TextDecorationStyle? decorationStyle, double? decorationThickness,
}) => GoogleFonts.jetBrainsMono(
  textStyle: textStyle, color: color, backgroundColor: backgroundColor,
  fontSize: fontSize, fontStyle: fontStyle,
  fontWeight: fontWeight == FontWeight.w400 ? FontWeight.w500 : fontWeight,
  letterSpacing: letterSpacing ?? -0.1, wordSpacing: wordSpacing,
  textBaseline: textBaseline, height: height, locale: locale,
  foreground: foreground, background: background, shadows: shadows,
  fontFeatures: fontFeatures, decoration: decoration,
  decorationColor: decorationColor, decorationStyle: decorationStyle,
  decorationThickness: decorationThickness,
);

final _textTheme = ShadTextTheme.fromGoogleFont(_jbm);

// ── Shared helpers ────────────────────────────────────────────────────────────

/// Parses an ISO timestamp and returns a zero-padded "HH:MM" string (local time).
String _parseToHHMM(String raw) {
  final dt = DateTime.parse(raw).toLocal();
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

/// Combines [date]'s calendar date with a "HH:MM" [timeInput].
/// Falls back to [fallbackHour]/[fallbackMinute] when input is unparseable.
DateTime _applyTimeInput(
  DateTime date,
  String timeInput, {
  int fallbackHour = 0,
  int fallbackMinute = 0,
}) {
  final parts = timeInput.split(':');
  final h = int.tryParse(parts.elementAtOrNull(0) ?? '') ?? fallbackHour;
  final m = int.tryParse(parts.elementAtOrNull(1) ?? '') ?? fallbackMinute;
  return DateTime(date.year, date.month, date.day, h, m).toUtc();
}

const _kSavingSpinner = SizedBox.square(
  dimension: 16,
  child: CircularProgressIndicator(strokeWidth: 2),
);

const _kHeaderStyle = TextStyle(fontWeight: FontWeight.bold);

// ── App ───────────────────────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const MainApp());
}

SupabaseClient get supabase => Supabase.instance.client;

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadZincColorScheme.light(),
        textTheme: _textTheme,
        radius: BorderRadius.circular(6.72),
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadZincColorScheme.dark(),
        textTheme: _textTheme,
        radius: BorderRadius.circular(6.72),
      ),
      home: const SplashPage(),
    );
  }
}

// ── Splash ────────────────────────────────────────────────────────────────────

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OtpPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('●')),
    );
  }
}

// ── OTP ───────────────────────────────────────────────────────────────────────

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _focusNode = FocusNode();
  bool _error = false;

  void _submit(String value) {
    final code = dotenv.env['OTP_CODE'] ?? '';
    if (value == code) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppointmentsPage()),
      );
    } else {
      setState(() => _error = true);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() => _error = false);
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 24,
          children: [
            Text('PIN eingeben', style: ShadTheme.of(context).textTheme.h3),
            ShadInputOTP(
              maxLength: 4,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) {
                if (_error) setState(() => _error = false);
                if (v.length == 4 && !v.contains(' ')) _submit(v);
              },
              children: [
                ShadInputOTPGroup(
                  children: [
                    ShadInputOTPSlot(focusNode: _focusNode),
                    const ShadInputOTPSlot(),
                    const ShadInputOTPSlot(),
                    const ShadInputOTPSlot(),
                  ],
                ),
              ],
            ),
            if (_error)
              Text(
                'Falscher Code',
                style: TextStyle(
                  color: ShadTheme.of(context).colorScheme.destructive,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Appointments ──────────────────────────────────────────────────────────────

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  DateTime _selectedDay = DateTime.now();
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _allRows = [];
  List<Map<String, dynamic>> _filteredRows = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() => _loading = true);
    supabase.from('appointments').select().then((data) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = null;
          _allRows = data;
          _filteredRows = _filterForDay(data, _selectedDay);
        });
      }
    }).catchError((e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    });
  }

  List<Map<String, dynamic>> _filterForDay(
    List<Map<String, dynamic>> rows,
    DateTime day,
  ) {
    return rows.where((r) {
      final dt = DateTime.parse(r['begins_at']).toLocal();
      return dt.year == day.year && dt.month == day.month && dt.day == day.day;
    }).toList();
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta);
    });
  }

  void _openSheet(Map<String, dynamic> row) {
    showShadSheet(
      side: ShadSheetSide.bottom,
      context: context,
      builder: (_) => AppointmentSheet(row: row, onSaved: _reload),
    );
  }

  ShadTableCell _tappableCell(String text, Map<String, dynamic> row) =>
      ShadTableCell(
        child: GestureDetector(
          onTap: () => _openSheet(row),
          child: Text(text),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => showShadSheet(
          side: ShadSheetSide.bottom,
          context: context,
          builder: (_) => _CreateDialog(
            selectedDay: _selectedDay,
            onCreated: _reload,
          ),
        ),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onHorizontalDragEnd: (details) {
                  final v = details.primaryVelocity ?? 0;
                  if (v < -200) _changeMonth(1);
                  if (v > 200) _changeMonth(-1);
                },
                child: ShadCalendar(
                  key: ValueKey(_currentMonth),
                  selected: _selectedDay,
                  initialMonth: _currentMonth,
                  dayButtonSize: 48,
                  headerTextStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  monthConstraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width,
                  ),
                  onChanged: (day) {
                    if (day != null) {
                      setState(() {
                        _selectedDay = day;
                        _filteredRows = _filterForDay(_allRows, day);
                      });
                    }
                  },
                  onMonthChanged: (month) {
                    setState(() => _currentMonth = DateTime(month.year, month.month));
                  },
                ),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Fehler: $_error',
                    style: TextStyle(
                      color: ShadTheme.of(context).colorScheme.destructive,
                    ),
                  ),
                )
              else if (_filteredRows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Keine Termine an diesem Tag'),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    // ShadTable uses a 2D viewport and requires explicit height.
                    height: 56.0 + _filteredRows.length * 48.0,
                    child: ShadTable.list(
                      header: const [
                        ShadTableCell.header(child: Text('Beginn', style: _kHeaderStyle)),
                        ShadTableCell.header(child: Text('Ende', style: _kHeaderStyle)),
                        ShadTableCell.header(child: Text('Bezeichnung', style: _kHeaderStyle)),
                      ],
                      columnSpanExtent: (index) {
                        if (index == 0 || index == 1) return const FixedTableSpanExtent(100);
                        return const RemainingTableSpanExtent();
                      },
                      children: _filteredRows.map((r) => [
                        _tappableCell('${_parseToHHMM(r['begins_at'])} Uhr', r),
                        _tappableCell('${_parseToHHMM(r['ends_at'])} Uhr', r),
                        _tappableCell(r['keyword'] ?? '', r),
                      ]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Appointment Sheet (edit) ──────────────────────────────────────────────────

class AppointmentSheet extends StatefulWidget {
  const AppointmentSheet({super.key, required this.row, required this.onSaved});

  final Map<String, dynamic> row;
  final VoidCallback onSaved;

  @override
  State<AppointmentSheet> createState() => _AppointmentSheetState();
}

class _AppointmentSheetState extends State<AppointmentSheet> {
  late final TextEditingController _keyword;
  late final TextEditingController _beginsAt;
  late final TextEditingController _endsAt;
  late final TextEditingController _description;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.row;
    final beginsLocal = DateTime.parse(r['begins_at']).toLocal();
    final endsLocal   = DateTime.parse(r['ends_at']).toLocal();
    _keyword     = TextEditingController(text: r['keyword'] ?? '');
    _beginsAt    = TextEditingController(text: _parseToHHMM(r['begins_at']));
    _endsAt      = TextEditingController(text: _parseToHHMM(r['ends_at']));
    _description = TextEditingController(text: r['description'] ?? '');
    // Store originals for fallback in _applyTimeInput
    _beginsLocal = beginsLocal;
    _endsLocal   = endsLocal;
  }

  late final DateTime _beginsLocal;
  late final DateTime _endsLocal;

  @override
  void dispose() {
    _keyword.dispose();
    _beginsAt.dispose();
    _endsAt.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await supabase.from('appointments').update({
        'keyword':     _keyword.text,
        'begins_at':   _applyTimeInput(
          _beginsLocal, _beginsAt.text,
          fallbackHour: _beginsLocal.hour, fallbackMinute: _beginsLocal.minute,
        ).toIso8601String(),
        'ends_at':     _applyTimeInput(
          _endsLocal, _endsAt.text,
          fallbackHour: _endsLocal.hour, fallbackMinute: _endsLocal.minute,
        ).toIso8601String(),
        'description': _description.text.isEmpty ? null : _description.text,
      }).eq('id', widget.row['id']);

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Fehler beim Speichern'),
            description: Text(e.toString()),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShadSheet(
      title: const Text('Termin bearbeiten'),
      description: const Text('Änderungen werden direkt in der Datenbank gespeichert.'),
      actions: [
        ShadButton(
          onPressed: _saving ? null : _save,
          child: _saving ? _kSavingSpinner : const Text('Speichern'),
        ),
      ],
      child: _AppointmentFormFields(
        keyword: _keyword,
        beginsAt: _beginsAt,
        endsAt: _endsAt,
        description: _description,
        descriptionPlaceholder: 'Notizen zum Termin…',
      ),
    );
  }
}

// ── Create Sheet ──────────────────────────────────────────────────────────────

class _CreateDialog extends StatefulWidget {
  const _CreateDialog({required this.selectedDay, required this.onCreated});

  final DateTime selectedDay;
  final VoidCallback onCreated;

  @override
  State<_CreateDialog> createState() => _CreateDialogState();
}

class _CreateDialogState extends State<_CreateDialog> {
  final _keyword     = TextEditingController();
  final _beginsAt    = TextEditingController();
  final _endsAt      = TextEditingController();
  final _description = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _keyword.dispose();
    _beginsAt.dispose();
    _endsAt.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await supabase.from('appointments').insert({
        'keyword':     _keyword.text,
        'begins_at':   _applyTimeInput(widget.selectedDay, _beginsAt.text).toIso8601String(),
        'ends_at':     _applyTimeInput(widget.selectedDay, _endsAt.text).toIso8601String(),
        'description': _description.text.isEmpty ? null : _description.text,
      });
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Fehler beim Erstellen'),
            description: Text(e.toString()),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShadSheet(
      title: const Text('Neuer Termin'),
      actions: [
        ShadButton(
          onPressed: _saving ? null : _save,
          child: _saving ? _kSavingSpinner : const Text('Erstellen'),
        ),
      ],
      child: _AppointmentFormFields(
        keyword: _keyword,
        beginsAt: _beginsAt,
        endsAt: _endsAt,
        description: _description,
        descriptionPlaceholder: 'Optional…',
      ),
    );
  }
}

// ── Shared form ───────────────────────────────────────────────────────────────

class _AppointmentFormFields extends StatelessWidget {
  const _AppointmentFormFields({
    required this.keyword,
    required this.beginsAt,
    required this.endsAt,
    required this.description,
    required this.descriptionPlaceholder,
  });

  final TextEditingController keyword;
  final TextEditingController beginsAt;
  final TextEditingController endsAt;
  final TextEditingController description;
  final String descriptionPlaceholder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          _Field(label: 'Bezeichnung', child: ShadInput(controller: keyword)),
          _Field(label: 'Beginn',      child: ShadInput(controller: beginsAt, placeholder: const Text('HH:MM'))),
          _Field(label: 'Ende',        child: ShadInput(controller: endsAt,   placeholder: const Text('HH:MM'))),
          _Field(
            label: 'Beschreibung',
            child: ShadTextarea(controller: description, placeholder: Text(descriptionPlaceholder)),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        child,
      ],
    );
  }
}
