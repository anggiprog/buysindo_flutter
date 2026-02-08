import 'package:equatable/equatable.dart';

class AppMenusModel extends Equatable {
  final int adminUserId;
  final int? parentId;
  final String title;
  final String slug;
  final String menuType;
  final int orderIndex;
  final String icon;
  final bool status;
  final Map<String, dynamic>? settings;
  final String? iconUrl;
  final String? htmlFilename;

  const AppMenusModel({
    required this.adminUserId,
    this.parentId,
    required this.title,
    required this.slug,
    required this.menuType,
    required this.orderIndex,
    required this.icon,
    required this.status,
    this.settings,
    this.iconUrl,
    this.htmlFilename,
  });

  factory AppMenusModel.fromJson(Map<String, dynamic> json) {
    return AppMenusModel(
      adminUserId: json['admin_user_id'] as int,
      parentId: json['parent_id'] as int?,
      title: json['title'] as String,
      slug: json['slug'] as String,
      menuType: json['menu_type'] as String,
      orderIndex: json['order_index'] as int,
      icon: json['icon'] as String,
      status: json['status'] == 1 || json['status'] == true,
      settings: json['settings'] is Map
          ? Map<String, dynamic>.from(json['settings'])
          : null,
      iconUrl: json['icon_url'] as String?,
      htmlFilename: json['html_filename'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'admin_user_id': adminUserId,
      'parent_id': parentId,
      'title': title,
      'slug': slug,
      'menu_type': menuType,
      'order_index': orderIndex,
      'icon': icon,
      'status': status ? 1 : 0,
      'settings': settings,
      'icon_url': iconUrl,
      'html_filename': htmlFilename,
    };
  }

  @override
  List<Object?> get props => [
    adminUserId,
    parentId,
    title,
    slug,
    menuType,
    orderIndex,
    icon,
    status,
    settings,
    iconUrl,
    htmlFilename,
  ];
}
