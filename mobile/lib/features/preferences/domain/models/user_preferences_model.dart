/// Model for User Preferences (favorite professors and tenants)
class UserPreferencesModel {
  final List<FavoriteProfessor> favoriteProfessors;
  final List<FavoriteTenant> favoriteTenants;

  UserPreferencesModel({
    required this.favoriteProfessors,
    required this.favoriteTenants,
  });

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) {
    return UserPreferencesModel(
      favoriteProfessors: (json['favoriteProfessors'] as List<dynamic>?)
              ?.map((item) => FavoriteProfessor.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      favoriteTenants: (json['favoriteTenants'] as List<dynamic>?)
              ?.map((item) => FavoriteTenant.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'favoriteProfessors': favoriteProfessors.map((p) => p.toJson()).toList(),
      'favoriteTenants': favoriteTenants.map((t) => t.toJson()).toList(),
    };
  }

  UserPreferencesModel copyWith({
    List<FavoriteProfessor>? favoriteProfessors,
    List<FavoriteTenant>? favoriteTenants,
  }) {
    return UserPreferencesModel(
      favoriteProfessors: favoriteProfessors ?? this.favoriteProfessors,
      favoriteTenants: favoriteTenants ?? this.favoriteTenants,
    );
  }
}

/// Model for a favorite professor
class FavoriteProfessor {
  final String id;
  final String name;
  final String email;
  final List<String> specialties;

  FavoriteProfessor({
    required this.id,
    required this.name,
    required this.email,
    required this.specialties,
  });

  factory FavoriteProfessor.fromJson(Map<String, dynamic> json) {
    return FavoriteProfessor(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      specialties: (json['specialties'] as List<dynamic>?)
              ?.map((item) => item as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'specialties': specialties,
    };
  }
}

/// Model for a favorite tenant (center)
class FavoriteTenant {
  final String id;
  final String name;
  final String slug;
  final String? logo;
  final bool isActive;

  FavoriteTenant({
    required this.id,
    required this.name,
    required this.slug,
    this.logo,
    required this.isActive,
  });

  factory FavoriteTenant.fromJson(Map<String, dynamic> json) {
    return FavoriteTenant(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      logo: json['logo'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'logo': logo,
      'isActive': isActive,
    };
  }
}

