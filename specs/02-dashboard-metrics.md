# SPEC 02 — Dashboard: activity metrics for a date range

> **Status:** Approved
> **Depends on:** SPEC 01 (shell, session, `AdminFailure`, `AuthInterceptor`)
> **Date:** 2026-10-01
> **Objective:** Replace the `/dashboard` placeholder with stat tiles, daily charts for registrations, products and receipts over a URL-addressable date range, and an all-time product-type breakdown.

---

## Scope

**In:**

- **Data sources** (existing backend endpoints, no backend changes):
  - `GET /api/v1/admin/metrics/users/registrations?from&to` → `[{date, count}]`
  - `GET /api/v1/admin/metrics/products?from&to` → `[{date, count}]`
  - `GET /api/v1/admin/metrics/shopping-receipts?from&to` → `[{date, totalReceipts}]`
  - `GET /api/v1/admin/product-types` → `[{productType, productCount}]`
- **Date range:**
  - Presets "Last 7 days", "Last 30 days" (default) and "Last 90 days", each ending today (the browser's local date).
  - "Custom…" opens a date-range picker that doesn't allow future dates. A picked range longer than 100 days (`to − from > 100`, the backend limit) is not applied and shows "Choose a range of at most 100 days."
  - The range lives in the URL: `/dashboard?range=7d|30d|90d` for presets, `/dashboard?from=YYYY-MM-DD&to=YYYY-MM-DD` for custom. A missing or invalid range falls back to the last 30 days, and the URL is replaced to match.
  - The range control and a Refresh button sit in one row above everything else.
- **Stat tiles** (a KPI row): "New users", "Products added" and "Receipts", each showing the total for the selected range. No delta.
- **Daily charts:** three single-series column charts, one card each:
  - "New users per day".
  - "Products added per day", subtitled "Includes deleted products".
  - "Receipts per purchase date", subtitled "Includes unconfirmed receipts".
  - Missing days are filled with 0 on the client, so every day in the range has a column.
  - Hovering a column shows a tooltip with the date and count.
- **Product types:** a horizontal bar chart titled "Products by type", subtitled "All time · excludes deleted products".
  - It shows every type the backend returns, sorted by count (largest first).
  - Types get human labels (`OTHER_FRESH_PRODUCTS` → "Other fresh products"), and each bar has its count at the end.
  - It ignores the date range.
- **Table view:** each chart card has a Chart | Table toggle. The table lists date and count (or type and count).
- **States:** each card loads and fails independently.
  - Loading shows a spinner in the card.
  - An error shows the failure message and a Retry button that refetches only that card.
  - An all-zero range shows "No … in this range" instead of an empty chart.
  - Each stat tile follows its metric's state.
- **Refresh:** data is fetched on page open and on range change. The Refresh button refetches all four, including product types. No polling.
- **Visuals:**
  - One series color for every chart, validated with the dataviz skill's `validate_palette.js` against the card surface.
  - Thin marks with rounded data ends, a recessive grid and axes, and text in text colors (never the series color).
  - No legends: each chart has one series and its title names it.
- **Dependency:** `fl_chart` for the charts.
- **Tests:** repository (fake HTTP adapter), zero-fill and range logic, bloc, URL ↔ range parsing, and widget tests for the page states, the toggle and the picker validation.

**Out of scope (for future specs):**

- `spaceId` / `creatorId` filters on the product and receipt metrics. There is no admin endpoint to list spaces yet; these are better added from the user detail page (SPEC 03) or later.
- Comparing with the previous period (deltas on the tiles).
- Changing backend semantics (excluding drafts or deleted products, counting receipts by creation date). That's a backend spec if wanted.
- Auto-refresh or polling.
- Dark mode, CSV export, printing.
- Timezone handling beyond the browser's local "today" (the backend buckets days in its database timezone).

---

## Data model

### Domain (`lib/features/dashboard/domain/`)

```dart
// entities/date_range.dart — calendar days only (time parts are always midnight local)
class DateRange extends Equatable {
  final DateTime from;     // inclusive
  final DateTime to;       // inclusive
  int get lengthInDays;    // to − from in days (backend limit: ≤ 100)
  List<DateTime> get days; // every day from → to, for zero-fill and axes
}

// entities/dashboard_range.dart — what the admin picked; resolved against "today"
enum RangePreset { last7('7d', 7), last30('30d', 30), last90('90d', 90) }
sealed class DashboardRange extends Equatable {
  DateRange resolve(DateTime today);
}
class PresetRange extends DashboardRange { final RangePreset preset; } // to = today, from = today − (days − 1)
class CustomRange extends DashboardRange { final DateRange range; }

// entities/daily_count.dart
class DailyCount extends Equatable { final DateTime date; final int count; }

// entities/product_type_count.dart
class ProductTypeCount extends Equatable {
  final String productType;  // raw backend value, e.g. "OTHER_FRESH_PRODUCTS"
  final int count;
  String get label;          // "Other fresh products"; unknown values are humanized the same way
}

// utils/fill_missing_days.dart — the backend omits days with no activity
List<DailyCount> fillMissingDays(List<DailyCount> counts, DateRange range); // one entry per day, 0 where missing, ordered

// repositories/dashboard_repository.dart
abstract class DashboardRepository {
  Future<Either<AdminFailure, List<DailyCount>>> getUserRegistrations(DateRange range);
  Future<Either<AdminFailure, List<DailyCount>>> getProductsAdded(DateRange range);
  Future<Either<AdminFailure, List<DailyCount>>> getReceipts(DateRange range);
  Future<Either<AdminFailure, List<ProductTypeCount>>> getProductTypeCounts();
}

// usecases/ — one per repository call; the three daily ones return fillMissingDays(...) results
class GetUserRegistrationsUseCase { }
class GetProductsAddedUseCase { }
class GetReceiptsUseCase { }
class GetProductTypeCountsUseCase { } // sorted by count desc, then label
```

### Data (`lib/features/dashboard/data/`)

```dart
class DailyCountModel extends DailyCount {
  factory DailyCountModel.fromJson(Map<String, dynamic> json, {String countKey = 'count'}); // receipts: 'totalReceipts'
}
class ProductTypeCountModel extends ProductTypeCount {
  factory ProductTypeCountModel.fromJson(Map<String, dynamic> json); // productType, productCount
}
class DashboardRemoteDataSource { } // 4 GETs; dates sent as yyyy-MM-dd
class DashboardRepositoryImpl implements DashboardRepository { } // DioException → mapDioException
```

### URL ↔ range (`lib/features/dashboard/presentation/dashboard_query.dart`)

```dart
// ?range=7d|30d|90d → PresetRange; ?from=YYYY-MM-DD&to=YYYY-MM-DD → CustomRange
// null when missing or invalid: unknown preset, unparseable date, from > to,
// to after today, or to − from > 100 days
DashboardRange? parseDashboardRange(Map<String, String> query, DateTime today);
Map<String, String> dashboardRangeQuery(DashboardRange range);
const kDefaultDashboardRange = PresetRange(RangePreset.last30);
```

### Presentation (`lib/features/dashboard/presentation/bloc/`)

```dart
enum DashboardSection { registrations, products, receipts, productTypes }

enum SectionStatus { loading, loaded, failure }
class SectionState<T> extends Equatable { final SectionStatus status; final T? data; final String? errorMessage; }

class DashboardState extends Equatable {
  final DashboardRange range;
  final DateRange resolvedRange;
  final SectionState<List<DailyCount>> registrations, products, receipts;
  final SectionState<List<ProductTypeCount>> productTypes;
}

sealed class DashboardEvent { }
class DashboardRangeChanged extends DashboardEvent { final DashboardRange range; } // from the URL
class DashboardRefreshed extends DashboardEvent { }                              // Refresh button: all 4
class DashboardSectionRetried extends DashboardEvent { final DashboardSection section; }

// DashboardBloc takes the 4 use cases and `DateTime Function() today` (injectable for tests).
// Range change refetches the 3 daily sections only; product types load once and on Refresh/Retry.
// A response for a range that is no longer current is dropped (quick successive range changes).
```

### Chart color (`lib/core/theme/chart_colors.dart`)

```dart
const kChartSeriesColor = Color(0x...); // single series hue, validated against the card surface
```

The exact value is decided in step 5 by running the validator. The chosen hex and the validator's output are recorded in a comment.

---

## Implementation plan

1. **Domain basics.** Add `fl_chart`. Add `DateRange`, `RangePreset`/`DashboardRange`, `DailyCount`, `ProductTypeCount` (with `label`) and `fillMissingDays`. Unit tests:
   - Preset resolution, including month and year boundaries.
   - `days` and `lengthInDays`.
   - Zero-fill: gaps, empty input, and out-of-range entries dropped.
   - Labels.
2. **URL ↔ range.** Add `parseDashboardRange` and `dashboardRangeQuery`. Unit tests: each preset, a valid custom range, every invalid case returning null, and a round trip.
3. **Data layer.** Add the models, `DashboardRemoteDataSource`, `DashboardRepositoryImpl`, the use cases and their get_it registrations. Tests with the fake HTTP adapter:
   - Exact paths and `from`/`to` query parameters.
   - `totalReceipts` parsing.
   - Zero-fill and sort applied through the use cases.
   - 400 `detail`, 401, 500 and network failures mapped.
4. **Bloc.** Add `DashboardBloc`, tested with a fake repository:
   - A range change loads the 3 daily sections; product types load once.
   - Refresh reloads all 4; Retry reloads one section.
   - One failing section leaves the others loaded.
   - A stale response is dropped.
5. **Chart color.** Run `validate_palette.js` on the candidate series color against the light card surface. Record the passing hex in `chart_colors.dart`, with the validator's output in a comment.
6. **Cards.** Add `StatTile`, `CountsTable` and `ChartCard`. `ChartCard` has a title, subtitle, Chart | Table toggle, and loading, error + Retry and empty states, with the chart as its `child`. Widget tests cover every state and the toggle.
7. **Charts.** Add two charts:
   - `DailyColumnChart`: an fl_chart `BarChart` with one column per day, sparse date labels, and a hover tooltip ("Sep 14 · 3").
   - `ProductTypeBarChart`: horizontal and sorted, with the value at each bar's end.

   Widget tests check one bar per day or type, matching values, and that zero-filled days are present.
8. **Range bar.** Add the preset segmented control, "Custom…" (`showDateRangePicker` with no future dates) and the Refresh button. A picked range over 100 days is not applied and shows "Choose a range of at most 100 days." Widget tests: a preset calls back with itself, a 101-day custom pick is rejected, a 100-day pick is accepted.
9. **Page and route.** Add `DashboardPage` and swap it in for the `/dashboard` placeholder, with a `DashboardBloc` per route.
   - The page reads the range from the URL and dispatches `DashboardRangeChanged`.
   - It replaces an invalid or missing range with `?range=30d`.
   - Range bar changes go through `context.go`.

   Widget tests with a fake repository:
   - `/dashboard` becomes `/dashboard?range=30d` and shows the tiles and charts.
   - `?range=7d` shows 7 columns.
   - An invalid `from` falls back to the default.
   - A failing section shows Retry while the others render.
10. **End-to-end manual check** against the real backend:
    - Totals match the backend responses.
    - Presets and custom ranges update the URL and the charts.
    - A reload keeps the range.
    - The product-type chart matches `GET /product-types`.

---

## Acceptance criteria

### Range and URL

- [ ] Opening `/dashboard` with no query replaces the URL with `/dashboard?range=30d`, and "Last 30 days" is selected.
- [ ] Selecting "Last 7 days" changes the URL to `/dashboard?range=7d`, and the daily charts show exactly 7 columns ending today.
- [ ] "Last 90 days" shows exactly 90 columns.
- [ ] A custom pick of 2026-09-01 → 2026-09-15 changes the URL to `/dashboard?from=2026-09-01&to=2026-09-15` and shows 15 columns.
- [ ] A custom pick spanning more than 100 days is not applied and shows "Choose a range of at most 100 days."
- [ ] The picker doesn't allow dates after today.
- [ ] Reloading the page keeps the selected range.
- [ ] An invalid query (unknown preset, bad date, `from` after `to`, `to` in the future, more than 100 days) is replaced with `?range=30d`.
- [ ] Every daily request sends `from` and `to` as `yyyy-MM-dd`, matching the selected range.

### Content

- [ ] Three stat tiles, "New users", "Products added" and "Receipts", each show the sum of their metric's daily counts for the range.
- [ ] Three daily column charts are shown, titled "New users per day", "Products added per day" and "Receipts per purchase date".
- [ ] The products chart is subtitled "Includes deleted products" and the receipts chart "Includes unconfirmed receipts".
- [ ] Days the backend omits appear as zero-height columns, so every day in the range is present.
- [ ] Hovering a column shows its date and count.
- [ ] "Products by type" lists every type returned by `GET /product-types` as a horizontal bar, sorted by count descending, with human labels and the count at each bar's end.
- [ ] "Products by type" is subtitled "All time · excludes deleted products" and doesn't change when the range changes.
- [ ] No chart has a legend, and no text is drawn in the series color.
- [ ] The series color in `chart_colors.dart` has a recorded passing `validate_palette.js` result against the card surface.

### Table view

- [ ] Every chart card has a Chart | Table toggle.
- [ ] In Table mode, a daily card lists one row per day (date, count) and the type card one row per type (type, count), with the same values as the chart.

### States

- [ ] While a card's data loads, that card and its stat tile show a spinner.
- [ ] When one endpoint fails, only its card shows the failure message and a Retry button; the other cards render normally.
- [ ] Retry refetches only that card's endpoint.
- [ ] A range with no activity for a metric shows "No new users in this range" (or "No products…" / "No receipts…") instead of a chart, and its tile shows 0.
- [ ] Refresh refetches all four endpoints, including product types.
- [ ] Changing the range refetches the three daily endpoints but not product types.
- [ ] A 401 on any dashboard request triggers SPEC 01's session-expired flow, with no dashboard-specific handling.

### Project

- [ ] `flutter analyze` reports no issues, `flutter test` passes, and `flutter build web` succeeds.

---

## Decisions

- **Yes:** Stat tiles, three daily charts and a product-type chart. The KPI row gives the headline; the charts give the trend.
- **No:** Charts only, or tiles only.
- **Yes:** Three separate single-series column charts. The metrics measure different things, so each gets its own chart with one axis.
- **No:** One multi-series or dual-axis chart. Different measures on shared axes mislead.
- **Yes:** Columns rather than lines for daily counts. These are discrete daily totals, often sparse, and a line would imply continuity between days.
- **Yes:** Zero-fill missing days on the client. The backend omits empty days, and skipping them would compress the time axis.
- **Yes:** A horizontal bar chart sorted by count for product types. It compares magnitude across ~17 long-named categories.
- **No:** A pie or donut chart. It's unreadable at 17 slices.
- **Yes:** One validated series color and no legends. Each chart has a single series named by its title.
- **Yes:** A Chart | Table toggle per card. Values stay reachable without hovering, for keyboard and screen-reader users.
- **Yes:** The toggle is `StatefulWidget` state. This is a deliberate exception to `CLAUDE.md`'s "toggles use a Cubit": the toggle is pure presentation, with no logic, events or side effects.
- **Yes:** Presets plus custom, with the range in the URL. Presets are stored as `range=30d` so shared links stay relative to today; custom ranges are stored as `from`/`to`. This is consistent with SPEC 01's deep links.
- **No:** Range kept in bloc state only. It would reset on reload.
- **Yes:** Over-long custom ranges are rejected after picking. `showDateRangePicker` can't limit the span while picking.
- **Yes:** Show the backend's current semantics as-is, and label them (receipts by purchase date including drafts, products including deleted ones). Changing them is a backend spec.
- **No:** A backend spec first.
- **Yes:** Totals only on the tiles. Deltas would double the requests and need their own design.
- **Yes:** Fetch on open and on range change, plus a Refresh button. No polling.
- **Yes:** Independent loading and error state per card. One failing endpoint shouldn't blank the dashboard.
- **Yes:** Drop stale responses after a quick range change by comparing against the current range, rather than adding `bloc_concurrency`.
- **Yes:** `fl_chart`. It's pure Flutter and MIT-licensed, with bar charts and tooltips that work on web.
- **No:** `syncfusion_flutter_charts` (commercial license), or `CustomPainter` (tooltips, axes and hit-testing all built by hand).
- **Yes:** `equatable` goes back from `^3.0.0` to `^2.1.0`. This was decided during implementation (step 1): every `fl_chart` version requires `equatable ^2`. The app only uses `props`, and all SPEC 01 tests pass on 2.1. Mobile is on the 2.x line too.
- **No:** `dependency_overrides` to keep `equatable` 3 under `fl_chart`. It's an unsupported combination that every upgrade would have to keep working.
- **Yes:** `spaceId` / `creatorId` filters deferred. There's no admin endpoint to list spaces to pick from.

---

## Risks

| Risk | Mitigation |
|---|---|
| The backend buckets days in its database timezone (`CAST(created_at AS DATE)`) while "today" is the browser's local date, so near midnight the last column can be off by a day | Accepted for SPEC 02 and listed as out of scope. Documented in the README so admins in other timezones know. |
| `fl_chart`'s API or rendering on web differs from expectations (new dependency) | Step 7 tests chart data, not pixels; step 10 checks rendering in the browser. The chart widgets wrap `fl_chart`, so it can be swapped. |
| At 90 columns, date labels get too narrow | Labels are sparse (about one per week at 30+ days). Exact values are in the tooltip and the table view. |
| Hover tooltips don't exist on touch screens | The app is desktop-first per SPEC 01. Tapping a column also shows the tooltip, and the table view has every value. |
| A slow response for an old range overwrites the current one | The bloc drops responses whose range isn't current. A test covers it. |
| `product-types` returns a type the app doesn't know | Labels are derived generically from the raw value, so new types render without a code change. |

---

## What is **not** in this spec

- `spaceId` / `creatorId` filters.
- Previous-period deltas.
- Backend changes to what the metrics count.
- Auto-refresh or polling.
- Dark mode, CSV export, printing.
- Timezone handling beyond the browser's local date.

Each one of those, if it lands, goes in its own spec.
