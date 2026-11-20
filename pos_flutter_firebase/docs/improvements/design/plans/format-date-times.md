# Fix: dates read like database output instead of human dates

> Follow the steps in order. Run every check. If anything in "STOP if"
> happens, stop and report instead of improvising.

- **Link**: https://flutterpro.design/details/md/format-date-times
- **Needs new dependency**: intl (for `DateFormat`; if the numbers plan already added it, reuse it — do not add twice)

## Why

Receipts, movements, shifts and losses show hand-built `13/09/2026 14:05` strings with padded numbers, never in the user's language, and a missing date would print `null`. One shared extension gives every screen `24 Jul 2026, 14:05`-style dates in Spanish, with `N/A` where there is no date.

## Where

No `DateFormat` exists in `lib/` (grep returns nothing). New file `lib/shared/extensions/date_time_x.dart` with the article's file, verbatim:

```dart
import 'package:intl/intl.dart';

extension DateTimeX on DateTime? {
  // 24 July 2016, 14:44
  String formattedDateTime(String languageCode) {
    if (this == null) return 'N/A';

    return DateFormat('d MMMM yyyy, HH:mm', languageCode).format(this!);
  }

  // 24 Jul 2016
  String formattedDate(String languageCode) {
    if (this == null) return 'N/A';

    return DateFormat('d MMM yyyy', languageCode).format(this!);
  }

  // Friday, 24 July
  String formattedWeekdayDate(String languageCode) {
    if (this == null) return 'N/A';

    return DateFormat('EEEE, d MMMM', languageCode).format(this!);
  }

  // 14:44
  String get formattedTime {
    if (this == null) return 'N/A';

    return DateFormat('HH:mm').format(this!);
  }

  // Today · Yesterday · 24 Jul 2016
  String formattedDayOrDate(String languageCode) {
    if (this == null) return 'N/A';

    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';

    return formattedDate(languageCode);
  }

  // 2016-07-24, for requests only
  String get formattedForBackend {
    if (this == null) return '';

    return DateFormat('yyyy-MM-dd').format(this!);
  }

  bool get isToday {
    if (this == null) return false;

    final DateTime now = DateTime.now();

    return this!.year == now.year &&
        this!.month == now.month &&
        this!.day == now.day;
  }

  bool get isYesterday {
    if (this == null) return false;

    final DateTime yesterday = DateTime.now().subtract(
      const Duration(days: 1),
    );

    return this!.year == yesterday.year &&
        this!.month == yesterday.month &&
        this!.day == yesterday.day;
  }
}
```

The app is Spanish-only: pass `'es'` as `languageCode` at every call site below. Locale data must load once in `main` — `lib/main.dart:46` is `await dotenv.load(fileName: '.env');`, add after it:

```dart
    await initializeDateFormatting('es');
```

(with `import 'package:intl/date_symbol_data_local.dart';` in `main.dart`).

Migrate every user-facing hand-built date (delete the replaced `_formatDate` helpers afterwards):
- `lib/features/home/ui/back_office_screen.dart:591` (`'${date.day...}/${date.month...}/${date.year}'`) → `date.formattedDate('es')`; `:850` (with hour/minute) → `date.formattedDateTime('es')`. Delete both `_formatDate` helpers if unused after. The chart grouping keys at `:1027`/`:1050` (`'${date.year}-...'`) stay exactly as-is (backend keys, never shown); the daily chart label `entry.key.substring(5)` at the `_dailyChart` becomes `DateTime.parse(entry.key).formattedDate('es')`.
- `lib/features/home/ui/desktop/shifts_view_screen.dart:199` → `formattedDateTime('es')`; delete its `_formatDate`.
- `lib/features/shift/ui/shift_screen.dart:334` → `formattedDateTime('es')`; delete its `_formatDate`.
- `lib/features/losses/ui/losses_screen.dart:200` → `formattedDateTime('es')`; delete its `_formatDate`.
- `lib/features/sales/ui/receipts_screen.dart:100` → `formattedDate('es')`; `:297` → `formattedDateTime('es')`; delete its `_formatDate`.
- `lib/features/pos/ui/ticket_detail_screen.dart:154` → `formattedDateTime('es')`; delete its `_formatDate`.
- `lib/features/pos/ui/pos_screen.dart:1098` (open-ticket dates) → `formattedDayOrDate('es')`; delete its `_formatDate`.
- `lib/features/sales/data/pdf_service.dart:195` (printed receipt) → `formattedDateTime('es')`; delete its `_formatDate`.
- `lib/features/home/ui/desktop/dashboard_screen.dart:175` (`'${days[value.toInt()].day}/${days[value.toInt()].month}'`) → `days[value.toInt()].formattedDate('es')`.

Each touched file gains both imports (`date_time_x.dart` with correct relative path, only where used).

## The fix

Article's extension + `initializeDateFormatting('es')` in `main` + the call-site migrations above.

## Steps

1. Add `intl` to `pubspec.yaml` (skip if the numbers plan already did) and run `flutter pub get`.
2. Create `lib/shared/extensions/date_time_x.dart` with the file above, exactly.
3. Add `await initializeDateFormatting('es');` in `main()` after the dotenv line, with import.
4. Migrate every call site above; delete each orphaned `_formatDate` helper.
5. Run `dart analyze` — must exit clean.

## Check it

`dart analyze` exits clean. Plus:
- `grep -rn "_formatDate" lib/features/home/ui/back_office_screen.dart lib/features/home/ui/desktop/shifts_view_screen.dart lib/features/shift/ui/shift_screen.dart lib/features/losses/ui/losses_screen.dart lib/features/sales/ui/receipts_screen.dart lib/features/pos/ui/ticket_detail_screen.dart lib/features/pos/ui/pos_screen.dart lib/features/sales/data/pdf_service.dart` → 0
- `grep -c "formattedDate" lib/features/home/ui/back_office_screen.dart` → 4
- `grep -c "initializeDateFormatting" lib/main.dart` → 1

## Don't touch

- Backend-only formats: `backup_service.dart:339` filename, `excel_export_service.dart:225-230` filename, chart grouping keys (`yyyy-MM-dd` strings used as map keys).
- Excel sheet date cells (`excel_book_builder.dart:383-385`, `excel_report_sheets.dart:896-900`): spreadsheets carry fixed sortable formats for filtering — out of scope.
- Non-date logic in the touched screens.
- No new dependencies unless declared in the header.
- No refactors, renames, or cleanups beyond the fix.

## STOP if

- The code at any location in "Where" doesn't match the quoted excerpt (the codebase moved on since this plan was written).
- `initializeDateFormatting('es')` throws for a missing locale bundle (then call the no-arg `initializeDateFormatting()` and report).
- A check fails twice.

## When you're done

Tell the developer, in two or three sentences, what's different in the app now and one place to open to see it. Not a list of files, the steps already have those.
