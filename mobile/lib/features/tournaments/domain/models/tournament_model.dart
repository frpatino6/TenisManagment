import '../../../../core/logging/logger.dart';

/// Modelo de dominio para un torneo.

class TournamentModel {
  final String id;
  final String name;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final TournamentStatus status;
  final List<TournamentCategoryModel> categories;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TournamentModel({
    required this.id,
    required this.name,
    this.description,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.categories,
    required this.createdAt,
    required this.updatedAt,
  });

  static DateTime _parseDate(dynamic val) {
    if (val is String) {
      return DateTime.parse(val);
    } else if (val is Map && val.containsKey('date')) {
      return DateTime.parse(val['date'] as String);
    }
    return DateTime.now();
  }

  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    try {
      return TournamentModel(
        id: json['id'] as String? ?? json['_id'] as String? ?? 'UNKNOWN_ID',
        name: json['name'] as String? ?? 'Sin Nombre',
        description: json['description'] as String?,
        startDate: _parseDate(json['startDate']),
        endDate: _parseDate(json['endDate']),
        status: TournamentStatus.fromString(
          json['status'] as String? ?? 'DRAFT',
        ),
        categories: ((json['categories'] ?? []) as List<dynamic>)
            .map(
              (e) =>
                  TournamentCategoryModel.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        createdAt: _parseDate(json['createdAt']),
        updatedAt: _parseDate(json['updatedAt']),
      );
    } catch (e) {
      final logger = AppLogger.tag('TournamentModel');
      logger.error(
        'Error parsing TournamentModel',
        error: e,
        context: {'json': json},
      );
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status.value,
      'categories': categories.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Verifica si el torneo está activo (en progreso).
  bool get isActive => status == TournamentStatus.inProgress;

  /// Verifica si el torneo está completo.
  bool get isCompleted => status == TournamentStatus.completed;

  /// Verifica si el usuario puede inscribirse.
  bool get canEnroll => status == TournamentStatus.draft;

  /// Verifica si el usuario está inscrito en alguna categoría del torneo.
  bool isUserEnrolled(String userId) {
    return categories.any((c) => c.isUserEnrolled(userId));
  }
}

/// Estado de un torneo.
enum TournamentStatus {
  draft('DRAFT'),
  inProgress('IN_PROGRESS'),
  completed('FINISHED'),
  cancelled('CANCELLED');

  final String value;
  const TournamentStatus(this.value);

  static TournamentStatus fromString(String value) {
    return TournamentStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TournamentStatus.draft,
    );
  }
}

/// Modelo para una categoría de torneo.
class TournamentCategoryModel {
  final String? id;
  final String name;
  final CategoryGender gender;
  final List<String> participants;
  final bool hasBracket;

  const TournamentCategoryModel({
    this.id,
    required this.name,
    required this.gender,
    required this.participants,
    this.hasBracket = false,
  });

  factory TournamentCategoryModel.fromJson(Map<String, dynamic> json) {
    try {
      // Backend envía una lista de IDs (Strings) para participants
      final participantsData = json['participants'];
      List<String> participantsList = [];

      if (participantsData is List) {
        participantsList = participantsData.map((e) => e.toString()).toList();
      }

      return TournamentCategoryModel(
        id: json['id'] as String?,
        name: json['name'] as String,
        gender: CategoryGender.fromString(json['gender'] as String? ?? 'MIXED'),
        participants: participantsList,
        hasBracket: json['hasBracket'] as bool? ?? false,
      );
    } catch (e) {
      final logger = AppLogger.tag('TournamentCategoryModel');
      logger.error(
        'Error parsing TournamentCategoryModel',
        error: e,
        context: {'json': json},
      );
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gender': gender.value,
      'participants': participants,
      'hasBracket': hasBracket,
    };
  }

  /// Verifica si un usuario está inscrito en esta categoría.
  bool isUserEnrolled(String userId) {
    return participants.contains(userId);
  }
}

/// Género de una categoría.
enum CategoryGender {
  male('MALE'),
  female('FEMALE'),
  mixed('MIXED');

  final String value;
  const CategoryGender(this.value);

  static CategoryGender fromString(String value) {
    return CategoryGender.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CategoryGender.mixed,
    );
  }
}

// Eliminamos TournamentParticipant ya que el backend solo envía IDs por ahora

/// Participante de un torneo.
class TournamentParticipant {
  final String userId;
  final int eloRating;

  const TournamentParticipant({required this.userId, required this.eloRating});

  factory TournamentParticipant.fromJson(Map<String, dynamic> json) {
    return TournamentParticipant(
      userId: json['userId'] as String,
      eloRating: json['eloRating'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'eloRating': eloRating};
  }
}
