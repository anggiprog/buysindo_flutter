# 📱 Flutter Web - Panduan Development & Deploy

## 🔧 Metode 1: Development (Testing Lokal)

Untuk testing Flutter Web langsung tanpa deploy ke Laravel:

```powershell
cd E:\projek_flutter\buysindo\buysindo_app
flutter run -d chrome
```

**Catatan:**
- Akses langsung di `http://localhost:xxxxx`
- Hot reload aktif (tekan `r` untuk reload)
- Cocok untuk development & debugging
- API harus pointing ke backend yang benar

---

## 🚀 Metode 2: Deploy ke Laravel (Production)

### Step 1: Build & Copy ke Laravel
```powershell
cd E:\projek_flutter\buysindo\buysindo_app
.\deploy-web.ps1
```

### Step 2: Push ke VPS
```powershell
cd C:\xampp\htdocs\buysindo
git add .
git commit -m "Update Flutter Web"
git push origin main
```

**Catatan:**
- Flutter Web ter-build ke `public/app/`
- Akses via `http://{subdomain}.bukatoko.local/`
- VPS otomatis update setelah git push

---

## 📁 Struktur File

```
Laravel (C:\xampp\htdocs\buysindo)
├── public/
│   ├── mobile.html      ← Wrapper iframe (450px frame)
│   └── app/             ← Flutter Web build
│       ├── index.html
│       ├── main.dart.js
│       └── ...

Flutter (E:\projek_flutter\buysindo\buysindo_app)
├── deploy-web.ps1       ← Script deploy
├── build/web/           ← Output build
└── lib/                 ← Source code
```

---

## ⚡ Quick Reference

| Tujuan | Command |
|--------|---------|
| Dev/Testing | `flutter run -d chrome` |
| Deploy Lokal | `.\deploy-web.ps1` |
| Push ke VPS | `git add . && git commit -m "msg" && git push` |

---

## 🔗 URL Akses

- **Development:** `http://localhost:xxxxx` (port random)
- **Lokal Laravel:** `http://{subdomain}.bukatoko.local/`
- **Production VPS:** `http://{subdomain}.bukatoko.com/`
