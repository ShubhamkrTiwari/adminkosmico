# Task List - Fix Coupons Not Showing

- [x] Backend Changes
    - [x] Add public coupon route in `server.js`
    - [x] Make GET all coupons public in `couponRoutes.js`
    - [x] Update GET coupons route to `/admin/list` in `couponRoutes.js`
    - [x] Update Update, Toggle, and Delete routes to match new API contract
- [x] Frontend Changes
    - [x] Update `CouponProvider` with robust parsing (Fix TypeError: "success": type 'String' is not a subtype of type 'int')
    - [x] Update `CouponsTab` UI for error reporting
    - [x] Make `Coupon` model parsing extremely robust (handle strings/doubles)
    - [x] Add coupon refresh to global refresh button
    - [x] Update `CouponProvider` to call new endpoints and use new field names
    - [x] Update `CouponsTab` dialog to send correct field names
- [x] Verification
    - [x] Confirm with user
