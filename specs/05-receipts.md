# SPEC 05 — Receipts: receipts list and receipt detail

> **Status:** Approved
> **Depends on:** SPEC 01–04; backend SPEC 02 (paged, labelled receipts list and the `deleted` flag on receipt products)
> **Date:** 2026-10-01
> **Objective:** Replace the `/receipts` placeholder with a paged list of receipts purchased in a URL-addressable date range, optionally for one creator. Add a `/receipts/:receiptId` page with the receipt and its products, and link both from the user and product pages.

---

## Scope

**In:**

- **Shared moves:**
  - `ExpirationCell`, `ExpirationBadge`, `expirationStatus` and `formatMoney` move from `features/products` to `lib/shared/products/`, so receipts can show the same badges and prices.
  - The creator-chip lookup (a user's email by id) moves to a shared place, so both lists use it.
  - Products behaves as before.
- **Routing:** new `/receipts/:receiptId`, a sibling of `/receipts` inside the shell. The Receipts rail item stays highlighted.
- **Receipts list** (`/receipts`):
  - **Data:** `GET /api/v1/admin/shopping-receipts?from&to&page&size=30`, plus `userId` when filtered by creator.
  - **Range:** "Purchased between…", using the same `RangeBar` as the dashboard: presets of 7 / 30 / 90 days (default 30) plus custom, capped at **100** days.
  - **Creator chip** (only when filtered):
    - Reads "Added by alice@example.com ✕".
    - If the email lookup fails, shows a short id instead.
    - ✕ removes the filter.
  - **URL:** `?range=…` (or `from`/`to`), `creatorId=…`, `page=…`.
    - Each invalid value is dropped on its own, as on the products list: a bad range becomes `30d`, a bad page becomes 1.
    - A new range or filter resets the page to 1.
  - **Table:** Purchased · Store · Added by · Space · Products.
    - Missing names show "—".
    - "Products" is the count of non-deleted products.
    - A row opens `/receipts/<id>`.
    - Subtitle: "Includes unconfirmed receipts".
  - **Paging:** "31–60 of 214" with Previous / Next. Past the last page: "No receipts on this page" and "Go to first page".
  - **States:** loading; error with Retry; "No receipts purchased in this range".
- **Receipt detail** (`/receipts/:receiptId`):
  - **Data:** `GET /api/v1/admin/shopping-receipts/{id}`.
  - **Header:** "← Back to receipts" returns to the last list URL visited this session.
  - **Receipt card:**
    - Store, purchase date, and uploaded (local time).
    - Added by: email and username, linked to `/users/<creatorId>`.
    - Space.
    - Image: "Image attached (JPEG)" or "No image".
    - Missing values show "—".
  - **Products card:**
    - Table: Name · Type · Expires (with badge) · Price.
    - Deleted products show a "Deleted" label, aren't clickable, and are left out of the total. Other rows open `/products/<id>`.
    - Total per currency, from non-deleted products with a price: "Total 23.40 USD", one line per currency. Adds "2 products without a price" when there are some.
    - An empty receipt shows "No products on this receipt".
  - **States:** loading; error with Retry. A 400 (unknown or malformed id) shows "Receipt not found" with the back link.
- **Entry points:**
  - **User page, receipts table:** rows now open `/receipts/<id>`, as SPEC 03 promised.
  - **User page:** a "View receipts" link next to "View products" opens `/receipts?creatorId=<id>` (default 30-day range).
  - **Product page, Origin card:** "View receipt" opens `/receipts/<receiptId>`, replacing "Other products on this receipt". The products list's receipt filter keeps working for shared or typed URLs.
- **Tests:**
  - The shared moves.
  - The repository: exact requests, paged parsing, nullable fields, `deleted`, malformed bodies.
  - List URL parsing.
  - Both blocs, including the chip lookup and dropping stale responses.
  - Widget tests for the list (range, chip, table, paging, states, URL) and the detail page (cards, deleted rows, totals, links, not found).
  - The three entry points.

**Out of scope (for future specs):**

- Viewing the receipt image: it needs a signed-URL endpoint.
- A receipt status (draft or confirmed): no backend field yet.
- A space filter, search, and other sort orders.
- Editing, confirming or deleting receipts.
- SPEC 06 (register admins).

---

## Data model

### Shared moves

- `lib/shared/products/`, moved from `features/products`:
  - `expiration_status.dart` (`ExpirationStatus`, `expirationStatus`, `kExpiresSoonDays`).
  - `money.dart` (`Money`) and `format_money.dart`.
  - `widgets/expiration_cell.dart` (`ExpirationCell`, `ExpirationBadge`).
- `lib/shared/creators/`, the creator chip's lookup, out of products:
  - `CreatorLabelRepository.getCreatorEmail(userId)`, with its data source (`GET /admin/users/{id}`, reading `email`) and implementation.
  - `GetCreatorLabelUseCase` (moved).
  - `CreatorFilterChip`: the chip, plus `creatorChipLabel` and `shortId`, out of `ProductsControls`.
  - `ProductsRepository` loses `getCreatorEmail`, and `ProductsListBloc` uses the shared use case.
- `lib/core/network/admin_api_paths.dart`: `kAdminUsersApiPath`, `kAdminProductsApiPath` and `kAdminShoppingReceiptsApiPath`. The users and products data sources use these instead of their own constants.

### Receipts domain (`lib/features/receipts/domain/`)

```dart
class ReceiptSummary {        // one list row
  final String id;
  final String? creatorId, creatorEmail, creatorUsername;
  final String? spaceName, storeName;
  final DateTime purchaseDate;   // calendar day (UTC midnight)
  final int productCount;        // excludes deleted products
}

class ReceiptsPage {          // like UsersPage
  final List<ReceiptSummary> receipts;
  final int page, size, totalElements, totalPages;
  int get firstIndex, lastIndex;  bool get hasPrevious, hasNext;
}

class ReceiptDetails {
  final String id;
  final String? creatorId, creatorEmail, creatorUsername;
  final String? spaceName, storeName;
  final DateTime purchaseDate;   // calendar day
  final DateTime createdAt;      // instant
  final String? imageMimeType;   // null = no image
  final List<ReceiptProduct> products;   // oldest first, deleted included
}

class ReceiptProduct {
  final String id, name, productType;
  final DateTime? expirationDate;
  final Money? price;
  final bool deleted;
}

/// Non-deleted products only: amounts summed in cents per currency, plus how
/// many had no price. Currencies in first-seen order.
class ReceiptTotals { final List<Money> totals; final int withoutPrice; }
ReceiptTotals receiptTotals(List<ReceiptProduct> products);
```

- `ReceiptsRepository`:
  - `getReceipts(DateRange purchasedBetween, {String? creatorId, required int page})`.
  - `getReceipt(String id)`: a `ValidationFailure` for an unknown or malformed id (the backend answers 400).
- `kReceiptsPageSize = 30`.
- Use cases: `GetReceipts`, `GetReceiptDetails`.

### Receipts data (`lib/features/receipts/data/`)

- `ReceiptsRemoteDataSource`:
  - Sends `from`, `to`, `page`, `size=30`, plus `userId` only when a creator is set.
  - The detail id goes through `Uri.encodeComponent`.
- Models use `json_readers` and `readMoney`:
  - `imageMimeType` is `null` when `receiptImageId` is null.
  - `deleted` must be a bool; anything else is a `ServerFailure`.
- `ReceiptsRepositoryImpl` wraps every call in `guardRequest`.

### Receipts presentation (`lib/features/receipts/presentation/`)

- `receipts_list_query.dart`:
  - `kReceiptsPath = '/receipts'`, `kReceiptsMaxRangeLengthInDays = 100`.
  - `ReceiptsListQuery(range, creatorId, page)`. `withRange` and `withCreator` reset the page to 1; `withPage` changes it.
  - `parseReceiptsListQuery(query, today)` drops each invalid value on its own.
  - `receiptsListQueryParameters`, `receiptsListLocation`, and the default `?range=30d&page=1`.
- `ReceiptsListLocation`: the last list URL, for the back link.
- `ReceiptsListBloc`:
  - Events: `ReceiptsListRequested(query)`, `ReceiptsListRetried`.
  - State: `query`, `resolvedRange`, the page's `SectionState`, and the creator label's `SectionState` (`null` without a filter).
  - The chip label loads in parallel with the page and is cached by id, as in products.
  - Stale answers are dropped by request number.
  - `today` is injectable.
- `ReceiptDetailBloc`:
  - Events: `ReceiptDetailRequested(id)`, `ReceiptDetailRetried`.
  - Statuses: `loading` / `loaded` / `failure` / `notFound`.
  - `today` is injectable for the badges, like the product bloc.
- Pages: `ReceiptsListPage`, `ReceiptDetailPage`.
- Widgets:
  - `ReceiptsTable`: horizontal scroll.
  - `ReceiptCard`.
  - `ReceiptProductsCard`: the table, a "Deleted" label (icon + text) and the totals.
  - `formatImageType('image/jpeg')` → "JPEG".

---

## Implementation plan

1. **Shared moves (no behavior change).**
   - Move expiration and money to `lib/shared/products/`.
   - Move the creator lookup to `lib/shared/creators/` (repository, data source, use case, `CreatorFilterChip`):
     - `ProductsRepository` loses `getCreatorEmail`.
     - `ProductsListBloc` and DI use the shared use case.
     - `ProductsControls` uses `CreatorFilterChip`.
   - Add `admin_api_paths.dart`, and switch the users and products data sources to it.
   - Tests:
     - Existing tests move with their code. All products and users tests pass unchanged.
     - A repository test for the creator lookup.
2. **Domain.**
   - Entities: `ReceiptSummary`, `ReceiptsPage`, `ReceiptDetails`, `ReceiptProduct`, plus `receiptTotals`.
   - The repository interface and 2 use cases.
   - Unit tests:
     - Page maths.
     - `receiptTotals`: one currency, mixed currencies, deleted products excluded, missing prices, an empty receipt, and cents (`0.1 + 0.2` → `0.30`).
3. **Data.**
   - Remote data source, models, `ReceiptsRepositoryImpl`.
   - Repository tests with a fake HTTP adapter:
     - Exact query parameters (`userId` only when set) and id encoding.
     - Paged parsing.
     - Nullable names and image.
     - `deleted`.
     - A 400 becomes a `ValidationFailure`; malformed bodies become a `ServerFailure`.
4. **List URL and location.**
   - `receipts_list_query.dart` and `ReceiptsListLocation`, registered in DI.
   - Tests:
     - Each parameter valid and invalid on its own; a bad range becomes `30d` and keeps `creatorId`.
     - 100 days accepted, 101 rejected.
     - Round trip.
     - Page reset.
5. **List bloc.**
   - `ReceiptsListBloc` and `FakeReceiptsRepository`.
   - Tests:
     - The page and the chip load in parallel.
     - A chip failure doesn't block the page.
     - The label is cached across pages.
     - Retry.
     - Stale answers are dropped (mutation-checked).
6. **List page and routing.**
   - `ReceiptsListPage`: range bar, chip, table, paging, states, and URL handling (normalize with `replace`, change with `go`).
   - The `/receipts` route via `RouteDependencies`, plus the sibling `/receipts/:receiptId`.
   - Widget tests through the real router, including 800px.
7. **Detail.**
   - `ReceiptDetailBloc` and `ReceiptDetailPage`.
   - Tests:
     - Cards, including missing values and the image line.
     - Deleted rows: labelled, not clickable, excluded from the total.
     - Totals per currency, and the "without a price" note.
     - The creator link opens `/users/<id>`.
     - A product row opens `/products/<id>`.
     - Not found, retry, and the back link to the last list URL.
8. **Entry links.**
   - User page: receipt rows open the receipt, plus a "View receipts" link.
   - Product page: "View receipt" replaces "Other products on this receipt".
   - Widget tests for each navigation; update the existing product page test.
9. **Polish.**
   - `flutter analyze`, the full test run, `flutter build web`.
   - Render the list and detail pages to images and check them.
   - README: new known limitations.
   - `CLAUDE.md`: update the receipts endpoint note.
10. **Manual check** against the dev backend (a checklist for the user).

---

## Acceptance criteria

### Shared moves

- [ ] The dashboard, users and products behave as before; all earlier tests pass after the moves.

### Receipts list

- [ ] `/receipts` normalizes to `?range=30d&page=1` and shows receipts purchased in the last 30 days, newest purchase first.
- [ ] Rows show Purchased · Store · Added by · Space · Products, with "—" for missing values. The subtitle reads "Includes unconfirmed receipts".
- [ ] Presets and a custom range up to 100 days work. A longer range shows the range-too-long message and changes nothing.
- [ ] `?creatorId=`:
  - [ ] Shows "Added by <email>" and only that user's receipts.
  - [ ] ✕ removes the filter.
  - [ ] If the email lookup fails, the chip shows a short id and the list still loads.
- [ ] An invalid range, id or page is dropped on its own; valid values are kept.
- [ ] A new range or filter resets to page 1.
- [ ] Paging shows "31–60 of N". Previous / Next are disabled at the ends. A page past the end offers "Go to first page".
- [ ] Loading, error with Retry, and "No receipts purchased in this range" appear as specified.
- [ ] Reloading or sharing a list URL shows the same list.

### Receipt detail

- [ ] Shows the store, purchase date, upload time (local), creator (linked), space and image line, with "—" for missing values.
- [ ] Products are listed oldest first with type, expiration badge and price.
- [ ] Deleted products show "Deleted", aren't clickable, and are excluded from the total.
- [ ] The total is shown per currency, with a note for products without a price. An empty receipt shows "No products on this receipt".
- [ ] A product row opens its product page.
- [ ] An unknown or malformed id shows "Receipt not found" with the back link.
- [ ] "← Back to receipts" returns to the last list URL.

### Entry points

- [ ] Receipt rows on a user page open the receipt.
- [ ] "View receipts" on a user page opens `/receipts?range=30d&creatorId=<id>&page=1`.
- [ ] "View receipt" on a product page opens the receipt; "Other products on this receipt" is gone.

### Project

- [ ] `flutter analyze` is clean, all tests pass, and `flutter build web` succeeds.
- [ ] The step 10 manual checklist is done against the dev backend.

---

## Decisions

- **Yes:** Paging like the users list ("31–60 of N"), since backend SPEC 02 returns a total.
- **Yes:** Invalid URL values are dropped one at a time, as on the products list. Receipts often arrive with a `creatorId` from the user page, and a bad range shouldn't lose it.
- **Yes:** Default to the last 30 days, capped at 100 (the backend's limit), using the shared `RangeBar`.
- **Yes:** "View receipts" opens the default 30-day range. Older receipts are one range change away, and the user page already lists them all.
- **Yes:** Deleted products appear on the receipt page, labelled and not linked. They were on the receipt, but their product page would say "not found".
- **Yes:** Totals in cents, per currency, from non-deleted products only:
  - Summing floats would show "0.30000000000000004".
  - Mixing currencies would be wrong.
  - Deleted products are no longer in the space.
- **Yes:** "View receipt" replaces "Other products on this receipt", because the receipt page lists all its products. The `?receiptId=` filter stays on the products list, so shared URLs keep working.
- **Yes:** The creator lookup and chip move to `lib/shared/creators/`, and expiration and money to `lib/shared/products/`, now that two features use them. This follows SPEC 03's shared metrics move.
- **Yes:** `admin_api_paths.dart` declares the admin API paths once, instead of once per data source.
- **No:** A receipt status, an image, or a space filter. There is no backend support yet, or no page to set them from.

---

## Risks

| Risk | Mitigation |
|---|---|
| The backend without SPEC 02 returns a plain array | The list fails with a `ServerFailure` ("Something went wrong"). The README notes the dependency, and the manual check starts by confirming the backend branch. |
| Purchase dates near midnight appear a day off | The range uses browser-local days, while the backend stores purchase dates at UTC midnight. Same limitation as the users list; documented in the README. |
| The creator-lookup move breaks products | Step 1 runs every products test unchanged after the move. |
| Rounding in totals | Totals are summed in integer cents; `0.1 + 0.2` is a test case. |

---

## What is **not** in this spec

- The receipt image, receipt status, a space filter, search, other sort orders.
- Editing, confirming or deleting receipts.
- SPEC 06 (register admins).
