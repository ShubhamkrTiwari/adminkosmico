# Implementation Plan - Dynamic Stat Trends

The user wants to replace the hardcoded percentage growth values in the dashboard stat cards with real data based on the backend response.

## User Review Required

> [!IMPORTANT]
> I will calculate the percentage growth based on "Today" vs "Yesterday" stats provided by the API. If "Yesterday" data is zero, the trend will be shown as `+100%` if today has data, or `0%` if both are zero.

## Proposed Changes

### Dashboard Overview
#### [MODIFY] [overview_tab.dart](file:///C:/Users/pc/StudioProjects/adminkosmico/lib/views/dashboard/overview_tab.dart)
- Add a helper method `_calculateTrend(num current, num previous)` to return a formatted trend string (e.g., `+10.5%`).
- Update the `StatCard` for **Total Revenue** to use `revenueToday` and `revenueYesterday` for trend calculation.
- Update the `StatCard` for **Total Orders** to use `ordersToday` and `ordersYesterday` for trend calculation.
- Dynamically set the `isTrendPositive` flag based on whether the current value is greater than or equal to the previous value.

## Verification Plan

### Manual Verification
- Launch the app and view the Dashboard Overview.
- Verify that the percentage values change based on the actual numbers shown in the "Daily Performance" section below.
- Test scenarios with zero values to ensure no "Divide by Zero" crashes occur.
