# Implementation Plan - App-wide Pagination

Implement pagination across the application to handle large datasets efficiently. The system will default to 10 items per page as requested.

## Proposed Changes

### [Component] Backend Updates
- **Categories**: Update `GET /api/admin/categories` in `categoryRoutes.js` to support `page` and `limit`.
- **Coupons**: Update `GET /api/admin/coupons/admin/list` in `couponRoutes.js` to support `page` and `limit`.

### [Component] Flutter Providers
Update the following providers to maintain pagination state (`currentPage`, `totalPages`, `hasMore`):
- `ProductProvider`
- `OrderProvider`
- `UserProvider`
- `CategoryProvider`
- `NotificationProvider`

Each provider will have:
- `int _currentPage`
- `int _totalPages`
- `bool _hasMore`
- `Future<void> fetchNextPage()` or similar.
- `fetchInitial()` (replaces current fetch, resets to page 1).

### [Component] UI Components
- Implement a reusable `PaginationControls` widget or a "Load More" indicator at the bottom of lists.
- Update `ProductsTab`, `OrdersTab`, `UsersTab`, `CategoriesTab`, and `NotificationsTab` to trigger page loads.

## Detailed Steps

### 1. Backend Pagination
#### [MODIFY] [categoryRoutes.js](file:///C:/Users/pc/StudioProjects/adminkosmico/backend/routes/categoryRoutes.js)
- Add `page` and `limit` logic to the GET route.
- Return `pagination` metadata in the response.

#### [MODIFY] [couponRoutes.js](file:///C:/Users/pc/StudioProjects/adminkosmico/backend/routes/couponRoutes.js)
- Add `page` and `limit` logic to the list route.
- Return `pagination` metadata in the response.

### 2. Frontend Providers
#### [MODIFY] [product_provider.dart](file:///C:/Users/pc/StudioProjects/adminkosmico/lib/providers/product_provider.dart)
- Update `fetchProducts` to accept `page`.
- Append products to `_products` if `page > 1`.
- Update pagination state from response metadata.

#### [MODIFY] [order_provider.dart](file:///C:/Users/pc/StudioProjects/adminkosmico/lib/providers/order_provider.dart)
- Similar updates as `ProductProvider`.

#### [MODIFY] [user_provider.dart](file:///C:/Users/pc/StudioProjects/adminkosmico/lib/providers/user_provider.dart)
- Similar updates as `ProductProvider`.

### 3. Frontend UI
#### [MODIFY] [products_tab.dart](file:///C:/Users/pc/StudioProjects/adminkosmico/lib/views/dashboard/products_tab.dart)
- Add a "Load More" button or infinite scroll listener.

#### [MODIFY] [users_tab.dart](file:///C:/Users/pc/StudioProjects/adminkosmico/lib/views/dashboard/users_tab.dart)
- Add pagination UI.

## Verification Plan
### Manual Verification
- Navigate to each tab (Products, Orders, Users, etc.).
- Add more than 10 items to ensure pagination triggers.
- Click "Load More" and verify that new items are appended correctly without duplicating or losing existing items.
- Verify that "Load More" disappears when no more data is available.
