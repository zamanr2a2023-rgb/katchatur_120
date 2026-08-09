# Bajatzu — Flutter Project Structure

```
lib/
├── main.dart
├── app.dart
├── core/theme|constants|network|utils
├── data/mock_data.dart
├── routes/app_router.dart | route_names.dart
├── features/
│   ├── auth/presentation/screens/   (login, register, forgot-password)
│   ├── home/presentation/screens/
│   ├── menu/presentation/screens/
│   ├── membership/presentation/screens/
│   └── donate/presentation/screens/
├── shared/widgets/                  (logo, button, field, card, nav, qr)
└── services/
```

## Routes
| Path | Screen |
|------|--------|
| `/` | Login (+ splash) |
| `/register` | Register |
| `/forgot-password` | Forgot password |
| `/home` | Home |
| `/menu` | Menu & socials |
| `/membership` | Membership (+ `?section=profile`) |
| `/donate` | Donate |
