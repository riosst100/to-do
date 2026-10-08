import 'package:intl/intl.dart';

/// Tanggal lokal (bukan UTC) dalam format YYYY-MM-DD.
String toIsoDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

String todayIso() => toIsoDate(DateTime.now());

DateTime parseIsoDate(String iso) => DateFormat('yyyy-MM-dd').parse(iso);

/// "8 Okt 2026"
String formatDate(String iso) => DateFormat('d MMM yyyy', 'id').format(parseIsoDate(iso));

/// "Kamis, 8 Oktober 2026"
String formatLongDate(String iso) => DateFormat('EEEE, d MMMM yyyy', 'id').format(parseIsoDate(iso));

/// "Oktober 2026"
String formatMonth(int year, int month) => DateFormat('MMMM yyyy', 'id').format(DateTime(year, month));
