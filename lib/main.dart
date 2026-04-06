import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Theme ─────────────────────────────────────────────────────────────────────

TextStyle _jbm({
  TextStyle? textStyle,
  Color? color,
  Color? backgroundColor,
  double? fontSize,
  FontWeight? fontWeight,
  FontStyle? fontStyle,
  double? letterSpacing,
  double? wordSpacing,
  TextBaseline? textBaseline,
  double? height,
  Locale? locale,
  Paint? foreground,
  Paint? background,
  List<Shadow>? shadows,
  List<FontFeature>? fontFeatures,
  TextDecoration? decoration,
  Color? decorationColor,
  TextDecorationStyle? decorationStyle,
  double? decorationThickness,
}) => GoogleFonts.jetBrainsMono(
  textStyle: textStyle,
  color: color,
  backgroundColor: backgroundColor,
  fontSize: fontSize,
  fontStyle: fontStyle,
  fontWeight: fontWeight == FontWeight.w400 ? FontWeight.w500 : fontWeight,
  letterSpacing: letterSpacing ?? -0.1,
  wordSpacing: wordSpacing,
  textBaseline: textBaseline,
  height: height,
  locale: locale,
  foreground: foreground,
  background: background,
  shadows: shadows,
  fontFeatures: fontFeatures,
  decoration: decoration,
  decorationColor: decorationColor,
  decorationStyle: decorationStyle,
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

const _kGermanWeekdays = [
  'Montag',
  'Dienstag',
  'Mittwoch',
  'Donnerstag',
  'Freitag',
  'Samstag',
  'Sonntag',
];


String _formatDateLabel(DateTime date) {
  return '${_kGermanWeekdays[date.weekday - 1]}, '
      '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.year}';
}

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
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('●')));
  }
}

// ── Home ──────────────────────────────────────────────────────────────────────

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _openMonthCalendar(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AppointmentsPage()),
    );
  }

  void _openQuests(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QuestsPage()),
    );
  }

  Widget _navigationCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = ShadTheme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 24),
              const SizedBox(width: 16),
              Text(title, style: theme.textTheme.h4),
              const Spacer(),
              const Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Questlog',
                  style: ShadTheme.of(context).textTheme.h1.copyWith(
                    decoration: TextDecoration.underline,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 32),
                Column(
                  spacing: 16,
                  children: [
                    _navigationCard(
                      context: context,
                      title: 'Quests',
                      icon: Icons.explore_outlined,
                      onTap: () => _openQuests(context),
                    ),
                    _navigationCard(
                      context: context,
                      title: 'Kalender',
                      icon: Icons.calendar_month_outlined,
                      onTap: () => _openMonthCalendar(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Day Calendar ──────────────────────────────────────────────────────────────

class QuestsPage extends StatefulWidget {
  const QuestsPage({super.key});

  @override
  State<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends State<QuestsPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _todos = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final data = await supabase
          .from('todo')
          .select()
          .order('created_at');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = null;
        _todos = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Quests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {}, // placeholder
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Fehler: $_error',
                      style: TextStyle(
                        color: ShadTheme.of(context).colorScheme.destructive,
                      ),
                    ),
                  ),
                )
              : _todos.isEmpty
                  ? const Center(child: Text('Keine Einträge'))
                  : ListView.separated(
                      itemCount: _todos.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final todo = _todos[i];
                        return ListTile(
                          title: Text(todo['keyword'] ?? ''),
                          subtitle: (todo['notes'] ?? '').toString().isNotEmpty
                              ? Text(todo['notes'])
                              : null,
                          trailing: todo['status'] == true
                              ? const Icon(Icons.check_circle_outline)
                              : const Icon(Icons.radio_button_unchecked),
                        );
                      },
                    ),
    );
  }
}

class QuestsDetailPage extends StatelessWidget {
  const QuestsDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quest Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const SizedBox.expand(),
    );
  }
}

// ── Day Calendar ──────────────────────────────────────────────────────────────

class DayCalendarPage extends StatefulWidget {
  const DayCalendarPage({super.key, this.initialDay});

  final DateTime? initialDay;

  @override
  State<DayCalendarPage> createState() => _DayCalendarPageState();
}

class _DayCalendarPageState extends State<DayCalendarPage> {
  static const double _timeColumnWidth = 88;
  static const int _kInitialPage = 10000;

  late final PageController _pageController;
  late final DateTime _baseDay;
  late DateTime _selectedDay;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _allRows = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final init = widget.initialDay;
    _baseDay = init != null
        ? DateTime(init.year, init.month, init.day)
        : DateTime(now.year, now.month, now.day);
    _selectedDay = _baseDay;
    _pageController = PageController(initialPage: _kInitialPage);
    _reload();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      if (_allRows.isEmpty) _loading = true;
    });
    try {
      final data = await supabase.from('appointments').select();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = null;
        _allRows = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<Map<String, dynamic>> _filterForDay(DateTime day) {
    return _allRows.where((r) {
      final beginsAt = DateTime.parse(r['begins_at']).toLocal();
      final endsAt = DateTime.parse(r['ends_at']).toLocal();
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      return beginsAt.isBefore(dayEnd) && endsAt.isAfter(dayStart);
    }).toList()
      ..sort((a, b) => a['begins_at'].compareTo(b['begins_at']));
  }

  List<Map<String, dynamic>> _allDayRowsFor(List<Map<String, dynamic>> rows) {
    return rows.where((row) {
      final beginsAt = DateTime.parse(row['begins_at']).toLocal();
      final endsAt = DateTime.parse(row['ends_at']).toLocal();
      return beginsAt.day != endsAt.day ||
          (beginsAt.hour == 0 &&
              beginsAt.minute == 0 &&
              endsAt.hour == 0 &&
              endsAt.minute == 0);
    }).toList();
  }

  void _onPageChanged(int page) {
    setState(() {
      _selectedDay = _baseDay.add(Duration(days: page - _kInitialPage));
    });
  }

  void _openSheet(Map<String, dynamic> row) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppointmentSheet(row: row, onSaved: _reload),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          _formatDateLabel(_selectedDay),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    _CreateDialog(selectedDay: _selectedDay, onCreated: _reload),
              ),
            ),
          ),
        ],
      ),
      body: Theme(
        data: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF09090B),
          cardColor: const Color(0xFF18181B),
          primaryColor: Colors.white,
          colorScheme: const ColorScheme.dark(
            primary: Colors.white,
            onPrimary: Colors.black,
            surface: Color(0xFF111318),
            onSurface: Colors.white,
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Fehler: $_error',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    )
                  : PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, index) {
                        final day =
                            _baseDay.add(Duration(days: index - _kInitialPage));
                        final rows = _filterForDay(day);
                        final allDayRows = _allDayRowsFor(rows);
                        final timedRows =
                            rows.where((r) => !allDayRows.contains(r)).toList();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (allDayRows.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 12, 12, 0),
                                child: Column(
                                  spacing: 8,
                                  children: allDayRows.map((row) {
                                    final keyword =
                                        row['keyword']
                                                ?.toString()
                                                .isNotEmpty ==
                                            true
                                        ? row['keyword']
                                        : 'Ganztagestermin';
                                    return GestureDetector(
                                      onTap: () => _openSheet(row),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFE2E8F0,
                                          ).withValues(alpha: 0.16),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.white24,
                                          ),
                                        ),
                                        child: Text(
                                          keyword,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final hourRowHeight =
                                      constraints.maxHeight / 24;
                                  return _DayCalendarTimeline(
                                    rows: timedRows,
                                    timeColumnWidth: _timeColumnWidth,
                                    hourRowHeight: hourRowHeight,
                                    onTapRow: _openSheet,
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

class _DayCalendarTimeline extends StatelessWidget {
  const _DayCalendarTimeline({
    required this.rows,
    required this.timeColumnWidth,
    required this.hourRowHeight,
    required this.onTapRow,
  });

  final List<Map<String, dynamic>> rows;
  final double timeColumnWidth;
  final double hourRowHeight;
  final ValueChanged<Map<String, dynamic>> onTapRow;

  double _positionFor(DateTime time) {
    return (time.hour + time.minute / 60) * hourRowHeight;
  }

  @override
  Widget build(BuildContext context) {
    final timelineHeight = hourRowHeight * 24;

    return SizedBox(
      height: timelineHeight,
      child: Stack(
        children: [
          Column(
            children: List.generate(24, (hour) {
              return SizedBox(
                height: hourRowHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: timeColumnWidth,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, top: 6),
                        child: Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Color(0xFF27272A)),
                            left: BorderSide(color: Color(0xFF27272A)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          ...rows.map((row) {
            final beginsAt = DateTime.parse(row['begins_at']).toLocal();
            final endsAt = DateTime.parse(row['ends_at']).toLocal();
            final top = _positionFor(beginsAt);
            final bottom = _positionFor(endsAt);
            final height = (bottom - top)
                .clamp(hourRowHeight * 0.75, 240.0)
                .toDouble();

            return Positioned(
              top: top + 2,
              left: timeColumnWidth + 8,
              right: 12,
              height: height - 4,
              child: GestureDetector(
                onTap: () => onTapRow(row),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          '${_parseToHHMM(row['begins_at'])} – ${_parseToHHMM(row['ends_at'])}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          color: const Color(0xFFE2E8F0).withValues(alpha: 0.18),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row['keyword']?.toString().isNotEmpty == true
                                    ? row['keyword']
                                    : 'Termin',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if ((row['description'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    row['description'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
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

const _kGermanMonths = [
  'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
  'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
];

class _AppointmentsPageState extends State<AppointmentsPage> {
  static const int _kInitialPage = 10000;

  late final PageController _pageController;
  final DateTime _baseMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  int _currentPage = _kInitialPage;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _kInitialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _monthForPage(int page) {
    final delta = page - _kInitialPage;
    final raw = DateTime(_baseMonth.year, _baseMonth.month + delta);
    return DateTime(raw.year, raw.month);
  }

  void _openDay(DateTime day) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DayCalendarPage(initialDay: day)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          () {
            final m = _monthForPage(_currentPage);
            return '${_kGermanMonths[m.month - 1]} ${m.year}';
          }(),
          style: const TextStyle(fontWeight: FontWeight.w400),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: null,
          ),
        ],
      ),
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (page) => setState(() => _currentPage = page),
          itemBuilder: (context, page) {
            final month = _monthForPage(page);
            return ShadCalendar(
              key: ValueKey(month),
              initialMonth: month,
              hideNavigation: true,
              dayButtonSize: 48,
              headerTextStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              monthConstraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width,
              ),
              onChanged: (day) {
                if (day != null) _openDay(day);
              },
            );
          },
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
  bool _wholeDay = false;

  @override
  void initState() {
    super.initState();
    final r = widget.row;
    final beginsLocal = DateTime.parse(r['begins_at']).toLocal();
    final endsLocal = DateTime.parse(r['ends_at']).toLocal();
    _keyword = TextEditingController(text: r['keyword'] ?? '');
    _beginsAt = TextEditingController(text: _parseToHHMM(r['begins_at']));
    _endsAt = TextEditingController(text: _parseToHHMM(r['ends_at']));
    _description = TextEditingController(text: r['description'] ?? '');
    _wholeDay = r['whole_day'] as bool? ?? false;
    // Store originals for fallback in _applyTimeInput
    _beginsLocal = beginsLocal;
    _endsLocal = endsLocal;
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
      await supabase
          .from('appointments')
          .update({
            'keyword': _keyword.text,
            'begins_at': _applyTimeInput(
              _beginsLocal,
              _beginsAt.text,
              fallbackHour: _beginsLocal.hour,
              fallbackMinute: _beginsLocal.minute,
            ).toIso8601String(),
            'ends_at': _applyTimeInput(
              _endsLocal,
              _endsAt.text,
              fallbackHour: _endsLocal.hour,
              fallbackMinute: _endsLocal.minute,
            ).toIso8601String(),
            'description': _description.text.isEmpty ? null : _description.text,
            'whole_day': _wholeDay,
          })
          .eq('id', widget.row['id']);

      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            title: Text('Termin gespeichert'),
          ),
        );
        Navigator.of(context).pop();
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Termin konnte nicht gespeichert werden'),
            description: Text(e.toString()),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termin bearbeiten'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: _saving ? _kSavingSpinner : const Icon(Icons.check),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _AppointmentFormFields(
          keyword: _keyword,
          beginsAt: _beginsAt,
          endsAt: _endsAt,
          description: _description,
          descriptionPlaceholder: 'Notizen zum Termin…',
          wholeDay: _wholeDay,
          onWholeDay: (v) => setState(() => _wholeDay = v),
        ),
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
  final _keyword = TextEditingController();
  final _beginsAt = TextEditingController();
  final _endsAt = TextEditingController();
  final _description = TextEditingController();
  bool _saving = false;
  bool _wholeDay = false;

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
        'keyword': _keyword.text,
        'begins_at': _applyTimeInput(
          widget.selectedDay,
          _beginsAt.text,
        ).toIso8601String(),
        'ends_at': _applyTimeInput(
          widget.selectedDay,
          _endsAt.text,
        ).toIso8601String(),
        'description': _description.text.isEmpty ? null : _description.text,
        'whole_day': _wholeDay,
      });
      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            title: Text('Termin erfolgreich angelegt'),
          ),
        );
        Navigator.of(context).pop();
        widget.onCreated();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Termin konnte nicht angelegt werden'),
            description: Text(e.toString()),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termin erstellen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: _saving ? _kSavingSpinner : const Icon(Icons.check),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _AppointmentFormFields(
          keyword: _keyword,
          beginsAt: _beginsAt,
          endsAt: _endsAt,
          description: _description,
          descriptionPlaceholder: 'Optional…',
          wholeDay: _wholeDay,
          onWholeDay: (v) => setState(() => _wholeDay = v),
        ),
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
    required this.wholeDay,
    required this.onWholeDay,
  });

  final TextEditingController keyword;
  final TextEditingController beginsAt;
  final TextEditingController endsAt;
  final TextEditingController description;
  final String descriptionPlaceholder;
  final bool wholeDay;
  final ValueChanged<bool> onWholeDay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          _Field(
            label: 'Bezeichnung',
            child: ShadInput(controller: keyword),
          ),
          Row(
            children: [
              ShadCheckbox(
                value: wholeDay,
                onChanged: onWholeDay,
              ),
              const SizedBox(width: 10),
              const Text('Ganztägig'),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _Field(
                  label: 'Beginn',
                  child: ShadInput(
                    controller: beginsAt,
                    placeholder: const Text('HH:MM'),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Text('→'),
              ),
              Expanded(
                child: _Field(
                  label: 'Ende',
                  child: ShadInput(
                    controller: endsAt,
                    placeholder: const Text('HH:MM'),
                  ),
                ),
              ),
            ],
          ),
          _Field(
            label: 'Beschreibung',
            child: ShadTextarea(
              controller: description,
              placeholder: Text(descriptionPlaceholder),
            ),
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
