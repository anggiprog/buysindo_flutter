# 🚀 Buysindo Web Deployment - Quick Start

## ⚡ Instant Deploy (Fast Track)

### Option 1: Batch Script (Recommended for Windows)
```bash
cd E:\projek_flutter\buysindo\buysindo_app
rebuild_web.bat
```
✅ Automatic: Clean → Build → Deploy → Verify

### Option 2: Manual Commands
```bash
cd E:\projek_flutter\buysindo\buysindo_app
flutter clean
flutter pub get
flutter build web --release --no-tree-shake-icons
xcopy "build\web" "C:\xampp\htdocs\buysindo\public\app" /E /I /Y
```

### Option 3: PowerShell Script (Advanced)
```powershell
cd E:\projek_flutter\buysindo\buysindo_app
.\rebuild_web.ps1
```

---

## ✅ Verify Deployment

```bash
# Check files exist
dir C:\xampp\htdocs\buysindo\public\app

# Open browser
http://localhost/buysindo/public/app
```

---

## 📂 Important Directories

| Path | Purpose |
|------|---------|
| `E:\projek_flutter\buysindo\buysindo_app` | Flutter project source |
| `E:\projek_flutter\buysindo\buysindo_app\build\web` | Build output |
| `C:\xampp\htdocs\buysindo\public\app` | **Web deployment location** |

---

## 🔄 Update Cycle

1. **Edit Code** → `E:\projek_flutter\buysindo\buysindo_app\lib\...`
2. **Run Test** → `flutter run -d web` (optional, for testing)
3. **Build Web** → `flutter build web --release --no-tree-shake-icons`
4. **Deploy** → Copy `build\web` → `C:\xampp\htdocs\buysindo\public\app`
5. **Test** → Open http://localhost/buysindo/public/app
6. **Verify** → Check console (F12) for errors

---

## 🐛 Common Issues

| Issue | Solution |
|-------|----------|
| Build fails | `flutter clean && flutter pub get` |
| Copy permission denied | Run Command Prompt as Administrator |
| Logo not loading | Check `appConfig.logoUrl` from backend |
| Blank white page | Clear cache (Ctrl+Shift+Delete) & refresh (Ctrl+F5) |
| Slow build first time | Normal! (~4-5 min). Later builds faster. |

---

## 📋 Checklist Before Deploy

- [ ] Code changes tested
- [ ] No console errors (`flutter analyze`)
- [ ] `flutter pub get` completed
- [ ] XAMPP ready (Apache running)
- [ ] Backup old app folder (optional)
- [ ] Build successful (no errors)
- [ ] Deploy successful (files copied)
- [ ] URL accessible in browser
- [ ] Logo loads from backend
- [ ] All features working

---

## 📞 Files in This Package

- **rebuild_web.bat** - One-click deploy script (Windows)
- **rebuild_web.ps1** - Advanced PowerShell script (if available)
- **WEB_BUILD_UPDATE_GUIDE.md** - Complete documentation

---

## 🎯 Next Deploy: Just Run!

```bash
# That's it! Everything is automated
rebuild_web.bat
```

---

**Last Updated**: 7 Maret 2026
