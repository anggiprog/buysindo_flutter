class BannerResponse {
  final String status;
  final List<String> banners;

  BannerResponse({required this.status, required this.banners});

  factory BannerResponse.fromJson(Map<String, dynamic> json) {
    return BannerResponse(
      status: json['status'] ?? '',
      banners: List<String>.from(json['banners'] ?? []),
    );
  }
}
