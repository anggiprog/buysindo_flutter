# Flutter Buysindo App - Comprehensive Codebase Analysis

## 1. GameTopupScreen.dart Overview

**Location:** `lib/ui/home/customer/tabs/templates/GameTopupScreen.dart`

### Architecture & Structure

#### Widget Hierarchy
```
GameTopupScreen (StatefulWidget)
├── _GameTopupScreenState (State)
│   ├── ApiService (dependency for API calls)
│   ├── SharedPreferences (for caching)
│   └── CustomScrollView (main UI)
│       ├── _buildBannerArea()
│       ├── _buildBalanceCard()
│       ├── _buildGameCategoriesSection()
│       └── _buildGameProductsSection()
```

#### Key State Variables

```dart
// Products & Categories
List<ProductPrabayar> _allProducts = [];           // All games products
List<String> _availableBrands = [];               // Game brands (e.g., PUBG, FF)
Map<String, String> _brandIconUrls = {};          // Brand icons
String _selectedBrand = "";                       // Currently selected brand

// Banner Management
List<String> _bannerList = [];                    // Banner URLs
int _bannerIndex = 0;                             // Current banner index
Timer? _bannerTimer;                              // Auto-rotate banner

// User Financial Data
String _saldo = "0";                              // User balance in Rupiah
int _totalPoin = 0;                               // Loyalty points

// Loading States
bool _isLoadingBanners = true;
bool _isLoadingSaldo = true;
bool _isLoadingPoin = true;
bool _isLoadingProducts = false;
bool _isRefreshing = false;

// Fallback Promotional Banners (when no API banners available)
List<Map<String, String>> _promotionalBanners = [
  {'title': 'DISKON 25%', 'subtitle': 'Untuk Pembelian Pertama', 'gradient': 'blue'},
  {'title': 'CASHBACK 15%', 'subtitle': 'Setiap Transaksi Games', 'gradient': 'purple'},
  {'title': 'BONUS POINT', 'subtitle': 'Kumpulkan dan Tukarkan', 'gradient': 'green'},
];
```

### Initialization Flow

```dart
@override
void initState() {
  super.initState();
  _apiService = ApiService(Dio());
  _initializeApp();
}

Future<void> _initializeApp() async {
  _prefs = await SharedPreferences.getInstance();  // 1. Initialize SharedPrefs
  _loadFromCache();                                 // 2. Load cached data first
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _fetchAllData();                                // 3. Fetch fresh data from API
    _startBannerAutoPlay();                         // 4. Start banner rotation
  });
}
```

### Key Data Loading Methods

#### 1. Cache Loading Strategy
```dart
void _loadFromCache() {
  // Banners
  final cachedBanners = _prefs.getStringList('cached_banners');
  if (cachedBanners != null && cachedBanners.isNotEmpty) {
    _bannerList = cachedBanners;
    _isLoadingBanners = false;  // ✅ Mark as loaded immediately
  }

  // Balance
  final cachedSaldo = _prefs.getString('cached_saldo');
  if (cachedSaldo != null) {
    _saldo = cachedSaldo;
    _isLoadingSaldo = false;
  }

  // Points
  final cachedPoin = _prefs.getInt('cached_poin');
  if (cachedPoin != null) {
    _totalPoin = cachedPoin;
    _isLoadingPoin = false;
  }
}
```

#### 2. API Fetching Methods

**A. Fetch Banners**
```dart
Future<void> _fetchBanners() async {
  try {
    final String adminId = appConfig.adminId;  // From AppConfig singleton
    final response = await _apiService.getBanners(adminId);

    if (response.statusCode == 200 && response.data != null) {
      List<String> banners = [];
      
      if (data['data'] is List) {
        banners = List<String>.from(
          (data['data'] as List).map((item) => item['image']?.toString() ?? ''),
        ).where((img) => img.isNotEmpty).toList();
      }

      await _prefs.setStringList('cached_banners', banners);  // Cache it

      setState(() {
        _bannerList = banners;
        _isLoadingBanners = false;
      });
    }
  } catch (e) {
    debugPrint('Error fetching banners: $e');
    if (mounted) setState(() => _isLoadingBanners = false);
  }
}
```

**B. Fetch Saldo (Balance)**
```dart
Future<void> _fetchSaldo() async {
  try {
    final String? token = await SessionManager.getToken();  // Get JWT token
    if (token == null) return;

    final response = await _apiService.getSaldo(token);

    if (response.statusCode == 200 && response.data != null) {
      final saldoValue = response.data['data']?['saldo']?.toString() ?? '0';
      await _prefs.setString('cached_saldo', saldoValue);

      setState(() {
        _saldo = saldoValue;
        _isLoadingSaldo = false;
      });
    }
  } catch (e) {
    debugPrint('Error fetching saldo: $e');
    if (mounted) setState(() => _isLoadingSaldo = false);
  }
}
```

**C. Fetch Poin (Points)**
```dart
Future<void> _fetchPoin() async {
  try {
    final String? token = await SessionManager.getToken();
    if (token == null) return;

    final response = await _apiService.getPoinSummary(token);
    int poin = 0;

    if (response.statusCode == 200 && response.data != null) {
      poin = response.data['data']?['poin'] ?? 0;
    }

    await _prefs.setInt('cached_poin', poin);

    setState(() {
      _totalPoin = poin;
      _isLoadingPoin = false;
    });
  } catch (e) {
    if (mounted) setState(() => _isLoadingPoin = false);
  }
}
```

**D. Load Games Products**
```dart
Future<void> _loadGamesData() async {
  if (!mounted) return;
  setState(() => _isLoadingProducts = true);

  try {
    final String? token = await SessionManager.getToken();
    if (token == null) return;

    // Fetch products with forceRefresh=true to get latest
    final products = await _apiService.getProducts(token, forceRefresh: true);

    if (mounted) {
      setState(() {
        // Filter only GAMES category products
        _allProducts = products
            .where((p) => p.category.toUpperCase().contains("GAMES"))
            .toList();

        // Extract unique brands and their icons
        final brandSet = <String>{};
        _brandIconUrls.clear();

        for (var product in _allProducts) {
          if (!brandSet.contains(product.brand)) {
            brandSet.add(product.brand);
            if (product.iconUrl != null && product.iconUrl!.isNotEmpty) {
              _brandIconUrls[product.brand] = product.iconUrl!;
            }
          }
        }

        _availableBrands = brandSet.toList()..sort();
        if (_availableBrands.isNotEmpty) {
          _selectedBrand = _availableBrands.first;
        }
        _isLoadingProducts = false;
      });
    }
  } catch (e) {
    if (mounted) setState(() => _isLoadingProducts = false);
    debugPrint('Error loading games: $e');
  }
}
```

### UI Building Methods

#### 1. Banner Area
```dart
Widget _buildBannerArea() {
  return SliverToBoxAdapter(
    child: Container(
      height: 160,
      // Uses BannerSliderWidget component or falls back to promotional banners
      child: _bannerList.isNotEmpty
          ? BannerSliderWidget(
              banners: _bannerList,
              baseUrl: _apiService.imageBaseUrl,
            )
          : _buildPromotionalBannerFallback(),
    ),
  );
}
```

#### 2. Balance Card
```dart
Widget _buildBalanceCard() {
  return SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        // Displays:
        // - Saldo (balance)
        // - Quick actions: "Isi Saldo" (Top up), "Histori" (History)
        // - Poin (Points) display
      ),
    ),
  );
}
```

#### 3. Game Categories (Horizontal Scroll)
```dart
Widget _buildGameCategoriesSection() {
  // Horizontal ListView of game brands
  // Each brand card shows:
  // - Brand icon from _brandIconUrls[brand]
  // - Brand name (e.g., "PUBG", "Free Fire")
  // - Selection indicator (blue border when selected)
  
  return ListView.builder(
    scrollDirection: Axis.horizontal,
    itemCount: _availableBrands.length,
    itemBuilder: (context, index) {
      final brand = _availableBrands[index];
      final isSelected = _selectedBrand == brand;
      // Tap to update _selectedBrand state
    },
  );
}
```

#### 4. Game Products Grid (2 columns)
```dart
Widget _buildGameProductsSection() {
  // Filters products by selected brand
  final filteredProducts = _allProducts
      .where((p) => p.brand == _selectedBrand)
      .toList();

  return SliverGrid(
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 0.75,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
    ),
    // Displays product cards with:
    // - Product icon/image
    // - Product name
    // - Price
  );
}
```

### Key Features

1. **Banner Auto-Rotation**
   ```dart
   void _startBannerAutoPlay() {
     _bannerTimer = Timer.periodic(Duration(seconds: 4), (timer) {
       if (mounted && _bannerList.isNotEmpty) {
         setState(() {
           _bannerIndex = (_bannerIndex + 1) % _bannerList.length;
         });
       }
     });
   }
   ```

2. **Pull-to-Refresh**
   ```dart
   RefreshIndicator(
     onRefresh: _handleRefresh,
     child: CustomScrollView(...)
   )
   ```

3. **Product Filtering**
   - Tapping a brand updates `_selectedBrand`
   - Products are re-filtered by brand
   - Grid rebuilds with matching products

---

## 2. ppob_template.dart - PPOB Menu & Topup Template

**Location:** `lib/ui/home/customer/tabs/templates/ppob_template.dart`

### Architecture & Purpose

The `ppob_template` is the **main home screen template** for PPOB (Pembayaran Pasca Bayar / Telecom Services) and displays:
- **Prabayar** (Prepaid) services: Pulsa, Data, Games, etc.
- **Pascabayar** (Postpaid) services: PLN, PDAM, BPJS, etc.
- **User Financial Data**: Balance, Points, Transaction History
- **Promotional Banners**

### Key State Variables

```dart
class _PpobTemplateState extends State<PpobTemplate> {
  final storage = const FlutterSecureStorage();
  late SharedPreferences _prefs;
  final ApiService apiService = ApiService(Dio());
  late PopupManager _popupManager;

  // Banners
  List<String> _bannerList = [];
  bool _isLoadingBanners = true;

  // User Financial Data
  String _saldo = "0";
  bool _isLoadingSaldo = true;
  int _totalPoin = 0;
  bool _isLoadingPoin = true;

  // Menu Systems
  List<MenuPrabayarItem> _menuList = [];           // Prepaid menus
  bool _isLoadingMenu = true;
  bool _showAllMenus = false;                      // Show all or top 8

  List<MenuPascabayarItem> _pascabayarList = [];   // Postpaid menus
  bool _isLoadingPascabayar = true;

  bool _isRefreshing = false;
}
```

### Initialization & Data Loading

```dart
@override
void initState() {
  super.initState();
  _popupManager = PopupManager(apiService: apiService);
  _initializeApp();
}

Future<void> _initializeApp() async {
  _prefs = await SharedPreferences.getInstance();
  _loadFromCache();                                // Step 1: Fast load from cache
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _fetchAllData();                               // Step 2: Fetch fresh data
    _checkAndShowPopup();                          // Step 3: Show popup if due
  });
}
```

### Cache Loading Pattern

```dart
void _loadFromCache() {
  if (mounted) {
    setState(() {
      // Load banners
      final cachedBanners = _prefs.getStringList('cached_banners');
      if (cachedBanners != null && cachedBanners.isNotEmpty) {
        _bannerList = cachedBanners;
        _isLoadingBanners = false;
      }

      // Load prepaid menu
      final cachedMenu = _prefs.getString('cached_menu_prabayar');
      if (cachedMenu != null) {
        try {
          final List<dynamic> data = jsonDecode(cachedMenu);
          _menuList = data.map((item) => MenuPrabayarItem.fromJson(item)).toList();
          _isLoadingMenu = false;
        } catch (e) {
          // Handle parsing error silently
        }
      }

      // Load postpaid menu
      final cachedPascabayar = _prefs.getString('cached_menu_pascabayar');
      if (cachedPascabayar != null) {
        try {
          final List<dynamic> data = jsonDecode(cachedPascabayar);
          _pascabayarList = data.map((item) => MenuPascabayarItem.fromJson(item)).toList();
          _isLoadingPascabayar = false;
        } catch (e) {
          // Silent error handling
        }
      }

      // Load saldo and poin...
    });
  }
}
```

### Parallel Data Fetching

```dart
Future<void> _fetchAllData() async {
  // Fetch all data in parallel for better performance
  await Future.wait([
    _fetchBanners(),
    _fetchSaldo(),
    _fetchPoin(),
    _fetchMenuPrabayar(),
    _fetchPascabayar(),
  ]);
}
```

### Individual Fetch Methods

#### 1. Fetch Banners
```dart
Future<void> _fetchBanners() async {
  try {
    final String adminId = appConfig.adminId;
    final response = await apiService.getBanners(adminId);

    if (response.statusCode == 200 && response.data != null) {
      // Uses BannerResponse model
      final data = BannerResponse.fromJson(response.data);
      await _prefs.setStringList('cached_banners', data.banners);

      setState(() {
        _bannerList = data.banners;
        _isLoadingBanners = false;
      });
    }
  } catch (e) {
    if (mounted) setState(() => _isLoadingBanners = false);
  }
}
```

#### 2. Fetch Prepaid Menu
```dart
Future<void> _fetchMenuPrabayar() async {
  try {
    String? token = await SessionManager.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) setState(() => _isLoadingMenu = false);
      return;
    }

    final response = await apiService.getMenuPrabayar(token);

    if (response.statusCode == 200 && response.data != null) {
      final data = MenuPrabayarResponse.fromJson(response.data);

      // Cache as JSON string
      final menusJson = jsonEncode(
        data.menus.map((m) => m.toJson()).toList(),
      );
      await _prefs.setString('cached_menu_prabayar', menusJson);

      setState(() {
        _menuList = data.menus;
        _isLoadingMenu = false;
      });
    }
  } catch (e) {
    if (mounted) setState(() => _isLoadingMenu = false);
  }
}
```

#### 3. Fetch Postpaid Menu
```dart
Future<void> _fetchPascabayar() async {
  try {
    String? token = await SessionManager.getToken();
    if (token == null) {
      setState(() => _isLoadingPascabayar = false);
      return;
    }

    final response = await apiService.getMenuPascabayar(token);

    if (response.statusCode == 200) {
      final List data = response.data;
      final pascabayarList = data
          .map((item) => MenuPascabayarItem.fromJson(item))
          .toList();

      // Cache as JSON
      final pascabayarJson = jsonEncode(
        pascabayarList.map((p) => p.toJson()).toList(),
      );
      await _prefs.setString('cached_menu_pascabayar', pascabayarJson);

      setState(() {
        _pascabayarList = pascabayarList;
        _isLoadingPascabayar = false;
      });
    }
  } catch (e) {
    if (mounted) setState(() => _isLoadingPascabayar = false);
  }
}
```

### UI Building - Topup Cards (Prabayar Menu)

#### Menu Grid Display
```dart
Widget _buildMenuGridContent() {
  return Padding(
    padding: const EdgeInsets.only(left: 15, right: 15, top: 0),
    child: RepaintBoundary(
      child: Column(
        children: [
          if (_isLoadingMenu)
            _buildMenuShimmer()
          else if (_menuList.isEmpty)
            const SizedBox(
              height: 100,
              child: Center(child: Text("Tidak ada menu tersedia")),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,           // 4 columns
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: 105,        // Height per item
              ),
              itemCount: _showAllMenus
                  ? _menuList.length
                  : (_menuList.length > 8 ? 8 : _menuList.length),  // Show 8 or all if less
              itemBuilder: (context, index) {
                if (!_showAllMenus && _menuList.length > 8 && index == 7) {
                  return _buildMoreMenuIcon();  // Position 8 shows "More" button
                }
                return _buildDynamicMenuIcon(_menuList[index]);
              },
            ),
          // Show/Hide button
          if (_showAllMenus && _menuList.length > 8)
            TextButton.icon(
              onPressed: () => setState(() => _showAllMenus = false),
              icon: const Icon(Icons.expand_less),
              label: const Text("Sembunyikan"),
            ),
        ],
      ),
    ),
  );
}
```

#### Individual Menu Card (Topup Card)
```dart
Widget _buildDynamicMenuIcon(MenuPrabayarItem menu) {
  // Use gambar_url from API if available, fallback to manual URL building
  final imageUrl =
      menu.gambarUrl ??
      '${apiService.imageBannerBaseUrl}${menu.gambarKategori}';

  return InkWell(
    onTap: () {
      // Navigation routing based on menu name
      if (menu.namaKategori == "Pulsa") {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PulsaPage()));
      } else if (menu.namaKategori == "Data") {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const DataPage()));
      } else if (menu.namaKategori == "Games") {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const GamesPage()));
      }
      // ... more navigation cases ...
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Card Container
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              cacheHeight: 40,
              cacheWidth: 40,
              errorBuilder: (_, __, ___) => Icon(
                Icons.image_not_supported,
                size: 40,
                color: Colors.grey[400],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Menu Label
        Text(
          menu.namaKategori,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    ),
  );
}
```

#### "More" Menu Button
```dart
Widget _buildMoreMenuIcon() {
  return InkWell(
    onTap: () => setState(() => _showAllMenus = true),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: appConfig.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            Icons.more_horiz,
            color: appConfig.primaryColor,
            size: 40,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Lainnya",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: appConfig.primaryColor,
          ),
        ),
      ],
    ),
  );
}
```

### UI Building - Postpaid Menu (Pascabayar)

Similar structure to prabayar but:
```dart
Widget _buildPascabayarGridContent() {
  return GridView.builder(
    itemCount: _pascabayarList.length,  // Shows ALL items (no "More" button)
    itemBuilder: (context, index) {
      final menu = _pascabayarList[index];
      final imageUrl =
          menu.gambarUrl ??
          '${apiService.imagePascabayarUrl}${menu.gambarBrand}';

      return InkWell(
        onTap: () {
          // Navigate by brand (PLN, PDAM, BPJS, etc.)
          final brand = menu.namaBrand.toLowerCase();
          if (brand.contains('pln')) {
            Navigator.push(context, MaterialPageRoute(...));
          } else if (brand.contains('pdam')) {
            Navigator.push(context, MaterialPageRoute(...));
          }
          // ... more brand cases ...
        },
        // Card UI...
      );
    },
  );
}
```

### Search/Filter Implementation

**Important Note:** The `ppob_template.dart` does **NOT implement search functionality**. Instead:

1. **Prabayar (Prepaid):**
   - Shows top 8 menus by default
   - Has "Lainnya" (More) button to expand and show all
   - No search field

2. **Pascabayar (Postpaid):**
   - Shows all brands (e.g., 4 items)
   - No search field

3. **Navigation Routing:**
   - Each menu card taps to specific category page (PulsaPage, DataPage, GamesPage, etc.)
   - Those individual pages (e.g., GamesPage → GameTopupScreen) handle product filtering

### Balance Card UI

```dart
Widget _buildBalanceCard() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    child: Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Saldo Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Saldo Anda", style: TextStyle(color: Colors.black)),
              _isLoadingSaldo
                  ? Shimmer(...) : Text(FormatUtil.formatRupiah(_saldo))
            ],
          ),
          const Divider(height: 24),
          // Quick Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickAction(Icons.account_balance_wallet, "Isi Saldo", _showTopup),
              _buildQuickAction(Icons.history, "Histori", () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const TopupHistoryScreen(),
                ));
              }),
              _buildQuickAction(
                Icons.stars,
                _isLoadingPoin ? "Poin: ..." : "Poin: $_totalPoin",
                () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const PoinPage(),
                  ));
                },
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
```

### Topup Modal Flow

```dart
void _showTopup() async {
  final result = await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TopupModal(
      primaryColor: appConfig.primaryColor,
      apiService: apiService,
    ),
  );

  // Handle navigation based on result
  if (result is Map && result['action'] != null && mounted) {
    if (result['action'] == 'navigate_manual') {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => TopupManual(
          amount: result['amount'],
          primaryColor: appConfig.primaryColor,
          apiService: apiService,
        ),
      ));
    } else if (result['action'] == 'navigate_auto') {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => TopupOtomatis(
          amount: result['amount'],
          primaryColor: appConfig.primaryColor,
          apiService: apiService,
        ),
      ));
    }
  }
}
```

---

## 3. Banner Data Management

### AppConfig.dart - Configuration Management

**Location:** `lib/core/app_config.dart`

### Purpose
- Manages app-wide configuration (colors, app name, logos, templates)
- Loads config from API on app startup
- Persists config to SharedPreferences for offline access

### Configuration Singleton Pattern

```dart
final appConfig = AppConfig();
```

### Key Configuration Properties

```dart
class AppConfig with ChangeNotifier {
  // Stored in SharedPreferences with prefix 'cfg_'
  static const String _keyAppName = 'cfg_app_name';
  static const String _keyPrimaryColor = 'cfg_primary_color';
  static const String _keyTextColor = 'cfg_text_color';
  static const String _keyTemplate = 'cfg_template';
  static const String _keyTampilan = 'cfg_tampilan';
  static const String _keyLogoUrl = 'cfg_logo_url';
  static const String _keySubdomain = 'cfg_subdomain';

  // Environment-based configuration (from build-time --dart-define)
  static const String _adminId = String.fromEnvironment(
    'ADMIN_ID',
    defaultValue: '1050',
  );
  static const String _initialAppType = String.fromEnvironment(
    'APP_TYPE',
    defaultValue: 'app',
  );

  // Getters
  String get adminId => _adminId;        // Used for banner fetching
  String get appName => _appName;
  String get appType => _appType;
  String get tampilan => _tampilan;
  Color get primaryColor => _primaryColor;
  String? get logoUrl => _logoUrl;
  String get subdomain => _subdomain;
}
```

### Banner-Related Initialization

#### 1. Load Local Config (on app startup)
```dart
Future<void> loadLocalConfig() async {
  final prefs = await SharedPreferences.getInstance();

  // Restore previously saved config
  _appName = prefs.getString(_keyAppName) ?? _appName;
  _tampilan = prefs.getString(_keyTampilan) ?? _tampilan;
  _logoUrl = prefs.getString(_keyLogoUrl);
  _subdomain = prefs.getString(_keySubdomain) ?? "";

  final hexPrimary = prefs.getString(_keyPrimaryColor);
  if (hexPrimary != null) _primaryColor = _parseColor(hexPrimary);

  notifyListeners();
}
```

#### 2. Fetch Config from API
```dart
Future<void> initializeApp(ApiService apiService) async {
  try {
    debugPrint('🔵 AppConfig.initializeApp START');
    
    // Call API with timeout
    final response = await apiService
        .getPublicConfig(_adminId, _appType)
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException('API call timeout setelah 15 detik');
          },
        );

    if (response.statusCode == 200 && response.data['data'] != null) {
      debugPrint('✅ API response valid, parsing data...');
      final model = AppConfigModel.fromApi(response.data['data']);

      // Update state
      updateFromModel(model);

      // Save to SharedPreferences for future offline use
      await _saveToLocal(model);
      debugPrint('✅ AppConfig.initializeApp COMPLETE');
    }
  } on TimeoutException catch (e) {
    debugPrint('⏱️ AppConfig Initialize Timeout: $e');
  } catch (e) {
    debugPrint('❌ AppConfig Initialize Error: $e');
  }
}
```

#### 3. Update Configuration from Model
```dart
void updateFromModel(AppConfigModel model) {
  try {
    _appName = model.appName;
    _primaryColor = _parseColor(model.primaryColor);
    _textColor = _parseColor(model.textColor);
    _logoUrl = model.logoUrl;
    _subdomain = model.subdomain;
    _appType = model.appType.toLowerCase();
    _tampilan = model.tampilan.trim();
    _status = model.status;

    _showAppbar = model.showAppbar;
    _showNavbar = model.showNavbar;

    debugPrint('✅ AppConfig Updated:');
    debugPrint('  - App Name: $_appName');
    debugPrint('  - Tampilan: $_tampilan');
    debugPrint('  - Template: ${model.template}');

    notifyListeners();
  } catch (e) {
    debugPrint('Update Model Failed: $e');
  }
}
```

#### 4. Save Config to SharedPreferences
```dart
Future<void> _saveToLocal(AppConfigModel model) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_keyAppName, model.appName);
  await prefs.setString(_keyPrimaryColor, model.primaryColor);
  await prefs.setString(_keyTextColor, model.textColor);
  await prefs.setString(_keyTemplate, model.template);
  await prefs.setString(_keyTampilan, model.tampilan);
  await prefs.setString(_keySubdomain, model.subdomain);
  if (model.logoUrl != null) {
    await prefs.setString(_keyLogoUrl, model.logoUrl!);
  }
}
```

### Color Parsing Strategy
```dart
static Color _parseColor(String hex) {
  try {
    if (hex.isEmpty) {
      return const Color(0xFF0D6EFD);  // Default blue
    }

    final cleanHex = hex.replaceAll('#', '').padLeft(8, 'FF');
    String formatHex = cleanHex.length > 8
        ? cleanHex.substring(cleanHex.length - 8)
        : cleanHex;

    final parsedColor = Color(int.parse(formatHex, radix: 16));

    // Validate color is not transparent or black
    if (parsedColor.value == 0 || parsedColor.alpha == 0) {
      return const Color(0xFF0D6EFD);
    }

    return parsedColor;
  } catch (e) {
    debugPrint('⚠️ Failed to parse color "$hex": $e, using default blue');
    return const Color(0xFF0D6EFD);
  }
}
```

### Banner Models

#### BannerResponse Model
```dart
class BannerResponse {
  final String status;
  final List<String> banners;  // List of image URLs

  BannerResponse({required this.status, required this.banners});

  factory BannerResponse.fromJson(Map<String, dynamic> json) {
    return BannerResponse(
      status: json['status'] ?? '',
      banners: List<String>.from(json['banners'] ?? []),
    );
  }
}
```

#### MenuPrabayarItem Model (with banner_url support)
```dart
class MenuPrabayarItem {
  final int id;
  final int urutan;                    // Order
  final int adminUserId;
  final String namaKategori;           // Category name (e.g., "Pulsa")
  final String gambarKategori;         // Image filename
  final String? gambarUrl;             // 👈 NEW: Full URL from API
  final String? iconTemplate;
  final String createdAt;
  final String updatedAt;

  MenuPrabayarItem({
    required this.id,
    required this.urutan,
    required this.adminUserId,
    required this.namaKategori,
    required this.gambarKategori,
    this.gambarUrl,  // Can be null - falls back to URL building
    this.iconTemplate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MenuPrabayarItem.fromJson(Map<String, dynamic> json) {
    return MenuPrabayarItem(
      id: json['id'] ?? 0,
      urutan: json['urutan'] ?? 0,
      adminUserId: json['admin_user_id'] ?? 0,
      namaKategori: json['nama_kategori'] ?? '',
      gambarKategori: json['gambar_kategori'] ?? '',
      gambarUrl: json['gambar_url'],  // 👈 Read full URL from API
      iconTemplate: json['icon_template'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'urutan': urutan,
    'admin_user_id': adminUserId,
    'nama_kategori': namaKategori,
    'gambar_kategori': gambarKategori,
    'gambar_url': gambarUrl,
    'icon_template': iconTemplate,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}
```

---

## 4. SharedPreferences Usage Patterns

### Overview
SharedPreferences is used throughout the app for:
1. **Caching API responses** (banners, menus, products)
2. **Storing tokens** (JWT authentication)
3. **User preferences** (theme, app config)
4. **Session management** (admin ID, pending OTP)

### Cache Keys Pattern

```dart
// API Service Cache Keys (CamelCase)
Keys:
- 'cached_banners'        // List<String>
- 'cached_saldo'          // String (formatted currency)
- 'cached_poin'           // int
- 'cached_menu_prabayar'  // JSON String (List)
- 'cached_menu_pascabayar'// JSON String (List)

// AppConfig Keys (with prefix)
Keys:
- 'cfg_app_name'          // String
- 'cfg_primary_color'     // String (hex color)
- 'cfg_text_color'        // String (hex color)
- 'cfg_template'          // String
- 'cfg_tampilan'          // String
- 'cfg_logo_url'          // String URL
- 'cfg_subdomain'         // String

// SessionManager Keys
Keys:
- 'access_token'          // String (JWT token)
- 'admin_user_id'         // int
- 'pending_otp_email'     // String

// Splash Screen Cache Keys
Keys:
- '_kSplashFileKey'       // String (file path)
- '_kSplashUrlKey'        // String (banner URL)
- '_kSplashTaglineKey'    // String (tagline text)
- '_kSplashUpdatedAtKey'  // String (timestamp)

// API Service Brand Cache Keys
Keys:
- 'brand_${prefix}'       // String (e.g., 'brand_0815' → "Telkomsel")
```

### Usage Patterns

#### 1. Session/Token Management

**SessionManager.dart**
```dart
// Save token after login
static Future<void> saveToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_tokenKey, token);
}

// Get token for API requests
static Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(_tokenKey);
  return token;
}

// Save admin user ID
static Future<void> saveAdminUserId(int adminUserId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_adminUserIdKey, adminUserId);
}

// Get admin user ID
static Future<int?> getAdminUserId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_adminUserIdKey);
}
```

#### 2. API Response Caching - Banners

```dart
// Save
await _prefs.setStringList('cached_banners', banners);

// Load
final cachedBanners = _prefs.getStringList('cached_banners');
if (cachedBanners != null && cachedBanners.isNotEmpty) {
  _bannerList = cachedBanners;
  _isLoadingBanners = false;  // Mark as loaded from cache
}
```

#### 3. API Response Caching - Menu (JSON)

```dart
// Save as JSON string
final menusJson = jsonEncode(
  data.menus.map((m) => m.toJson()).toList(),
);
await _prefs.setString('cached_menu_prabayar', menusJson);

// Load and parse
final cachedMenu = _prefs.getString('cached_menu_prabayar');
if (cachedMenu != null) {
  try {
    final List<dynamic> data = jsonDecode(cachedMenu);
    _menuList = data
        .map((item) => MenuPrabayarItem.fromJson(item))
        .toList();
    _isLoadingMenu = false;
  } catch (e) {
    // Handle parsing error
  }
}
```

#### 4. Numeric Data Caching

```dart
// Save integer
await _prefs.setInt('cached_poin', poin);

// Load integer
final cachedPoin = _prefs.getInt('cached_poin');
if (cachedPoin != null) {
  _totalPoin = cachedPoin;
}
```

#### 5. Brand Detection Cache

**api_service.dart**
```dart
Future<String?> detectBrand(String phone, String? token) async {
  final prefs = await SharedPreferences.getInstance();
  String prefix = phone.substring(0, 4);
  String cacheKey = "brand_$prefix";

  // Check if brand for this prefix is already cached
  if (prefs.containsKey(cacheKey)) {
    return prefs.getString(cacheKey);  // Return cached brand
  }

  try {
    // Call API to detect brand
    final response = await _dio.get(
      'api/detect-brand',
      queryParameters: {'phone': phone},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode == 200 && response.data['brand'] != null) {
      String detectedBrand = response.data['brand'].toString();

      // Cache the detected brand
      await prefs.setString(cacheKey, detectedBrand);

      return detectedBrand;
    }
  } catch (e) {
    return null;
  }
}
```

#### 6. Splash Screen Cache

**splash_screen.dart**
```dart
// Save banner info
final prefs = await SharedPreferences.getInstance();
await prefs.setString(_kSplashFileKey, filePath);
await prefs.setString(_kSplashUrlKey, url);
await prefs.setString(_kSplashTaglineKey, tagline ?? '');
await prefs.setString(_kSplashUpdatedAtKey, updatedAt ?? '');

// On init, load cached values
final filePath = prefs.getString(_kSplashFileKey);
final url = prefs.getString(_kSplashUrlKey);
final tagline = prefs.getString(_kSplashTaglineKey);
final updatedAt = prefs.getString(_kSplashUpdatedAtKey);
```

### Cache Invalidation Patterns

#### Manual Cache Clear
```dart
Future<void> clearProductCache() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_prefKey);
  _noopLog('🗑️ Cache produk telah dihapus');
}
```

#### Force Refresh Pattern
```dart
// User pulls to refresh
Future<void> _handleRefresh() async {
  if (_isRefreshing) return;
  setState(() => _isRefreshing = true);
  try {
    // forceRefresh=true bypasses cache
    await _fetchAllData();
  } finally {
    if (mounted) setState(() => _isRefreshing = false);
  }
}

// In API method
Future<List<ProductPrabayar>> getProducts(
  String? token, {
  bool forceRefresh = false,  // 👈 Force bypass cache
}) async {
  final prefs = await SharedPreferences.getInstance();
  final String? cachedData = prefs.getString(_prefKey);

  if (forceRefresh) {
    // Skip cache, fetch from API directly
    return await _fetchProductsFromApi(token, prefs);
  }

  if (cachedData != null) {
    return _parseProducts(cachedData);
  }

  return await _fetchProductsFromApi(token, prefs);
}
```

---

## 5. API Calls Architecture

### ApiService - Core Service

**Location:** `lib/core/network/api_service.dart`

### Base Configuration

```dart
class ApiService {
  late Dio _dio;
  
  final String baseUrl = '[Backend URL]';
  final String imageBaseUrl = '$baseUrl/storage/games/';
  final String imageBannerBaseUrl = '$baseUrl/storage/icon-menu/';
  final String imagePascabayarUrl = '$baseUrl/storage/icon-pascabayar/';
  
  static const String _prefKey = 'productos_prabayar_cache';
}
```

### API Endpoints Used

#### 1. Banner Endpoint
```dart
Future<Response> getBanners(String adminId) {
  return _dio.get(
    'api/banner',
    queryParameters: {'admin_user_id': adminId}
  );
}

// API Response Format:
{
  "status": "success",
  "data": [
    {"id": 1, "image": "https://...banner1.jpg"},
    {"id": 2, "image": "https://...banner2.jpg"},
  ]
}
```

#### 2. Balance Endpoint
```dart
Future<Response> getSaldo(String token) {
  return _dio.get(
    'api/saldo',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
}

// API Response Format:
{
  "data": {
    "saldo": "50000"  // String format for formatting
  }
}
```

#### 3. Points Endpoint
```dart
Future<Response> getPoinSummary(String token) {
  return _dio.get(
    'api/user/poin',
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
}

// API Response Format:
{
  "data": {
    "poin": 2500  // Integer
  }
}
```

#### 4. Menu Prabayar Endpoint
```dart
Future<Response> getMenuPrabayar(String token) => _dio.get(
  'api/menu-prabayar',
  options: Options(headers: {'Authorization': 'Bearer $token'}),
);

// API Response Format:
[
  {
    "id": 1,
    "urutan": 1,
    "admin_user_id": 1050,
    "nama_kategori": "Pulsa",
    "gambar_kategori": "pulsa.png",
    "gambar_url": "https://.../pulsa.png",  // Full URL from API
    "icon_template": null,
    "created_at": "2024-01-01 12:00:00",
    "updated_at": "2024-01-01 12:00:00"
  },
  // ... more menus
]
```

#### 5. Menu Pascabayar Endpoint
```dart
Future<Response> getMenuPascabayar(String token) => _dio.get(
  'api/menu-pascabayar',
  options: Options(headers: {'Authorization': 'Bearer $token'}),
);

// API Response Format:
[
  {
    "id": 1,
    "nama_brand": "PLN",
    "gambar_brand": "pln.png",
    "gambar_url": "https://.../pln.png",
    "urutan": 1
  },
  // ... more brands
]
```

#### 6. Products (Prabayar) Endpoint
```dart
Future<List<ProductPrabayar>> getProducts(
  String? token, {
  bool forceRefresh = false,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final String? cachedData = prefs.getString(_prefKey);

  if (forceRefresh) {
    return await _fetchProductsFromApi(token, prefs);
  }

  if (cachedData != null) {
    return _parseProducts(cachedData);  // Return from cache
  }

  return await _fetchProductsFromApi(token, prefs);  // Fetch and cache
}

Future<List<ProductPrabayar>> _fetchProductsFromApi(
  String? token,
  SharedPreferences prefs,
) async {
  try {
    final response = await _dio.get(
      'api/produk-prabayar',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['status'] == true && data['products'] != null) {
        final String productsJson = json.encode(data['products']);
        await prefs.setString(_prefKey, productsJson);
        return _parseProducts(productsJson);
      }
    }
  } catch (e) {
    // Fallback to cache if API fails
    final String? cachedData = prefs.getString(_prefKey);
    if (cachedData != null) {
      return _parseProducts(cachedData);
    }
  }
  return [];
}

// API Response Format:
{
  "status": true,
  "products": [
    {
      "product_name": "PUBG 100 UC",
      "category": "GAMES",
      "brand": "PUBG",
      "icon_url": "https://.../pubg.png",
      "type": "prepaid",
      "price": 18000,
      "total_harga": 18000,
      "produk_diskon": 0,
      "markup_member": 2000,
      "harga_jual_member": 20000,
      "buyer_sku_code": "PUBG100",
      "buyer_product_status": 1,
      "description": "100 UC untuk PUBG"
    },
    // ... more products
  ]
}
```

#### 7. Brand Detection Endpoint
```dart
Future<String?> detectBrand(String phone, String? token) async {
  final prefs = await SharedPreferences.getInstance();
  String prefix = phone.substring(0, 4);
  String cacheKey = "brand_$prefix";

  // Check cache first
  if (prefs.containsKey(cacheKey)) {
    return prefs.getString(cacheKey);
  }

  try {
    final response = await _dio.get(
      'api/detect-brand',
      queryParameters: {'phone': phone},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (response.statusCode == 200 && response.data['brand'] != null) {
      String detectedBrand = response.data['brand'].toString();
      await prefs.setString(cacheKey, detectedBrand);
      return detectedBrand;
    }
  } catch (e) {
    return null;
  }
}

// API Response Format:
{
  "brand": "Telkomsel"  // or "Indosat", "XL", "Tri"
}
```

#### 8. Public Config Endpoint (Used by AppConfig)
```dart
Future<Response> getPublicConfig(String adminId, String appType) {
  return _dio.get(
    'api/config/$adminId',
    queryParameters: {'app_type': appType},
  );
}

// API Response Format:
{
  "data": {
    "app_name": "Buysindo",
    "primary_color": "#0D6EFD",
    "text_color": "#FFFFFF",
    "logo_url": "https://.../logo.png",
    "template": "ppob_template",
    "tampilan": "ppob_template",
    "subdomain": "buysindo",
    "status": "active",
    "show_appbar": 1,
    "show_navbar": 1
  }
}
```

### API Error Handling Pattern

```dart
final response = await _dio.get(
  'api/endpoint',
  options: Options(headers: {'Authorization': 'Bearer $token'}),
);

// Dio is configured with validateStatus < 500
// This means 4xx responses (404, 401, etc.) don't throw
// Only 5xx and connection errors throw

if (response.statusCode == 200 && response.data != null) {
  // Success - process data
  final data = response.data;
  if (data['status'] == true && data['products'] != null) {
    // Process products
  }
} else {
  // Handle error response
  if (mounted) setState(() => _isLoading = false);
}

// Catch exceptions only for network/timeout errors
catch (e) {
  debugPrint('Error: $e');
  if (mounted) setState(() => _isLoading = false);
  
  // Optionally fallback to cache
  final cachedData = _prefs.getString(cacheKey);
  if (cachedData != null) {
    // Use cached data
  }
}
```

### Parallel Request Pattern

```dart
// Fetch multiple endpoints concurrently
Future<void> _fetchAllData() async {
  await Future.wait([
    _fetchBanners(),      // GET /api/banner
    _fetchSaldo(),        // GET /api/saldo
    _fetchPoin(),         // GET /api/user/poin
    _fetchMenuPrabayar(), // GET /api/menu-prabayar
    _fetchMenuPascabayar(),// GET /api/menu-pascabayar
  ]);
}
```

### Token Management Pattern

All authenticated endpoints use SessionManager:
```dart
// Get token from secure storage
String? token = await SessionManager.getToken();

if (token == null || token.isEmpty) {
  // Handle not logged in
  return;
}

// Use token in request
final response = await _dio.get(
  'api/endpoint',
  options: Options(headers: {'Authorization': 'Bearer $token'}),
);
```

---

## Summary Table

| Component | Purpose | Cache Key | Update Trigger |
|-----------|---------|-----------|-----------------|
| GameTopupScreen | Games category topup | cached_banners, cached_poin, cached_saldo | Pull-to-refresh, Init |
| ppob_template | Main PPOB screen | cached_banners, cached_menu_prabayar, cached_menu_pascabayar | Pull-to-refresh, Init |
| AppConfig | App-wide settings | cfg_* (6 keys) | App startup, API fetch |
| SessionManager | Auth tokens | access_token, admin_user_id | Login/Logout |
| ApiService | API layer with cache | cached_banners, cached_menu_*, brand_* | forceRefresh flag, API calls |

| API Endpoint | Method | Auth | Cache | Response |
|--------------|--------|------|-------|----------|
| /api/banner | GET | Admin ID | banners | List of image URLs |
| /api/saldo | GET | Token | saldo | Balance string |
| /api/user/poin | GET | Token | poin | Integer points |
| /api/menu-prabayar | GET | Token | menu_prabayar | List of menu items |
| /api/menu-pascabayar | GET | Token | menu_pascabayar | List of brand items |
| /api/produk-prabayar | GET | Token | productos_prabayar_cache | List of products |
| /api/detect-brand | GET | Token | brand_${prefix} | Detected brand name |
| /api/config/{id} | GET | - | (in AppConfig) | App configuration |

