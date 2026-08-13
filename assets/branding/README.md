# App branding

Put the master App Store icon here:

`app_icon_1024.png`

Requirements:
- 1024×1024 PNG
- No transparency (Apple rejects alpha on the 1024 marketing icon)
- Square; the sugar-skull “DAY OF THE DEAD” art is fine

Then from the repo root:

```bash
flutter pub get
dart run flutter_launcher_icons
```

That fills iOS `AppIcon.appiconset` and Android mipmaps.
