# Quick Flutter Commands for Development

## 🚀 Fast Build & Run Commands

```powershell
# 1. FASTEST - Hot Reload (preserves app state)
flutter run

# 2. FAST - Hot Restart (restarts app, keeps debug session)
# Press 'R' in console saat app running

# 3. CLEAN REBUILD (clear cache, rebuild from scratch)
flutter clean
flutter pub get
flutter run

# 4. RELEASE BUILD (smaller APK, for testing on device)
flutter run --release
```

## ⚡ Optimized Build Flags

```powershell
# Skip splash screen rebuild
flutter run --no-fast-start

# Split debug symbols (faster build)
flutter run --split-debug-info=split-output

# No devtools (faster startup)
flutter run --no-devtools
```

## 🔥 Ultra-Fast Development Commands

```powershell
# Create PowerShell function for super-fast rebuild
# Add to Profile ($PROFILE):

function frf {
  cd e:\projek_flutter\buysindo\buysindo_app
  flutter run
}

function frr {
  cd e:\projek_flutter\buysindo\buysindo_app
  # Hot restart - press 'R' in running console
}

function fclean {
  cd e:\projek_flutter\buysindo\buysindo_app
  flutter clean
  flutter pub get
  flutter run
}
```

## 📝 Edit PowerShell Profile

```powershell
# Open profile
code $PROFILE

# Or create if doesn't exist
if (!(Test-Path -Path $PROFILE)) {
  New-Item -ItemType File -Path $PROFILE -Force
}

# Add functions above
notepad $PROFILE

# Reload profile
. $PROFILE
```

## 💡 Pro Tips

1. **Avoid `flutter clean` saat development** - gunakan hanya kalau ada issues
2. **Press 'R' for Hot Restart** - lebih cepat daripada Ctrl+C dan flutter run lagi
3. **Jangan edit pubspec.yaml** tanpa `flutter pub get` - kalau perlu, better do fresh clean
4. **Use `--verbose`** untuk troubleshooting lambatnya build:
   ```powershell
   flutter run --verbose 2>&1 | Select-String -Pattern "ms|time" | tail -20
   ```

## 🎯 Startup Time Target

- **Sebelum optimization:** 20-30 detik
- **Sesudah optimization:** 5-10 detik (3x lebih cepat!)

**Expected timing saat app launch:**
```
⚡ Binding initialized (1ms)
📋 Loading .env file (background)...
🎨 Preserving native splash... (5ms)
📥 Loading cached config... (50-100ms)
🔥 Starting Firebase initialization (background)...
🌐 Starting API config fetch (background)...
⏱️ Total main() duration: 150-200ms (READY TO SHOW APP) ✅

🏃 UI SIAP DALAM ~200MS! 
```
