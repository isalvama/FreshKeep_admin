# SPEC 03 — Users: registered-users list and user detail

> **Status:** Approved
> **Depends on:** SPEC 01 (shell, session, failures), SPEC 02 (range, charts and cards — moved to `lib/shared/metrics/` in step 1)
> **Date:** 2026-10-01
> **Objective:** Replace the `/users` placeholder with a paginated list of users registered in a URL-addressable date range, and add a `/users/:userId` detail page with the user's profile, spaces, receipts and last-30-days activity.

---

## Scope

**In:**

- **Shared metrics module (refactor, no behavior change).** Move to `lib/shared/metrics/`:
  - **Domain and URL:**
    - `DateRange`, the calendar-day utils, `DailyCount` and `fillMissingDays`.
    - The range choice, renamed `DashboardRange` → `SelectedRange` (`PresetRange` / `CustomRange` unchanged).
    - URL range parsing, with the maximum length as a parameter (100 for metrics, 90 for the users list).
  - **Data:** the daily-metrics data layer (registrations, products added, receipts: data source, repository, use cases). `getProductsAdded` and `getReceipts` gain an optional `creatorId`.
  - **Widgets:** the range bar (also taking the maximum length), `ChartCard`, `DailyColumnChart`, `StatTile`, `CountsTable` and the formatters.
  - **What stays in `features/dashboard`:** product types (repository, use case, chart), `DashboardBloc` and `DashboardPage`.
  - The dashboard behaves exactly as before. All SPEC 02 tests pass after moving with their code.
- **Routing:**
  - `resolveRedirect` treats sub-paths of a shell section (e.g. `/users/<id>`) as known; today only exact paths are.
  - New route `/users/:userId` inside the shell. The Users rail item stays highlighted.
- **Users list** (`/users`):
  - **Data:** `GET /api/v1/admin/users?from&to&page&size=30`.
  - **Range:** "Registered between…", with the same presets and custom picker as the dashboard (7 / 30 / 90 days, default 30), capped at **90** days (`to − from`).
  - **URL:** `?range=…` or `?from=…&to=…`, plus `page`.
    - A missing or invalid range or page is replaced with `?range=30d&page=1`.
    - Changing the range resets `page` to 1.
  - **Table:** columns Email · Username · Registered · Last login, newest first. Timestamps are in the browser's local time ("Sep 14, 2026, 14:32"). A row opens `/users/<id>`.
  - **Paging:** Previous / Next with "31–60 of 214", 30 per page. A page past the last one shows "No users on this page" and a "Go to first page" link.
  - **Footnote:** "For users who have never logged in, Last login shows their registration time."
  - **States:**
    - Loading shows a spinner.
    - An error shows the failure message and Retry.
    - No users shows "No users registered in this range".
- **User detail** (`/users/:userId`):
  - **Data:** `GET /api/v1/admin/users/{id}`, plus `GET /admin/metrics/products` and `GET /admin/metrics/shopping-receipts` with `creatorId=<id>` for the last 30 days.
  - **Header:** a "← Back to users" link that returns to the last list URL visited this session (default `/users?range=30d&page=1`).
  - **Profile card:** email, username, roles as chips ("User", "Admin"), registered and last login in local time, with the same last-login footnote.
  - **Spaces:** a list of the user's space names, or "Not a member of any space".
  - **Receipts:** a table of store name, purchase date and created (local time), newest first.
    - Titled "Receipts" and subtitled "Includes unconfirmed receipts"; "No receipts yet" when empty.
    - Rows aren't clickable yet; SPEC 05 adds the links.
  - **Activity:** two compact daily charts in `ChartCard`s, "Products added per day" and "Receipts per purchase date". Each is labelled "Last 30 days", carries SPEC 02's semantics subtitles, and has a Chart | Table toggle.
  - **States:** each part (profile with spaces and receipts, products activity, receipts activity) loads and fails independently, with Retry.
  - **Not found:** a 400 from the detail endpoint (unknown or malformed id) shows "User not found" and the back link instead of the page.
- **Tests:**
  - The shared-module move (existing tests, relocated) and the redirect sub-path rule.
  - The users repository (fake HTTP) and the list/page URL parsing.
  - Both blocs.
  - Widget tests for the list page (table, paging, states, URL) and the detail page (profile, spaces, receipts, activity, not found).

**Out of scope (for future specs):**

- Searching users by email or username, or listing users without a date range. That needs backend changes (a backend spec).
- A page-size selector, sorting by other columns, CSV export.
- Linking receipts to their detail page (SPEC 05), and linking spaces anywhere (there's no admin space page).
- A range control for the detail page's activity charts (fixed at 30 days).
- Editing, disabling or deleting users.
- Distinguishing "never logged in" from "logged in at registration" (the backend's `last_log_in` defaults to the registration time).

---

## Data model

### Shared metrics (`lib/shared/metrics/`), moved from `features/dashboard`

```dart
// domain/ — moved as-is, except:
const kMetricsMaxRangeLengthInDays = 100;                 // was kMaxRangeLengthInDays
sealed class SelectedRange extends Equatable { DateRange resolve(DateTime today); } // was DashboardRange
class PresetRange extends SelectedRange { }  // unchanged
class CustomRange extends SelectedRange { }  // unchanged
// date_range.dart, daily_count.dart, calendar_day.dart, fill_missing_days.dart — unchanged

// domain/repositories/metrics_repository.dart — the daily half of the old DashboardRepository
abstract class MetricsRepository {
  Future<Either<AdminFailure, List<DailyCount>>> getUserRegistrations(DateRange range);
  Future<Either<AdminFailure, List<DailyCount>>> getProductsAdded(DateRange range, {String? creatorId});
  Future<Either<AdminFailure, List<DailyCount>>> getReceipts(DateRange range, {String? creatorId});
}
// usecases: GetUserRegistrationsUseCase, GetProductsAddedUseCase({creatorId}), GetReceiptsUseCase({creatorId})
// data: DailyCountModel, MetricsRemoteDataSource (sends creatorId only when given), MetricsRepositoryImpl

// presentation/range_query.dart — was dashboard_query.dart
SelectedRange? parseRangeQuery(Map<String, String> query, DateTime today, {required int maxLengthInDays});
Map<String, String> rangeQuery(SelectedRange range);
const kDefaultSelectedRange = PresetRange(RangePreset.last30);

// presentation/section_state.dart — was inside dashboard_state.dart
enum SectionStatus { loading, loaded, failure }
class SectionState<T> extends Equatable { }

// presentation/widgets/ — RangeBar (was DashboardRangeBar; + maxLengthInDays, + optional leading label),
// ChartCard, DailyColumnChart, StatTile, CountsTable; presentation/format.dart (+ formatDateTime)
String formatDateTime(DateTime instant); // local time: "Sep 14, 2026, 14:32"
```

### Dashboard (`lib/features/dashboard/`), what stays

```dart
abstract class DashboardRepository {   // product types only now
  Future<Either<AdminFailure, List<ProductTypeCount>>> getProductTypeCounts();
}
// ProductTypeCount, GetProductTypeCountsUseCase, ProductTypeBarChart, DashboardBloc, DashboardPage — unchanged behavior
```

### Users domain (`lib/features/users/domain/`)

```dart
class RegisteredUser extends Equatable {
  final String id;              // users.id — also the creatorId for metrics
  final String email;
  final String username;
  final DateTime registeredAt;  // UTC instant
  final DateTime? lastLoggedAt; // UTC instant
}

class UsersPage extends Equatable {
  final List<RegisteredUser> users;
  final int page;               // 1-based, as the backend
  final int size;
  final int totalElements;
  final int totalPages;
  int get firstIndex;           // 1-based index of the first row ("31" in "31–60 of 214"); 0 when empty
  int get lastIndex;
}

class UserDetails extends Equatable {
  final String id, email, username;
  final DateTime registeredAt;
  final DateTime? lastLoggedAt;
  final List<String> roles;     // "USER", "ADMIN"
  final List<UserSpace> spaces;
  final List<UserReceipt> receipts;
}
class UserSpace extends Equatable { final String id; final String name; }
class UserReceipt extends Equatable {
  final String id;
  final DateTime createdAt;     // UTC instant
  final DateTime purchaseDate;  // calendar day
  final String? storeName;
}

abstract class UsersRepository {
  Future<Either<AdminFailure, UsersPage>> getUsers(DateRange registeredBetween, {required int page}); // size 30
  Future<Either<AdminFailure, UserDetails>> getUser(String userId);
}
class GetUsersUseCase { }
class GetUserDetailsUseCase { }
```

### Users data (`lib/features/users/data/`)

```dart
class RegisteredUserModel extends RegisteredUser { factory fromJson(...); }
class UsersPageModel extends UsersPage { factory fromJson(...); }       // {content, page, size, totalElements, totalPages}
class UserDetailsModel extends UserDetails { factory fromJson(...); }   // + nested spaces/receipts
class UsersRemoteDataSource { }  // GET /api/v1/admin/users, GET /api/v1/admin/users/{id}
class UsersRepositoryImpl implements UsersRepository { } // mapDioException; unreadable body → ServerFailure
```

### Users presentation (`lib/features/users/presentation/`)

```dart
// users_list_query.dart
const kUsersMaxRangeLengthInDays = 90;
class UsersListQuery extends Equatable { final SelectedRange range; final int page; }
UsersListQuery? parseUsersListQuery(Map<String, String> query, DateTime today); // null: invalid range or page < 1 / not an int
Map<String, String> usersListQueryParameters(UsersListQuery query);
const kDefaultUsersListQuery = UsersListQuery(range: kDefaultSelectedRange, page: 1);

// users_list_location.dart — remembers the last list URL for "← Back to users" (get_it singleton, in memory)
class UsersListLocation { String value = '/users?range=30d&page=1'; }

// bloc/users_list_bloc.dart
class UsersListState extends Equatable {
  final UsersListQuery query;
  final DateRange resolvedRange;
  final SectionState<UsersPage> users;
}
sealed class UsersListEvent { }
class UsersListQueryChanged extends UsersListEvent { final UsersListQuery query; } // from the URL
class UsersListRetried extends UsersListEvent { }
// Stale responses (query no longer current) are dropped, as in DashboardBloc.

// bloc/user_detail_bloc.dart
enum UserDetailSection { details, productsActivity, receiptsActivity }
class UserDetailState extends Equatable {
  final String userId;
  final DateRange activityRange;                    // last 30 days
  final SectionState<UserDetails> details;
  final bool userNotFound;                          // details failed with ValidationFailure (400)
  final SectionState<List<DailyCount>> productsActivity, receiptsActivity;
}
sealed class UserDetailEvent { }
class UserDetailRequested extends UserDetailEvent { final String userId; }
class UserDetailSectionRetried extends UserDetailEvent { final UserDetailSection section; }

// pages/users_list_page.dart, pages/user_detail_page.dart
// widgets/users_table.dart, pagination_bar.dart, user_profile_card.dart,
//         user_spaces_card.dart, user_receipts_card.dart, last_login_footnote.dart
```

---

## Implementation plan

1. **Shared metrics move.** Move the files listed above to `lib/shared/metrics/`.
   - Rename `DashboardRange` → `SelectedRange`, `DashboardRangeBar` → `RangeBar`, and `dashboard_query` → `range_query`.
   - Add the `maxLengthInDays` parameters and the optional `creatorId`.
   - Split `DashboardRepository` into `MetricsRepository` and a product-types-only `DashboardRepository`.
   - Move the tests with their code, and add `creatorId` request tests.
   - Check: all 191 existing tests pass (relocated), `flutter build web` succeeds, and the dashboard behaves the same.
2. **Redirect sub-paths.** `resolveRedirect` accepts `<section>/…` paths while authenticated. Tests:
   - `/users/abc` stays.
   - `/userszzz` and `/nope/users` still go to `/dashboard`.
   - Logged out, `/users/abc` goes to `/login?from=%2Fusers%2Fabc`.
3. **Users domain and data.** Entities, the repository, use cases, models, the data source, the repository implementation, and get_it registrations. Tests with the fake HTTP adapter:
   - The exact list request (`from`, `to`, `page`, `size=30`) and detail request.
   - Parsing, including a null `lastLoggedAt` and a null `storeName`.
   - `firstIndex` / `lastIndex`.
   - 400, 401, 500, network and malformed-body failures mapped.
4. **List URL and location memory.** `parseUsersListQuery`, `usersListQueryParameters` and `UsersListLocation`. Unit tests:
   - Presets and custom ranges; 90 days accepted, 91 rejected.
   - Page `1`, `2`, missing, `0`, `-1` and `x`.
   - A round trip.
5. **`UsersListBloc`.** Tests: a query change loads that page for the resolved range; Retry reloads; a stale response is dropped; a failure is kept in state.
6. **Users list page.** `UsersTable`, `PaginationBar`, the footnote, the states, and the `/users` route. The range bar is reused with a 90-day cap and a "Registered between" label. Widget tests:
   - `/users` becomes `?range=30d&page=1`.
   - Rows show local times, and a row opens `/users/<id>`.
   - Next/Previous update `page`; changing the range resets `page` to 1.
   - "31–60 of 214"; a page past the end shows the empty-page message and link.
   - Error with Retry, and the empty state.
   - A 91-day custom pick is rejected.
7. **`UserDetailBloc`.** Tests:
   - Requesting loads the details plus both activity series with `creatorId` for the last 30 days.
   - A 400 sets `userNotFound`.
   - Each section retries independently.
8. **User detail page.** The profile card, spaces, the receipts table, the two activity `ChartCard`s, the back link (via `UsersListLocation`), the not-found state, and the `/users/:userId` route. Widget tests:
   - Profile fields, role chips and local times.
   - Spaces and their empty state; receipts newest first and their empty state.
   - Each activity chart has 30 columns.
   - Not found shows "User not found" and the back link.
   - The back link returns to the remembered list URL.
   - The Users rail item stays highlighted.
9. **End-to-end manual check** against the real backend:
   - The list matches `GET /admin/users` for the range and page.
   - The detail page matches `GET /admin/users/{id}`.
   - The activity totals match the metrics with `creatorId`.
   - An unknown id shows "User not found".

---

## Acceptance criteria

### Shared metrics move

- [ ] Range, daily metrics, chart/card/tile widgets and formatters live under `lib/shared/metrics/`; `features/dashboard` keeps only product types, its bloc and its page.
- [ ] Every SPEC 01 and SPEC 02 test still passes (relocated where its code moved), and the dashboard's behavior is unchanged.
- [ ] `getProductsAdded` / `getReceipts` send `creatorId` only when given.

### Routing

- [ ] While logged in, `/users/<id>` opens the user detail page and the Users rail item is highlighted.
- [ ] Unknown paths, including look-alikes such as `/userszzz`, still redirect to `/dashboard`.
- [ ] Logged out, `/users/<id>` redirects to `/login?from=%2Fusers%2F<id>` and returns there after login.

### Users list

- [ ] Opening `/users` replaces the URL with `/users?range=30d&page=1` and requests `GET /admin/users` with the resolved `from`/`to`, `page=1`, `size=30`.
- [ ] The range bar is labelled "Registered between" and offers Last 7 / 30 / 90 days and Custom….
- [ ] A custom pick spanning more than 90 days is not applied and shows "Choose a range of at most 90 days."
- [ ] Changing the range updates the URL and resets `page` to 1.
- [ ] An invalid range, or a `page` that isn't a positive integer, is replaced with `?range=30d&page=1`.
- [ ] The table shows Email, Username, Registered and Last login for each user, newest first, with times in the browser's local time ("Sep 14, 2026, 14:32").
- [ ] Clicking a row opens `/users/<id>`.
- [ ] The paging bar shows "31–60 of 214" for page 2 of 214 users. Previous is disabled on page 1 and Next on the last page. Both update `page` in the URL.
- [ ] A page past the last one shows "No users on this page" with a "Go to first page" link.
- [ ] No users in the range shows "No users registered in this range".
- [ ] A failed request shows the failure message and Retry; Retry reloads the same page.
- [ ] The footnote "For users who have never logged in, Last login shows their registration time." is shown under the table.
- [ ] Reloading keeps the range and page.

### User detail

- [ ] The page requests `GET /admin/users/<id>`, plus the products and receipts metrics with `creatorId=<id>` for the last 30 days.
- [ ] The profile card shows email, username, roles as chips ("User", "Admin"), registered and last login in local time, and the last-login footnote.
- [ ] Spaces lists the user's space names, or "Not a member of any space".
- [ ] Receipts lists store, purchase date and created time, newest first, subtitled "Includes unconfirmed receipts", or "No receipts yet". Rows aren't clickable.
- [ ] "Products added per day" and "Receipts per purchase date" each show 30 columns, are labelled "Last 30 days", carry their semantics subtitles, and have a Chart | Table toggle.
- [ ] If one part fails, only that part shows its error and Retry, and Retry reloads only that part.
- [ ] An unknown or malformed id (400) shows "User not found" with the back link, instead of the page.
- [ ] "← Back to users" returns to the last list URL visited this session (range and page included), or to `/users?range=30d&page=1` if none.

### Project

- [ ] `flutter analyze` reports no issues, `flutter test` passes, and `flutter build web` succeeds.

---

## Decisions

- **Yes:** Filter the list by registration date only, as the backend allows. It's labelled "Registered between…" so the filter is explicit.
- **No:** A backend spec first to add search. Search by email/username is a backend change for later.
- **Yes:** Reuse the dashboard's presets, picker and URL convention, capped at 90 days (the users endpoint's limit, not 100).
- **Yes:** A table with the page in the URL and a fixed 30 per page (the backend default). Reloads and shared links keep the position.
- **No:** A page-size selector (unneeded for now) or infinite scroll (it loses position on reload).
- **Yes:** Reset to page 1 when the range changes. The old page number means nothing in a new range.
- **Yes:** A page past the end shows an empty-page message with a link rather than an automatic redirect. The URL stays what the admin asked for.
- **Yes:** Show "Last login" as the backend gives it, with a footnote. The backend defaults it to the registration time; the UI doesn't guess.
- **No:** Hiding last login when it's close to registration. The mobile app logs in right after every registration, so the heuristic would hide real logins.
- **Yes:** Timestamps in the browser's local time; dates (purchase date) as calendar days.
- **Yes:** A detail page with profile, spaces, receipts and last-30-days activity charts (via `creatorId`). It uses data the backend already offers.
- **Yes:** Activity charts fixed at the last 30 days, with no range control. The detail page stays simple.
- **Yes:** Receipts on the detail page aren't links until SPEC 05. Linking now would land on a placeholder.
- **Yes:** Receipts are subtitled "Includes unconfirmed receipts". The detail endpoint doesn't expose each receipt's status, so drafts can't be marked individually.
- **Yes:** A 400 from the detail endpoint is shown as "User not found". The backend maps a missing user and a malformed id to 400.
- **Yes:** "← Back to users" uses the last list URL remembered in memory. List → detail uses `context.go`, so there's no stack to pop; browser Back also works.
- **Yes:** Move SPEC 02's range, daily-metrics and chart pieces to `lib/shared/metrics/`, with the max length as a parameter. Users and dashboard both depend on shared code, not on each other.
- **No:** Users importing from `features/dashboard`. It would couple two features.
- **Yes:** Rename `DashboardRange` → `SelectedRange` and `DashboardRangeBar` → `RangeBar`. They're no longer dashboard-specific.
- **Yes:** Product types stay in `features/dashboard`. Only the dashboard uses them.
- **Yes:** `resolveRedirect` accepts sub-paths of shell sections. Detail pages need it, while look-alikes (`/userszzz`) still don't match.

---

## Risks

| Risk | Mitigation |
|---|---|
| Moving SPEC 02 code breaks the dashboard | Step 1 is a pure move with renames. All 191 existing tests relocate with their code and must pass before step 2, plus a web build. |
| The backend computes `from`/`to` boundaries with its JVM default timezone (`Timestamp.valueOf(from.atStartOfDay())`) while times show in the browser's local time | Users near a boundary may appear one day off. Noted in the README's Known limitations, alongside the SPEC 02 note. |
| `totalElements` comes from a window function over the returned rows, so a page past the end returns 0 rows **and** `totalElements: 0` | The empty-page state can't show "of N" there. It shows "No users on this page" plus the first-page link, which needs no total. |
| A user id in the URL that isn't a UUID | The backend answers 400, which shows "User not found". No client-side UUID validation is needed. |
| The detail page fires three requests at once | They're independent sections; one failing doesn't block the others, and each has its own Retry. |
| A large receipts list on the detail page (no backend pagination) | Rendered as a scrollable table inside its card. Pagination would be a backend change and is out of scope. |

---

## What is **not** in this spec

- Search by email/username, or listing all users without a range.
- A page-size selector, other sort orders, CSV export.
- Receipt links (SPEC 05), space pages.
- A range control for per-user activity.
- Editing, disabling or deleting users.
- A real "never logged in" indicator.

Each one of those, if it lands, goes in its own spec.
