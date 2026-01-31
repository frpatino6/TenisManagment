import '../models/tournament_model.dart';

class UpdateTournamentDto {
  final String? name;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<UpdateCategoryDto>? categories;

  const UpdateTournamentDto({
    this.name,
    this.description,
    this.startDate,
    this.endDate,
    this.categories,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (name != null) json['name'] = name;
    if (description != null) json['description'] = description;
    if (startDate != null) json['startDate'] = startDate!.toIso8601String();
    if (endDate != null) json['endDate'] = endDate!.toIso8601String();
    if (categories != null) {
      json['categories'] = categories!.map((e) => e.toJson()).toList();
    }
    return json;
  }
}

class UpdateCategoryDto {
  final String? id;
  final String? name;
  final CategoryGender? gender;
  final TournamentFormat? format;

  const UpdateCategoryDto({this.id, this.name, this.gender, this.format});

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (id != null) json['id'] = id;
    if (name != null) json['name'] = name;
    if (gender != null) json['gender'] = gender!.value;
    if (format != null) json['format'] = format!.value;
    return json;
  }
}
