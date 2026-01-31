import '../models/tournament_model.dart';

class CreateTournamentDto {
  final String name;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final List<CreateCategoryDto> categories;

  const CreateTournamentDto({
    required this.name,
    this.description,
    required this.startDate,
    required this.endDate,
    required this.categories,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'categories': categories.map((e) => e.toJson()).toList(),
    };
  }
}

class CreateCategoryDto {
  final String name;
  final CategoryGender gender;

  const CreateCategoryDto({required this.name, required this.gender});

  Map<String, dynamic> toJson() {
    return {'name': name, 'gender': gender.value};
  }
}
