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
  final bool hasGroupStage;
  final TournamentFormat format;
  final GroupStageConfig? groupStageConfig;
  final String? championId;
  final String? championName;
  final String? runnerUpId;
  final String? runnerUpName;

  const TournamentCategoryModel({
    this.id,
    required this.name,
    required this.gender,
    required this.participants,
    this.hasBracket = false,
    this.hasGroupStage = false,
    this.format = TournamentFormat.singleElimination,
    this.groupStageConfig,
    this.championId,
    this.championName,
    this.runnerUpId,
    this.runnerUpName,
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
        id: json['id'] as String? ?? json['_id'] as String?,
        name: json['name'] as String? ?? 'Sin Nombre',
        gender: CategoryGender.fromString(json['gender'] as String? ?? 'MIXED'),
        participants: participantsList,
        hasBracket: json['hasBracket'] as bool? ?? false,
        hasGroupStage: json['hasGroupStage'] as bool? ?? false,
        format: TournamentFormat.fromString(
          json['format'] as String? ?? 'SINGLE_ELIMINATION',
        ),
        groupStageConfig: json['groupStageConfig'] != null
            ? GroupStageConfig.fromJson(
                json['groupStageConfig'] as Map<String, dynamic>,
              )
            : null,
        championId: json['championId'] as String?,
        championName: json['championName'] as String?,
        runnerUpId: json['runnerUpId'] as String?,
        runnerUpName: json['runnerUpName'] as String?,
      );
    } catch (e, stackTrace) {
      final logger = AppLogger.tag('TournamentCategoryModel');
      logger.error(
        'Error parsing TournamentCategoryModel',
        error: e,
        stackTrace: stackTrace,
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
      'hasGroupStage': hasGroupStage,
      'format': format.value,
      if (groupStageConfig != null)
        'groupStageConfig': groupStageConfig!.toJson(),
      'championId': championId,
      'championName': championName,
      'runnerUpId': runnerUpId,
      'runnerUpName': runnerUpName,
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

/// Formato de torneo.
enum TournamentFormat {
  singleElimination('SINGLE_ELIMINATION'),
  roundRobin('ROUND_ROBIN'),
  hybrid('HYBRID');

  final String value;
  const TournamentFormat(this.value);

  static TournamentFormat fromString(String value) {
    return TournamentFormat.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TournamentFormat.singleElimination,
    );
  }
}

/// Método de seeding para grupos.
enum SeedingMethod {
  ranking('RANKING'),
  random('RANDOM');

  final String value;
  const SeedingMethod(this.value);

  static SeedingMethod fromString(String value) {
    return SeedingMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SeedingMethod.ranking,
    );
  }
}

/// Configuración de la fase de grupos para torneos híbridos.
class GroupStageConfig {
  final int numberOfGroups;
  final int playersAdvancingPerGroup;
  final SeedingMethod seedingMethod;
  final int pointsForWin;
  final int pointsForDraw;
  final int pointsForLoss;

  const GroupStageConfig({
    required this.numberOfGroups,
    required this.playersAdvancingPerGroup,
    required this.seedingMethod,
    this.pointsForWin = 3,
    this.pointsForDraw = 1,
    this.pointsForLoss = 0,
  });

  factory GroupStageConfig.fromJson(Map<String, dynamic> json) {
    return GroupStageConfig(
      numberOfGroups: json['numberOfGroups'] as int? ?? 0,
      playersAdvancingPerGroup:
          (json['playersAdvancingPerGroup'] as int?) ??
          (json['advancePerGroup'] as int?) ??
          0,
      seedingMethod: SeedingMethod.fromString(
        json['seedingMethod'] as String? ?? 'RANKING',
      ),
      pointsForWin: json['pointsForWin'] as int? ?? 3,
      pointsForDraw: json['pointsForDraw'] as int? ?? 1,
      pointsForLoss: json['pointsForLoss'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numberOfGroups': numberOfGroups,
      'advancePerGroup': playersAdvancingPerGroup, // Backend espera esto
      'playersAdvancingPerGroup': playersAdvancingPerGroup, // Compatibilidad
      'seedingMethod': seedingMethod.value,
      'pointsForWin': pointsForWin,
      'pointsForDraw': pointsForDraw,
      'pointsForLoss': pointsForLoss,
    };
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
      userId: json['userId'] as String? ?? 'UNKNOWN',
      eloRating: json['eloRating'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'eloRating': eloRating};
  }
}
