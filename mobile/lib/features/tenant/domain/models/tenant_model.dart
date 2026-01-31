import '../../../../core/interfaces/tenant_info_interface.dart';

/// Model for Tenant (Center) information
class TenantModel implements ITenantInfo {
  @override
  final String id;
  @override
  final String name;
  @override
  final String slug;
  final String? domain;
  final bool isActive;
  @override
  final String? logo;
  @override
  final Map<String, dynamic>? config;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TenantModel({
    required this.id,
    required this.name,
    required this.slug,
    this.domain,
    required this.isActive,
    this.logo,
    this.config,
    this.createdAt,
    this.updatedAt,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: json['id'] as String? ?? json['tenantId'] as String? ?? '',
      name: json['name'] as String? ?? json['tenantName'] as String? ?? '',
      slug: json['slug'] as String? ?? json['tenantSlug'] as String? ?? '',
      domain: json['domain'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      logo: json['logo'] as String? ?? json['config']?['logo'] as String?,
      config: json['config'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'domain': domain,
      'isActive': isActive,
      'logo': logo,
      'config': config,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
