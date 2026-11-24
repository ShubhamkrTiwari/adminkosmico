# Implementation Plan - Backend Routes & Revenue Fix

Fix the JSON error and ensure cancelled orders are excluded from revenue calculations.

## User Review Required

> [!IMPORTANT]
> - I will modify the dashboard logic to strictly exclude orders with status `cancelled` from all revenue and order count metrics.
> - I will implement the missing Shiprocket endpoints in the backend to fix the "Unexpected token '<'" error in the Flutter app.

## Proposed Changes

### Backend - Models

#### [MODIFY] [Order.js](file:///C:/Users/pc/StudioProjects/adminkosmico/backend/models/Order.js)
- Add `shiprocketOrderId`, `shipmentId`, and `trackingUrl` fields to the schema.

### Backend - Routes

#### [MODIFY] [adminRoutes.js](file:///C:/Users/pc/StudioProjects/adminkosmico/backend/routes/adminRoutes.js)
- **Revenue Fix**: Ensure `totalRevenue` and `totalOrders` queries exclude `{ status: 'cancelled' }`.
- **Daily Stats**: Add logic to calculate `ordersToday`, `ordersYesterday`, `revenueToday`, and `revenueYesterday` using the same exclusion rules.
- Calculations will use the `createdAt` field and local time boundaries.

#### [MODIFY] [orderRoutes.js](file:///C:/Users/pc/StudioProjects/adminkosmico/backend/routes/orderRoutes.js)
- Implement Shiprocket endpoints:
    - `POST /:id/shiprocket/create`
    - `POST /:id/shiprocket/cancel`
    - `GET /:id/shiprocket/track`
    - `POST /:id/shiprocket/return`
- These will return placeholder success responses for now to satisfy the UI.

### Flutter - Core

#### [MODIFY] [api_client.dart](file:///C:/Users/pc/StudioProjects/adminkosmico/lib/core/api_client.dart)
- Add error handling for non-JSON responses to prevent the app from crashing with a `FormatException`.

## Verification Plan

### Manual Verification
- **Dashboard**: Cancel an order and verify that "Total Revenue" and "Total Orders" decrease accordingly.
- **Shiprocket**: Click logistics buttons in the app and verify they return a "Success" message instead of an error.
