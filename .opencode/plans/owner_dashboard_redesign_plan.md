# Owner Dashboard Redesign Plan

## Goal
Rewrite `lib/owner_dashboard.dart` with a professional, clean design using BottomNavigationBar + TabBar navigation, proper dark mode support, and the existing teal+gold design system.

## Architecture

```
OwnerDashboard
├── PremiumAppBar (title per tab, notifications, theme toggle, logout)
├── Body: StreamBuilder<Shop?>
│   └── IndexedStack (4 tabs via BottomNavigationBar)
│       ├── [0] Dashboard Tab
│       │   └── DefaultTabController (Overview | Queue)
│       │       ├── Overview:
│       │       │   ├── Header (gradient, shop photo, name, location, open/close)
│       │       │   ├── Revenue Cards (2x2 grid)
│       │       │   ├── Quick Actions (horizontal scroll tiles)
│       │       │   └── Revenue Reports CTA (gold card)
│       │       └── Queue: active bookings list (confirmed + in_progress)
│       ├── [1] Bookings Tab
│       │   ├── Filter chips (All | Confirmed | In Progress | Completed | Cancelled | Paid)
│       │   └── Filtered booking list
│       ├── [2] Services Tab
│       │   ├── Add service form card
│       │   └── Service list with toggle/edit/delete
│       └── [3] Settings Tab
│           └── Shop details form (same fields as before)
└── BottomNavigationBar (custom styled, matches customer app)
```

## Key Changes from Current Code

1. **Navigation**: Single scroll page → BottomNav + TabBar within Dashboard
2. **Dark Mode**: All hardcoded `Colors.white` replaced with `isDark ? AppColors.darkCard : Colors.white`
3. **Card Design**: Uses existing `AppColors.shadowCard`, proper border colors per theme
4. **Filter**: Status filter chips added to Bookings tab
5. **Queue**: Dedicated queue view in Dashboard tab showing only active bookings
6. **Unchanged**: All Firebase methods, models, dialogs, business logic, controller management, initState/dispose

## Files Modified
- Only `lib/owner_dashboard.dart` — full rewrite

## Files NOT Modified
- `app_styles.dart`, `models.dart`, `firebase_service.dart`, `theme_provider.dart`
- `invoice_page.dart`, `login_registration.dart`, `splash_screen.dart`, `main.dart`
- Any other files

## Design System
- Primary: `#00695C` (teal)
- Gold accent: `#D4AF37`
- Gradients: `AppColors.gradientPrimary`, `AppColors.gradientGold`
- Cards: white → dark surface with shadows
- Border radius: 20–28px consistent
- Typography: Inter/native, w700–w900 weights

## Verification
- Run `flutter analyze` to check for errors
- Run `flutter build` to verify compilation
