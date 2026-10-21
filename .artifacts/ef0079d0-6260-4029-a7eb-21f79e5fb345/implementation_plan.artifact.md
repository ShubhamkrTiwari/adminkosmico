# Implementation Plan - Update Coupon API Contract

The user has requested updates to the Coupon API endpoints and data structures to match a new specification.

## Proposed Changes

### Backend Changes

#### [MODIFY] [couponRoutes.js](file:///C:/Users/pc/StudioProjects/adminkosmico/backend/routes/couponRoutes.js)
- Update Endpoints:
    - `PUT /admin/update-coupon/:id` -> `PUT /update/:id`
    - `PATCH /admin/toggle-status/:id` -> `PATCH /toggle/:id`
    - `DELETE /admin/delete-coupon/:id` -> `DELETE /:id`
- Update Field Mapping (mapping new fields to existing model fields):
    - `title` -> `description` (or `code`? I'll assume `title` is the descriptive name)
    - `discountValue` -> `discountAmount`
    - `validUntil` -> `expiryDate`
- Update Responses:
    - Toggle response should match: `{ "success": true, "message": "...", "isActive": ... }`
    - Delete response should match: `{ "message": "Coupon removed successfully" }`

### Frontend Changes (Admin App)

#### [MODIFY] [coupon_provider.dart](file:///C:/Users/pc/StudioProjects/adminkosmico/lib/providers/coupon_provider.dart)
- Update `updateCoupon`, `deleteCoupon`, and `toggleStatus` to use new endpoints and payload structures.

#### [MODIFY] [coupon.dart](file:///C:/Users/pc/StudioProjects/adminkosmico/lib/models/coupon.dart)
- Update model to include mapping for the new field names if necessary for consistency.

#### [MODIFY] [coupons_tab.dart](file:///C:/Users/pc/StudioProjects/adminkosmico/lib/views/dashboard/coupons_tab.dart)
- Update `CouponDialog` to send the correct field names in the `data` map.

## Verification Plan

### Manual Verification
- Test Updating a coupon and verify the request payload in debug logs.
- Test Toggling a coupon and verify it updates the UI correctly.
- Test Deleting a coupon and verify it is removed from the list.
