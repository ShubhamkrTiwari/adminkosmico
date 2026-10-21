# Walkthrough - Coupon API Contract Update

I have updated the Coupon API and the Admin App to match the new specification provided.

## Changes Made

### Backend Fixes
1.  **Endpoint Renaming**:
    - Update: `/api/admin/coupons/update/:id`
    - Toggle: `/api/admin/coupons/toggle/:id`
    - Delete: `/api/admin/coupons/:id`
2.  **Field Mapping**: Updated the routes to accept new field names from the client and map them to the database model:
    - `title` -> `description`
    - `discountValue` -> `discountAmount`
    - `validUntil` -> `expiryDate`
3.  **Response Alignment**: Updated the JSON responses for Toggle and Delete actions to match the expected format exactly.

### Admin App Fixes
1.  **Provider Update**: Updated `CouponProvider.dart` to use the new endpoints and handle the simplified toggle response (updating local state based on the `isActive` boolean).
2.  **Dialog Update**: Updated `CouponDialog` in `coupons_tab.dart` to send the correctly named fields (`title`, `discountValue`, `validUntil`) in the request body.

## Verification Results
- All administrative actions (Edit, Toggle, Delete) now use the simplified and renamed endpoints.
- The field names sent by the app match the requirements.
- The UI should correctly reflect status changes after toggling.

Please **restart your backend server** and test the coupon management actions in the admin app.
