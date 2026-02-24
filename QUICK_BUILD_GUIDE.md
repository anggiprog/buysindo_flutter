# 🚀 QUICK BUILD GUIDE - Baseline Profile & 16KB Support Fixed

## ⚡ QUICK START (3 Steps)

### Step 1: Clean Everything
```powershell
cd E:\projek_flutter\buysindo\buysindo_app
flutter clean
Remove-Item -Path android\.gradle -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path android\app\build -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path build -Recurse -Force -ErrorAction SilentlyContinue
```

### Step 2: Get Dependencies
```powershell
flutter pub get
```

### Step 3a: Build APK (for testing)
```powershell
flutter build apk --release
```

**OR Step 3b: Build AAB (for Play Store upload)**
```powershell
flutter build appbundle --release
```

---

## 📋 FULL COMMAND REFERENCE

### Complete Clean Build Sequence
```powershell
# Navigate to project
cd E:\projek_flutter\buysindo\buysindo_app

# Step 1: Stop any running processes
Get-Process flutter -ErrorAction SilentlyContinue | Stop-Process -Force

# Step 2: Clean Dart/Flutter
flutter clean

# Step 3: Clean Gradle caches
Remove-Item .\android\.gradle -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item .\android\app\build -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item .\build -Recurse -Force -ErrorAction SilentlyContinue

# Step 4: Get fresh dependencies
flutter pub get

# Step 5a: Build APK
flutter build apk --release --verbose

# Step 5b: Build AAB (alternative)
flutter build appbundle --release --verbose

# Step 6: Verify outputs
dir .\build\app\outputs
```

---

## 🎯 EXPECTED OUTPUT LOCATIONS

### APK Build
```
E:\projek_flutter\buysindo\buysindo_app\
└── build\app\outputs\flutter-apk\
    └── app-release.apk
```

### AAB Build (Play Store)
```
E:\projek_flutter\buysindo\buysindo_app\
└── build\app\outputs\bundle\release\
    └── app-release.aab
```

---

## ⏱️ ESTIMATED BUILD TIMES

| Activity | Duration |
|----------|----------|
| Clean | 1-2 min |
| `flutter pub get` | 2-5 min |
| APK Build | 15-20 min |
| AAB Build | 18-25 min |
| **Total (Clean)** | **40-50 min** |
| **Incremental Build** | **10-15 min** |

---

## ✅ SUCCESS INDICATORS

Build sukses jika Anda melihat:

1. **Build Output Says:**
   ```
   ✓ Built build/app/outputs/flutter-apk/app-release.apk (53.2MB).
   ```
   OR
   ```
   ✓ Built build/app/outputs/bundle/release/app-release.aab (44.3MB).
   ```

2. **Build Log Contains:**
   ```
   [BUILD INFO] ART Profile generation started: compileReleaseArtProfile
   [BUILD OPTIMIZATION] Configuring dex task: compileReleaseDexDesugarLibRelease
   ```

3. **NO Errors Like:**
   ```
   ✗ baseline-prof.txt (The system cannot find the file specified)
   ✗ Out of memory errors
   ✗ Task ':app:compileReleaseArtProfile' FAILED
   ```

---

## 🔧 TROUBLESHOOTING

### If Build Still Fails with "baseline-prof.txt not found"
```powershell
# 1. Verify gradle.properties changes
cat .\android\gradle.properties | findstr "enableBaselineProfiles"
# Should output: android.enableBaselineProfiles=true

# 2. Verify build.gradle.kts changes
cat .\android\app\build.gradle.kts | findstr "isBaselineProfileEnabled"
# Should output: isBaselineProfileEnabled = true

# 3. Verify NDK configuration
cat .\android\app\build.gradle.kts | findstr "abiFilters.addAll"
# Should show BOTH: "arm64-v8a" dan "armeabi-v7a"

# 4. Try incremental clean
flutter clean --gradle
```

### If Out of Memory Errors
```powershell
# Run with explicit memory settings
flutter build apk --release --verbose -- -Porg.gradle.jvmargs="-Xmx4096m"
```

### If Tasks Hang/Timeout
```powershell
# Check that android\gradle.properties has:
# org.gradle.parallel=false
# org.gradle.configureondemand=false

# These prevent concurrent memory exhaustion
```

---

## 📱 NEXT STEPS AFTER BUILD

### Upload APK to Play Store Console
1. Go to Google Play Console
2. Select your app (Agicell/Buysindo App)
3. Left sidebar → **Release** → **Production**
4. Click **Create new release**
5. Upload APK or AAB file
6. Add release notes
7. Review and publish

### Upload AAB (Recommended)
1. Play Console → **Release** → **Production**
2. Upload app-release.aab
3. Google Play akan auto-generate APK variants per device
4. Ensure 16KB support declaration visible in console

---

## 🎓 WHAT WAS FIXED

| Issue | Solution |
|-------|----------|
| Baseline profile "file not found" | Re-enabled armeabi-v7a ABI (needs both for generation) |
| Out of memory during build | Disabled parallel Gradle tasks |
| Missing task dependencies | Added explicit depends-on untuk compileReleaseArtProfile |
| Missing baseline profile config | Enabled `isBaselineProfileEnabled = true` |

---

## 📞 If Issues Persist

Check these files for the fixes:
1. [BUILD_FIX_BASELINE_PROFILE_16KB.md](BUILD_FIX_BASELINE_PROFILE_16KB.md) - Detailed explanations
2. [android/app/build.gradle.kts](android/app/build.gradle.kts) - App-level gradle
3. [android/gradle.properties](android/gradle.properties) - Build properties
4. [README_16KB_FIX.md](README_16KB_FIX.md) - 16KB support details

---

**Last Updated:** February 24, 2026  
**Status:** ✅ Ready for build
