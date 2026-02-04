import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/network/api_service.dart';
import '../../../../../core/network/session_manager.dart';

/// Model untuk Popup Data
class PopupData {
  final int id;
  final int adminUserId;
  final int status;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;

  PopupData({
    required this.id,
    required this.adminUserId,
    required this.status,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PopupData.fromJson(Map<String, dynamic> json) {
    List<String> imageList = [];

    // Collect all gambar fields that are not null or empty
    if (json['gambar1'] != null && json['gambar1'].toString().isNotEmpty) {
      imageList.add(json['gambar1'].toString());
    }
    if (json['gambar2'] != null && json['gambar2'].toString().isNotEmpty) {
      imageList.add(json['gambar2'].toString());
    }
    if (json['gambar3'] != null && json['gambar3'].toString().isNotEmpty) {
      imageList.add(json['gambar3'].toString());
    }

    return PopupData(
      id: json['id'] ?? 0,
      adminUserId: json['admin_user_id'] ?? 0,
      status: json['status'] ?? 0,
      images: imageList,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }
}

/// PopupDialog Widget - Beautiful swipeable popup with dots indicator
class PopupDialog extends StatefulWidget {
  final PopupData popupData;
  final VoidCallback? onClose;

  const PopupDialog({super.key, required this.popupData, this.onClose});

  @override
  State<PopupDialog> createState() => _PopupDialogState();

  /// Show the popup dialog
  static Future<void> show(BuildContext context, PopupData popupData) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Popup',
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return PopupDialog(
          popupData: popupData,
          onClose: () async {
            // Save close time to SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt(
              'popup_closed_time',
              DateTime.now().millisecondsSinceEpoch,
            );
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }
}

class _PopupDialogState extends State<PopupDialog> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    if (widget.popupData.images.length > 1) {
      _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (mounted) {
          int nextPage = (_currentPage + 1) % widget.popupData.images.length;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width * 0.85;
    final dialogHeight = size.height * 0.55;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: dialogWidth,
          height: dialogHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main content with images
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Colors.grey.shade100],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Image Slider
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: widget.popupData.images.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return _buildImageItem(
                              widget.popupData.images[index],
                              index,
                            );
                          },
                        ),
                      ),

                      // Dots Indicator
                      if (widget.popupData.images.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20, top: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              widget.popupData.images.length,
                              (index) => _buildDot(index),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Close Button (floating on top-right corner)
              Positioned(
                top: -15,
                right: -15,
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.red.shade400, Colors.red.shade600],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),

              // Swipe hint indicator
              if (widget.popupData.images.length > 1)
                Positioned(
                  bottom: 55,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swipe_rounded,
                            color: Colors.white.withOpacity(0.9),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Geser untuk melihat lebih',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageItem(String imageUrl, int index) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey.shade200,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey.shade200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_rounded,
                  size: 50,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 10),
                Text(
                  'Gagal memuat gambar',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    bool isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: isActive
            ? LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.7),
                ],
              )
            : null,
        color: isActive ? null : Colors.grey.shade300,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
    );
  }
}

/// PopupManager - Handles popup fetching and display logic with 1-hour interval
class PopupManager {
  static const String _popupClosedTimeKey = 'popup_closed_time';
  static const String _popupCacheKey = 'popup_cache';
  static const int _popupIntervalHours = 1; // Show popup every 1 hour

  final ApiService apiService;

  PopupManager({ApiService? apiService})
    : apiService = apiService ?? ApiService(Dio());

  /// Check if popup should be shown (based on 1-hour interval)
  Future<bool> shouldShowPopup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastClosedTime = prefs.getInt(_popupClosedTimeKey);

      if (lastClosedTime == null) {
        // Never closed before, show popup
        return true;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final hourInMillis = _popupIntervalHours * 60 * 60 * 1000;

      // Check if 1 hour has passed since last close
      return (now - lastClosedTime) >= hourInMillis;
    } catch (e) {
      return true;
    }
  }

  /// Fetch popup data from API
  Future<PopupData?> fetchPopupData() async {
    try {
      // Get token from SessionManager
      final token = await SessionManager.getToken();

      if (token == null || token.isEmpty) {
        debugPrint('[PopupManager] No token available');
        return null;
      }

      debugPrint('[PopupManager] Fetching popup with token...');
      final response = await apiService.getPopup(token);

      debugPrint('[PopupManager] Response status: ${response.statusCode}');
      debugPrint('[PopupManager] Response data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        if (data['success'] == true && data['data'] != null) {
          final popupData = PopupData.fromJson(data['data']);

          // Only return if status is 1 (active)
          if (popupData.status == 1 && popupData.images.isNotEmpty) {
            // Cache the popup data
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_popupCacheKey, data['data'].toString());

            return popupData;
          }
        }
      }
    } catch (e) {
      debugPrint('[PopupManager] Error fetching popup: $e');
    }
    return null;
  }

  /// Check and show popup if conditions are met
  Future<void> checkAndShowPopup(BuildContext context) async {
    try {
      // First check if we should show popup based on time interval
      final shouldShow = await shouldShowPopup();

      if (!shouldShow) {
        debugPrint('[PopupManager] Popup not shown - within 1 hour interval');
        return;
      }

      // Fetch popup data from API
      final popupData = await fetchPopupData();

      if (popupData != null && context.mounted) {
        // Show the popup dialog
        await PopupDialog.show(context, popupData);
      }
    } catch (e) {
      debugPrint('[PopupManager] Error in checkAndShowPopup: $e');
    }
  }

  /// Reset popup timer (for testing purposes)
  Future<void> resetPopupTimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_popupClosedTimeKey);
  }
}
