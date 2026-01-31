import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tennis_management/features/ranking/presentation/screens/ranking_screen.dart';
import 'package:tennis_management/features/ranking/presentation/widgets/ranking_podium.dart';

import 'package:tennis_management/features/ranking/presentation/providers/ranking_providers.dart';
import 'package:tennis_management/features/ranking/infrastructure/repositories/mock_ranking_repository.dart';

void main() {
  setUpAll(() {
    // Evitar errores de HTTP request en tests para NetworkImage
    HttpOverrides.global = null;
  });

  testWidgets('RankingScreen renders tabs and leaderboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          rankingRepositoryProvider.overrideWithValue(MockRankingRepository()),
        ],
        child: const MaterialApp(home: RankingScreen()),
      ),
    );

    // Verificar que el título esté presente
    expect(find.text('Rankings CourtHub'), findsOneWidget);

    // Verificar que las pestañas existan
    expect(find.text('Nivel (ELO)'), findsOneWidget);
    expect(find.text('La Raza (Mensual)'), findsOneWidget);

    // Esperar a que se carguen los datos mock
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Verificar que el podio esté presente
    expect(find.byType(RankingPodium), findsOneWidget);

    // Verificar que algunos de los jugadores mock estén en la lista
    // En el podio solo mostramos el primer nombre
    expect(find.text('Carlos'), findsOneWidget);
    expect(find.text('Jannik'), findsOneWidget);

    // Cambiar a la pestaña de Race
    await tester.tap(find.text('La Raza (Mensual)'));
    await tester.pumpAndSettle();

    // Verificar que los datos de Race se carguen
    // Jannik Sinner tiene 450 en Race en el mock
    expect(find.text('450'), findsOneWidget);
  });
}
