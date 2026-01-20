# 🔐 Environment Configuration - Register Screen

## Development (.env.development)

```env
# Firebase Configuration
FIREBASE_PROJECT_ID=your-firebase-project
FIREBASE_API_KEY=your-firebase-api-key

# Admin Configuration
ADMIN_ID=1050
ADMIN_TOKEN=dev-admin-token-12345
APP_TYPE=app

# API Configuration
API_BASE_URL=https://buysindo.com/
API_TIMEOUT=10000

# Features
ENABLE_REFERRAL=true
ENABLE_VERIFICATION_EMAIL=true
REQUIRE_PHONE_NUMBER=false
```

## Production (.env.production)

```env
# Firebase Configuration
FIREBASE_PROJECT_ID=prod-firebase-project
FIREBASE_API_KEY=prod-firebase-api-key

# Admin Configuration
ADMIN_ID=1050
ADMIN_TOKEN=prod-admin-token-secure
APP_TYPE=app

# API Configuration
API_BASE_URL=https://buysindo.com/
API_TIMEOUT=15000

# Features
ENABLE_REFERRAL=true
ENABLE_VERIFICATION_EMAIL=true
REQUIRE_PHONE_NUMBER=false
```

## Staging (.env.staging)

```env
# Firebase Configuration
FIREBASE_PROJECT_ID=staging-firebase-project
FIREBASE_API_KEY=staging-firebase-api-key

# Admin Configuration
ADMIN_ID=1050
ADMIN_TOKEN=staging-admin-token
APP_TYPE=app

# API Configuration
API_BASE_URL=https://staging.buysindo.com/
API_TIMEOUT=10000

# Features
ENABLE_REFERRAL=true
ENABLE_VERIFICATION_EMAIL=true
REQUIRE_PHONE_NUMBER=false
```

---

## 📖 How to Use

### 1. Install flutter_dotenv
```bash
flutter pub add flutter_dotenv
```

### 2. Add pubspec.yaml
```yaml
flutter_dotenv:
  - .env.development
  - .env.staging
  - .env.production
```

### 3. Initialize in main.dart
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment based on flavor
  String env = const String.fromEnvironment('FLAVOR', defaultValue: 'development');
  await dotenv.load(fileName: '.env.$env');
  
  runApp(const MyApp());
}
```

### 4. Use in app_config.dart
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig with ChangeNotifier {
  static const String adminToken = String.fromEnvironment(
    'ADMIN_TOKEN',
    defaultValue: '',
  );

  // Atau dari dotenv:
  static String get adminToken => dotenv.env['ADMIN_TOKEN'] ?? '';
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'https://buysindo.com/';
}
```

### 5. Run with Flavor
```bash
# Development
flutter run --dart-define=FLAVOR=development

# Staging
flutter run --dart-define=FLAVOR=staging

# Production
flutter run --dart-define=FLAVOR=production
```

---

## 🚀 Build with Flavor

### Android
```bash
flutter build apk \
  --dart-define=FLAVOR=production \
  -t lib/main_production.dart
```

### iOS
```bash
flutter build ios \
  --dart-define=FLAVOR=production
```

---

## ⚠️ Security Notes

- Never commit `.env` files to git
- Add to `.gitignore`:
  ```
  .env
  .env.*
  ```

- Use secure secrets management:
  - GitHub Secrets
  - Firebase Remote Config
  - AWS Secrets Manager
  - HashiCorp Vault

---

## 📱 Build Variants

### Development
- Debug mode enabled
- Verbose logging
- Test credentials
- Development API

### Staging
- Debug mode enabled (for QA testing)
- Full logging
- Staging API
- Can use production credentials

### Production
- Release mode
- Minimal logging
- Production API
- Real admin token

---

**Keep sensitive data secure!** 🔒
