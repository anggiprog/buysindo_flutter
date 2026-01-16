class UserModel {
  final int id;
  final String username;
  final String email;
  final String? referralCode;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.referralCode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      referralCode: json['referral_code'],
    );
  }
}

class ProfileModel {
  final int id;
  final int userId;
  final String? fullName;
  final String? address;
  final String? gender;
  final String? birthdate;
  final String? phone;
  final String? profilePicture;
  final String? referralDate;
  final int verified;

  ProfileModel({
    required this.id,
    required this.userId,
    this.fullName,
    this.address,
    this.gender,
    this.birthdate,
    this.phone,
    this.profilePicture,
    this.referralDate,
    required this.verified,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      fullName: json['full_name'],
      address: json['address'],
      gender: json['gender'],
      birthdate: json['birthdate'],
      phone: json['phone'],
      profilePicture: json['profile_picture'],
      referralDate: json['referral_date'],
      verified: json['verified'] ?? 0,
    );
  }
}

class ProfileResponse {
  final bool success;
  final UserModel user;
  final ProfileModel profile;

  ProfileResponse({
    required this.success,
    required this.user,
    required this.profile,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      success: json['success'] ?? false,
      user: UserModel.fromJson(json['user']),
      profile: ProfileModel.fromJson(json['profile']),
    );
  }
}

class LoginResponse {
  final String? message;
  final String? accessToken;
  final String? tokenType;
  final bool requireOtp; // Default false jika tidak ada
  final UserModel? user; // Menggunakan UserModel yang sudah kita buat

  LoginResponse({
    this.message,
    this.accessToken,
    this.tokenType,
    required this.requireOtp,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'] as String?,
      accessToken: json['access_token'] as String?,
      tokenType: json['token_type'] as String?,
      requireOtp: json['require_otp'] ?? false, // Jika null, anggap false
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}
