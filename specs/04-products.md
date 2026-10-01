# SPEC 04 — Products: products list and product detail

> **Status:** Approved
> **Depends on:** SPEC 01–03 (shell, session, shared metrics, users), backend SPEC 01 (fixes the `creatorId` / `shoppingReceiptId` filters, the default `sort`, and the receipt-detail query)
> **Date:** 2026-10-01
> **Objective:** Replace the `/products` placeholder with a sortable, filterable, paginated products list and add a `/products/:productId` detail page. Link them from the user page, the dashboard and each other.

---

## Scope

**In:**

- **Shared product types.**
  - Move the type label helper (`OTHER_FRESH_PRODUCTS` → "Other fresh products") from `features/dashboard` to `lib/shared/products/`.
  - Add the fixed list of the backend's 17 `ProductType` values, used by the type filter.
  - The dashboard behaves as before.
- **Routing:** new `/products/:productId`, a sibling of `/products` inside the shell (like `/users/:userId`). The Products rail item stays highlighted.
- **Products list** (`/products`):
  - **Data:** `GET /api/v1/admin/products?sort&page&size=30`, plus `productType`, `creatorId` and `shoppingReceiptId` when set.
  - **Controls:** one row above the table, all stored in the URL.
    - **Sort:** Name A–Z / Z–A, Expires soonest / latest, Price low–high / high–low. Default: Name A–Z.
    - **Type:** "All types" or one of the 17.
    - **Creator chip** (only when filtered): "Added by alice@example.com ✕". The email comes from `GET /admin/users/{id}`; if that fails, the chip shows a short id. ✕ removes the filter.
    - **Receipt chip** (only when filtered): "Receipt: SuperMart · Sep 8, 2026 ✕". The label comes from `GET /admin/shopping-receipts/{id}`; if that fails, the chip shows a short id.
  - **URL:** `?sort=…&type=…&creatorId=…&receiptId=…&page=…`.
    - Each invalid value is dropped on its own, so a bad `page` doesn't lose a valid filter.
    - A missing `page` becomes 1.
    - Changing the sort or a filter resets `page` to 1.
  - **Table:** Name · Type · Expires · Price.
    - Expires shows the date and a status badge (icon + label): "Expired" before today, "Expires soon" within 3 days.
    - Price shows the amount and currency, or "—".
    - A row opens `/products/<id>`.
  - **Paging:** Previous / Next with "Products 31–60" (no total).
    - Next is disabled when a page has fewer than 30 rows.
    - A page with no rows shows "No more products", plus "Go to first page" when page > 1.
  - **States:** loading; error with Retry; "No products match these filters" (page 1, nothing found).
- **Product detail** (`/products/:productId`):
  - **Data:** `GET /api/v1/admin/products/{id}`.
  - **Header:** "← Back to products", which returns to the last list URL visited this session.
  - **Product card:** name, type, expiration with badge, price, storage spot type (e.g. "Fridge").
  - **Origin card:**
    - Creator (email and username), linking to `/users/<creatorId>`.
    - Space name, store, purchase date, and added at (local time).
    - "Other products on this receipt", linking to `/products?receiptId=<id>`.
    - Missing values show "—".
    - For a product without a receipt there is no creator, space or store, and the card says so.
  - **States:** loading; error with Retry. A 400 (unknown or malformed id) shows "Product not found" with the back link.
- **Entry points:**
  - **User page:** a "View products" link that opens `/products?creatorId=<id>`.
  - **Dashboard:** clicking a product-type label opens `/products?type=<TYPE>`. It's a direct link on the label and works from the keyboard.
- **Tests:**
  - The shared move.
  - The repository (exact requests, nullable fields, malformed bodies).
  - List URL parsing.
  - Both blocs, including chip lookups and dropping stale responses.
  - Widget tests for the list (controls, chips, badges, paging, states, URL) and the detail page (cards, links, not found).
  - The entry links from the user page and the dashboard.

**Out of scope (for future specs):**

- Name search, date filters, total counts or "of N" paging, a page-size choice. These need backend changes.
- Showing deleted products. The backend ignores `isDeleted`.
- Editing, moving or deleting products.
- Receipt detail pages and links (SPEC 05). Until then, the receipt chip and "Other products on this receipt" are the only receipt views.
- A space page, and storage spot names (only the type is available).

---

## Data model

### Shared products (`lib/shared/products/`)

- `product_type.dart`:
  - `String productTypeLabel(String raw)`, moved out of `ProductTypeCount.label`, which now calls it. Values the app doesn't know still read well.
  - `const kProductTypes = ['FRUITS', …, 'OTHER']`: the backend's 17 values, in backend order. This is the dropdown order.

### Products domain (`lib/features/products/domain/`)

```dart
enum ProductSort { nameAsc, nameDesc, expirationAsc, expirationDesc, priceAsc, priceDesc }
// → backend NAME_ASC … PRICE_DESC; URL name_asc … price_desc

class ProductFilters {        // Equatable
  final ProductSort sort;     // default nameAsc
  final String? productType;  // one of kProductTypes
  final String? creatorId;
  final String? receiptId;
}

class ProductSummary {        // one list row
  final String id, name, productType;
  final DateTime? expirationDate;   // calendar day (UTC midnight)
  final Money? price;
}

class Money { final num amount; final String currency; }  // both present, or Money is null

class ProductsPage {
  final List<ProductSummary> products;
  final int page;             // 1-based
  bool get hasPrevious => page > 1;
  bool get hasNext => products.length == kProductsPageSize;
  int get firstIndex, lastIndex;   // "Products 31–60"
}

class ProductDetails {
  final String id, name, productType;
  final DateTime? expirationDate;
  final String? storageSpotType;    // FRIDGE …
  final Money? price;
  final DateTime createdAt;
  final ProductOrigin? origin;      // null when shoppingReceiptId is null
}

class ProductOrigin {
  final String receiptId;
  final String? creatorId, creatorEmail, creatorUsername;
  final String? spaceName, storeName;
  final DateTime? purchaseDate;     // calendar day
}

enum ExpirationStatus { expired, soon, ok }
ExpirationStatus expirationStatus(DateTime day, DateTime today);  // soon = 0–3 days ahead
```

- `ProductsRepository`:
  - `getProducts(ProductFilters, {required int page})`
  - `getProduct(String id)`
  - `getCreatorEmail(String userId)`
  - `getReceiptLabel(String receiptId)` (store and purchase date)
- `kProductsPageSize = 30`.
- Use cases: `GetProducts`, `GetProductDetails`, `GetCreatorLabel`, `GetReceiptLabel`.

### Products data (`lib/features/products/data/`)

- `ProductsRemoteDataSource`:
  - `/api/v1/admin/products`: sends `sort`, `page` and `size`, plus `productType`, `creatorId` and `shoppingReceiptId` only when set.
  - `/products/{id}`.
  - `/users/{id}` (email only).
  - `/shopping-receipts/{id}` (store and date only).
  - Path ids go through `Uri.encodeComponent`.
- Models use the existing `json_readers.dart`, moved to `lib/core/network/` so both features can use it.
  - Every field the backend may return as null is nullable.
  - `price` reads `num`. A price without a currency, or a currency without a price, becomes `null`.
- `ProductsRepositoryImpl` wraps every call in `guardRequest`.

### Products presentation (`lib/features/products/presentation/`)

- `products_list_query.dart`:
  - `kProductsPath`, `ProductsListQuery(filters, page)`, `parseProductsListQuery(query)`, `productsListLocation(q)`, and the default (`?sort=name_asc&page=1`).
  - Each invalid value is dropped on its own: an unknown sort or type, a non-UUID id, or a page that doesn't match `^[1-9]\d{0,8}$`.
- `ProductsListLocation`: same as `UsersListLocation`, for the detail page's back link.
- `ProductsListBloc` (events `ProductsListRequested(query)`, `ProductsListRetried`):
  - Separate `SectionState`s for the page, the creator chip label and the receipt chip label.
  - Chip lookups run in parallel with the page and are cached by id, so changing pages doesn't refetch them.
  - Stale responses are dropped.
- `ProductDetailBloc` (events `ProductDetailRequested(id)`, `Retried`): `loading` / `loaded` / `failure` / `notFound` (on `ValidationFailure`).
- Pages: `ProductsListPage`, `ProductDetailPage`.
- Widgets:
  - `ProductsControls`: sort and type dropdowns, plus the chips.
  - `ProductsTable`: horizontal scroll; reuses `kMissingValue`.
  - `ExpirationCell`: the date plus a badge. "Expired" uses the error color and a warning icon; "Expires soon" uses the tertiary color and a clock icon. Both always have a text label.
  - `ProductCard`, `ProductOriginCard`.
  - `PaginationBar`: reused from users, moved to `lib/shared/widgets/`, with an optional "of N" that products leave out.
- `formatMoney(Money)`: "2.50 USD", always 2 decimals, with the currency code (no symbol table).
- `today` can be injected into both blocs and the badge, as on the dashboard.

---

## Implementation plan

1. **Shared moves (no behavior change).**
   - `productTypeLabel` and `kProductTypes` move to `lib/shared/products/`; `ProductTypeCount.label` delegates to it.
   - `json_readers.dart` moves to `lib/core/network/`.
   - `PaginationBar` moves to `lib/shared/widgets/`, with "of N" made optional.
   - Existing tests are relocated, plus a test pinning `kProductTypes` to the backend's 17 values.
2. **Domain.**
   - `ProductSort` (backend and URL mapping), `ProductFilters`, `Money`, `ProductSummary`, `ProductsPage` (`hasNext`, `firstIndex`, `lastIndex`), `ProductDetails`, `ProductOrigin` and `expirationStatus`.
   - The repository interface and the 4 use cases.
   - Unit tests:
     - Sort mappings.
     - Page maths: a full page has next, a short page doesn't.
     - Expiration boundaries: yesterday, today, +3 and +4 days.
3. **Data.**
   - Remote data source, models and `ProductsRepositoryImpl`.
   - Repository tests with a fake HTTP adapter:
     - Exact query parameters (filters only when set) and id encoding.
     - Nullable fields, and a price without a currency.
     - The email and receipt-label lookups.
     - 400 → `ValidationFailure`; malformed bodies → `ServerFailure`.
4. **List URL and location.**
   - `products_list_query.dart` and `ProductsListLocation`, registered in DI.
   - Tests: each param valid and invalid on its own, the defaults, a round trip, and the page reset.
5. **List bloc.**
   - `ProductsListBloc` and a hand-written `FakeProductsRepository`.
   - Tests:
     - The initial load runs the page and both chip lookups in parallel.
     - A chip failure doesn't block the page.
     - Chip labels are cached across pages.
     - Retry.
     - Stale responses are dropped (mutation-checked).
6. **List page and routing.**
   - `ProductsListPage`: controls, chips, table, badges, pagination, states, and URL handling (normalize with `replace`, apply changes with `go`).
   - The `/products` route wired through `RouteDependencies`, and the sibling `/products/:productId` route.
   - Widget tests through the real router, including 800px layouts.
7. **Detail.**
   - `ProductDetailBloc` and `ProductDetailPage`.
   - Tests:
     - The cards, and a product without an origin.
     - The creator link opens `/users/<id>`.
     - "Other products on this receipt" opens `/products?receiptId=…`.
     - Not found, and retry.
     - The back link returns to the last list URL.
8. **Entry links.**
   - "View products" on the user page.
   - A type link on each dashboard product-type label.
   - Widget tests for both navigations.
9. **Polish.**
   - `flutter analyze`, the full test run and `flutter build web`.
   - Render the list and detail pages to images and inspect them.
   - Update the README if there are new known limitations.
10. **Manual check** against the dev backend (a checklist for the user).

---

## Acceptance criteria

### Shared moves

- [ ] The dashboard and users pages behave as before; all earlier tests pass after the move.

### Products list

- [ ] `/products` normalizes to `?sort=name_asc&page=1` and shows 30 products sorted by name.
- [ ] Each sort option reorders the list as the backend does, and the URL reflects it.
- [ ] The type filter shows only that type; "All types" clears it.
- [ ] `?creatorId=`:
  - [ ] Shows the chip "Added by <email>" and only that user's products.
  - [ ] ✕ removes the filter.
  - [ ] If the email lookup fails, the chip shows a short id and the list still loads.
- [ ] `?receiptId=` shows the chip "Receipt: <store> · <date>" and only that receipt's products.
- [ ] An invalid sort, type, id or page is dropped on its own; valid filters are kept.
- [ ] Changing the sort or a filter resets to page 1.
- [ ] Paging:
  - [ ] Next is disabled on a short page.
  - [ ] Page 2 shows "Products 31–60".
  - [ ] An empty page past the end offers "Go to first page".
- [ ] Badges, each with an icon and a label:
  - [ ] "Expired" for past dates.
  - [ ] "Expires soon" from today to 3 days ahead.
  - [ ] None otherwise, and none without a date.
- [ ] Price shows "2.50 USD", or "—" when missing.
- [ ] Loading, error with Retry, and "No products match these filters" each show as specified.
- [ ] Reloading or sharing a list URL shows the same list.

### Product detail

- [ ] Shows the name, type, expiration with badge, price, storage spot type, and added at (local time).
- [ ] The origin card shows:
  - [ ] The creator, linked to their user page.
  - [ ] The space, store and purchase date.
  - [ ] "Other products on this receipt", linked.
  - [ ] Without a receipt, a note saying so.
- [ ] An unknown or malformed id shows "Product not found" with the back link.
- [ ] "← Back to products" returns to the last list URL (sort, filters, page).

### Entry points

- [ ] "View products" on a user page opens `/products?creatorId=<id>`.
- [ ] Clicking a dashboard type label opens `/products?type=<TYPE>`, also from the keyboard.

### Project

- [ ] `flutter analyze` is clean, all tests pass, and `flutter build web` succeeds.
- [ ] The Step 10 manual checklist is done against the dev backend.

---

## Decisions

- **Yes:** Previous / Next with no total.
  - The backend returns a plain list, and making it page-shaped would be a breaking change.
  - The cost: when the last page has exactly 30 rows, Next leads to an empty "No more products" page.
- **No:** Fetching 31 rows to detect a next page. `page` and `size` set the offset together, so it can't be done without breaking paging.
- **Yes:** Invalid URL values are dropped one at a time, keeping the valid ones.
  - Filters usually arrive from links (user page, dashboard, product page), and a bad `page` shouldn't lose a valid `creatorId`.
  - This differs from SPEC 03, where the whole list URL resets.
- **Yes:** The URL uses `sort=name_asc`, and the backend gets `NAME_ASC`. URLs stay lowercase and readable, and the mapping lives in one enum.
- **Yes:** The URL uses `receiptId`, and the backend gets `shoppingReceiptId`. It's shorter, and SPEC 05's receipt routes will use the same name.
- **Yes:** Chips look up the creator's email and the receipt's store and date. A failed lookup falls back to a short id and never blocks the list.
- **Yes:** The product types are hard-coded in the app, with a test pinning the 17 values. The backend has no endpoint listing all types; `/product-types` only returns types in use.
- **Yes:** Badges use the local "today" (injectable) and a 3-day window. Each has an icon and a label, never color alone.
- **Yes:** Prices are formatted by hand as "2.50 USD". That avoids adding `intl` for one format, and `formatCount` is already hand-written.
- **Yes:** `/products/:productId` is a sibling route, as learned with `/users/:userId` in SPEC 03.
- **Yes:** `PaginationBar` and `json_readers` move to shared folders now that a second feature uses them.
- **No:** Linking the receipt itself before SPEC 05. "Other products on this receipt" is the receipt view until then.

---

## Risks

| Risk | Mitigation |
|---|---|
| The backend adds a product type the app doesn't know | `productTypeLabel` derives labels from the raw value, so list rows still read well. The dropdown offers only the 17 known types, and an unknown `type` in the URL is dropped. |
| Expiration dates shift a day across timezones | The backend sends `expirationDate` as a plain date. It is parsed as a calendar day (UTC midnight) and compared with local today, as in SPEC 02/03. |
| Chip lookups race with page changes or filter removal | Lookups are cached by id and stale responses are dropped. Step 5 has a mutation-checked test. |
| `price` arrives as an int, double or string | The model reads `num`; anything else becomes a `ServerFailure`. Step 3 tests cover both int and double. |
| The backend fix (backend SPEC 01) isn't deployed when testing | The creator and receipt filters would return 500s. The manual checklist starts by confirming the backend branch is running. |

---

## What is **not** in this spec

- Name search, date filters, totals, or a page-size choice.
- Deleted products.
- Editing, moving or deleting products.
- Receipt pages and links (SPEC 05), space pages, or storage spot names.
