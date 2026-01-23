import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:buysindo_app/core/app_config.dart';
import 'package:buysindo_app/core/network/session_manager.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/network/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _remoteLogoUrl;
  String? _tagline;
  Uint8List? _remoteLogoBytes; // prefer memory image when available
  String? _cachedUpdatedAt;
  bool _isLoadingImage =
      true; // controls showing spinner when we don't have cache

  static const _kSplashUrlKey = 'cached_splash_url';
  static const _kSplashTaglineKey = 'cached_splash_tagline';
  static const _kSplashUpdatedAtKey = 'cached_splash_updated_at';
  static const _kSplashFileKey = 'cached_splash_file';

  @override
  void initState() {
    super.initState();
    // Load cached splash first so UI can show it immediately
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadCachedSplash();
      // If we already have cached bytes, show immediately and remove native splash
      if (_remoteLogoBytes != null) {
        try {
          FlutterNativeSplash.remove();
        } catch (_) {}
        // Start background update but don't wait for it; navigate quickly for snappy UX
        _backgroundUpdateSplash();
        // Short delay so user sees splash before navigating
        Future.delayed(const Duration(milliseconds: 800), () async {
          if (!mounted) return;
          final token = await SessionManager.getToken();
          if (!mounted) return;
          final next = (token != null && token.isNotEmpty) ? '/home' : '/login';
          Navigator.pushReplacementNamed(context, next);
        });
      } else {
        // No cached image -- perform fetch and navigate when completed
        _fetchRemoteSplashAndPrecache();
      }
    });
    // fallback removal
    Future.delayed(const Duration(seconds: 5), () {
      try {
        FlutterNativeSplash.remove();
      } catch (_) {}
    });
  }

  Future<void> _loadCachedSplash() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filePath = prefs.getString(_kSplashFileKey);
      final url = prefs.getString(_kSplashUrlKey);
      final tagline = prefs.getString(_kSplashTaglineKey);
      final updatedAt = prefs.getString(_kSplashUpdatedAtKey);

      if (filePath != null && filePath.isNotEmpty) {
        final f = File(filePath);
        if (await f.exists()) {
          final bytes = await f.readAsBytes();
          setState(() {
            _remoteLogoBytes = bytes;
            _remoteLogoUrl = url;
            _tagline = tagline;
            _cachedUpdatedAt = updatedAt;
            _isLoadingImage = false; // cached image available => no spinner
          });
          return;
        }
      }

      // If no file but url exists, keep network mode
      if (url != null && url.isNotEmpty) {
        setState(() {
          _remoteLogoUrl = url;
          _tagline = tagline;
          _cachedUpdatedAt = updatedAt;
          _isLoadingImage = true;
        });
        return;
      }

      // nothing cached
      setState(() {
        _isLoadingImage = true;
      });
    } catch (e) {
      debugPrint('⚠️ Failed to load cached splash: $e');
      setState(() {
        _isLoadingImage = true;
      });
    }
  }

  Future<void> _saveSplashToCache(
    String url,
    List<int> bytes,
    String? tagline,
    String? updatedAt,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/cached_splash.png');
      await file.writeAsBytes(bytes, flush: true);
      await prefs.setString(_kSplashFileKey, file.path);
      await prefs.setString(_kSplashUrlKey, url);
      await prefs.setString(_kSplashTaglineKey, tagline ?? '');
      await prefs.setString(_kSplashUpdatedAtKey, updatedAt ?? '');
      debugPrint('✅ Splash cached to filesystem: ${file.path}');
    } catch (e) {
      debugPrint('⚠️ Failed to cache splash: $e');
    }
  }

  Future<void> _fetchRemoteSplashAndPrecache() async {
    String? logoToUse;
    String? taglineToUse;
    bool shouldShowSplash = true;
    String? remoteUpdatedAt;

    try {
      final adminId = appConfig.adminId;
      final api = ApiService(Dio());
      final data = await api.getSplashScreen(adminId);
      debugPrint('🌊 Splash API response: $data');

      if (data == null) {
        shouldShowSplash = true; // no remote config, show default splash
      } else {
        final status = (data['status'] as String?)?.toLowerCase();
        // If status explicitly not 'active', skip splash entirely
        if (status != null && status != 'active') {
          shouldShowSplash = false;
        } else {
          // status active or missing -> accept remote logo URL directly
          final candidate = data['logo'] as String?;
          final candidateTag = data['tagline'] as String?;
          remoteUpdatedAt = data['updated_at'] as String?;
          if (candidate != null && candidate.isNotEmpty) {
            logoToUse = candidate;
            taglineToUse = candidateTag;
            debugPrint('ℹ️ Using remote logo: $logoToUse');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Splash fetch failed: $e');
    }

    // If remote config said inactive -> navigate immediately (skip showing remote splash)
    if (!shouldShowSplash) {
      try {
        FlutterNativeSplash.remove();
      } catch (_) {}
      if (!mounted) return;
      final token = await SessionManager.getToken();
      if (!mounted) return;
      final next = (token != null && token.isNotEmpty) ? '/home' : '/login';
      Navigator.pushReplacementNamed(context, next);
      return;
    }

    // If we found a usable remote logo, consider if we need to fetch/update cache
    if (logoToUse != null) {
      final needsUpdate =
          (_cachedUpdatedAt == null ||
              remoteUpdatedAt == null ||
              remoteUpdatedAt != _cachedUpdatedAt) ||
          (_remoteLogoUrl == null || _remoteLogoUrl != logoToUse) ||
          _remoteLogoBytes == null;
      debugPrint(
        'ℹ️ Splash needsUpdate=$needsUpdate cachedUpdated=$_cachedUpdatedAt remoteUpdated=$remoteUpdatedAt',
      );
      if (!needsUpdate) {
        // nothing to do: we already have cached bytes and up-to-date
        debugPrint('ℹ️ Cached splash is up-to-date, skipping re-download');
      } else {
        if (mounted) {
          setState(() {
            _remoteLogoUrl = logoToUse;
            _tagline = taglineToUse;
          });
        } else {
          _remoteLogoUrl = logoToUse;
          _tagline = taglineToUse;
        }

        // Attempt to GET image bytes (faster deterministic rendering) with timeout
        try {
          final dio = Dio();
          dio.options.connectTimeout = const Duration(seconds: 6);
          dio.options.receiveTimeout = const Duration(seconds: 6);
          final resp = await dio.getUri(
            Uri.parse(logoToUse),
            options: Options(
              responseType: ResponseType.bytes,
              validateStatus: (s) => s! < 500,
            ),
          );
          if (resp.statusCode == 200 && resp.data != null) {
            final bytes = resp.data as List<int>;
            if (bytes.isNotEmpty) {
              if (mounted) {
                setState(() {
                  _remoteLogoBytes = Uint8List.fromList(bytes);
                  _isLoadingImage = false;
                });
              } else {
                _remoteLogoBytes = Uint8List.fromList(bytes);
              }
              // Save to filesystem cache with remoteUpdatedAt
              await _saveSplashToCache(
                logoToUse,
                bytes,
                taglineToUse,
                remoteUpdatedAt,
              );
              debugPrint(
                '✅ Fetched remote splash bytes, will render Image.memory',
              );
            }
          } else {
            debugPrint(
              '⚠️ Failed to fetch splash bytes, will rely on Image.network (status ${resp.statusCode})',
            );
          }
        } catch (e) {
          debugPrint('⚠️ Fetching remote splash bytes failed: $e');
        }
      }
    }

    // Remove native splash then navigate after a short delay so image is visible
    try {
      FlutterNativeSplash.remove();
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    final token = await SessionManager.getToken();
    if (!mounted) return;
    final next = (token != null && token.isNotEmpty) ? '/home' : '/login';
    Navigator.pushReplacementNamed(context, next);
  }

  /// Background-only update: fetch remote splash and update cache if newer.
  /// Does NOT perform navigation or remove native splash.
  Future<void> _backgroundUpdateSplash() async {
    try {
      final adminId = appConfig.adminId;
      final api = ApiService(Dio());
      final data = await api.getSplashScreen(adminId);
      debugPrint('🌊 (background) Splash API response: $data');
      if (data == null) return;
      final status = (data['status'] as String?)?.toLowerCase();
      if (status != null && status != 'active') return; // no update if inactive

      final candidate = data['logo'] as String?;
      final candidateTag = data['tagline'] as String?;
      final remoteUpdatedAt = data['updated_at'] as String?;
      if (candidate == null || candidate.isEmpty) return;

      final needsUpdate =
          (_cachedUpdatedAt == null ||
              remoteUpdatedAt == null ||
              remoteUpdatedAt != _cachedUpdatedAt) ||
          (_remoteLogoUrl == null || _remoteLogoUrl != candidate) ||
          _remoteLogoBytes == null;
      if (!needsUpdate) {
        debugPrint('🌊 (background) Splash cache up to date');
        return;
      }

      // Try download bytes
      try {
        final dio = Dio();
        dio.options.connectTimeout = const Duration(seconds: 6);
        dio.options.receiveTimeout = const Duration(seconds: 6);
        final resp = await dio.getUri(
          Uri.parse(candidate),
          options: Options(
            responseType: ResponseType.bytes,
            validateStatus: (s) => s! < 500,
          ),
        );
        if (resp.statusCode == 200 && resp.data != null) {
          final bytes = resp.data as List<int>;
          if (bytes.isNotEmpty) {
            await _saveSplashToCache(
              candidate,
              bytes,
              candidateTag,
              remoteUpdatedAt,
            );
            if (mounted)
              setState(() {
                _remoteLogoBytes = Uint8List.fromList(bytes);
                _remoteLogoUrl = candidate;
                _tagline = candidateTag;
                _cachedUpdatedAt = remoteUpdatedAt;
                _isLoadingImage = false;
              });
            debugPrint('🌊 (background) Updated cached splash successfully');
          }
        }
      } catch (e) {
        debugPrint('⚠️ (background) Failed to update splash bytes: $e');
      }
    } catch (e) {
      debugPrint('⚠️ (background) Splash update failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Responsive larger image: up to 60% of width, max 240
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final width = constraints.maxWidth.isFinite
                      ? constraints.maxWidth * 0.6
                      : 240.0;
                  final imageSize = width.clamp(140.0, 320.0);

                  if (_remoteLogoBytes != null)
                    return Image.memory(
                      _remoteLogoBytes!,
                      width: imageSize,
                      height: imageSize,
                      fit: BoxFit.contain,
                    );
                  else if (_remoteLogoUrl != null && _remoteLogoUrl!.isNotEmpty)
                    // Try network image if bytes fetch failed – loadingBuilder keeps spinner until loaded
                    Image.network(
                      _remoteLogoUrl!,
                      width: imageSize,
                      height: imageSize,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return SizedBox(
                          width: imageSize,
                          height: imageSize,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/logo.png',
                        width: imageSize,
                        height: imageSize,
                      ),
                    );
                  return Image.asset(
                    'assets/images/logo.png',
                    width: imageSize,
                    height: imageSize,
                  );
                },
              ),

              const SizedBox(height: 16),

              Text(
                _tagline ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 20),

              // show spinner only if we don't already have cached image
              if (_isLoadingImage && _remoteLogoBytes == null)
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
