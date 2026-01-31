import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/tournaments_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/bracket_tree_widget.dart';
import '../widgets/tournament_match_result_dialog.dart';
import '../../../../core/exceptions/network_exception.dart';

class BracketViewScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final String categoryId;

  const BracketViewScreen({
    super.key,
    required this.tournamentId,
    required this.categoryId,
  });

  @override
  ConsumerState<BracketViewScreen> createState() => _BracketViewScreenState();
}

class _BracketViewScreenState extends ConsumerState<BracketViewScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final bracketAsync = ref.watch(
      bracketProvider(widget.tournamentId, widget.categoryId),
    );

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Cuadro del Torneo'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.invalidate(
                    bracketProvider(widget.tournamentId, widget.categoryId),
                  );
                },
              ),
              if (ref.watch(currentUserProvider)?.isTenantAdmin ?? false)
                bracketAsync.maybeWhen(
                  data: (bracket) => bracket != null
                      ? IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          tooltip: 'Reiniciar Cuadro',
                          onPressed: () => _handleResetBracket(context, ref),
                        )
                      : const SizedBox.shrink(),
                  orElse: () => const SizedBox.shrink(),
                ),
            ],
          ),
          body: bracketAsync.when(
            data: (bracket) {
              if (bracket == null || bracket.matches.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.account_tree_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        bracket == null
                            ? 'El cuadro no ha sido generado'
                            : 'El cuadro está vacío',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          context.pop();
                        },
                        child: const Text('Volver al Torneo'),
                      ),
                    ],
                  ),
                );
              }
              return InteractiveViewer(
                constrained: false,
                boundaryMargin: const EdgeInsets.all(100),
                minScale: 0.1,
                maxScale: 2.0,
                child: BracketTreeWidget(
                  bracket: bracket,
                  onMatchTap: (match) async {
                    final isBye =
                        match.player1Id == null || match.player2Id == null;
                    if (isBye && match.winnerId != null) {
                      final nextMatch = match.nextMatchId != null
                          ? bracket.matches
                                .where((m) => m.id == match.nextMatchId)
                                .firstOrNull
                          : null;

                      final alreadyAdvanced =
                          nextMatch != null &&
                          (nextMatch.player1Id == match.winnerId ||
                              nextMatch.player2Id == match.winnerId);

                      if (alreadyAdvanced) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Este avance por BYE ya fue procesado.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                    }

                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (context) => TournamentMatchResultDialog(
                        match: match,
                        player1Name: match.player1Name,
                        player2Name: match.player2Name,
                      ),
                    );

                    if (result != null) {
                      setState(() => _isProcessing = true);
                      try {
                        await ref
                            .read(
                              bracketProvider(
                                widget.tournamentId,
                                widget.categoryId,
                              ).notifier,
                            )
                            .recordMatchResult(
                              matchId: match.id,
                              winnerId: result['winnerId'] as String,
                              score: result['score'] as String,
                            );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Resultado registrado exitosamente',
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isProcessing = false);
                        }
                      }
                    }
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) {
              debugPrint('BracketView Error: $error');

              String errorMessage = error.toString();
              bool isNotFound = false;

              if (error is NetworkException &&
                  error.code == 'SERVER_ERROR_404') {
                isNotFound = true;
                errorMessage = 'El cuadro no existe para esta categoría.';
              } else if (error.toString().contains('404')) {
                isNotFound = true;
                errorMessage = 'El cuadro no existe para esta categoría.';
              }

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isNotFound
                          ? Icons.content_paste_off
                          : Icons.error_outline,
                      size: 48,
                      color: isNotFound ? Colors.orange : Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isNotFound ? 'Bracket no encontrado' : 'Error al cargar',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(errorMessage),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(
                          bracketProvider(
                            widget.tournamentId,
                            widget.categoryId,
                          ),
                        );
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (_isProcessing)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Procesando resultado...',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Estamos actualizando el cuadro',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _handleResetBracket(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Reiniciar Cuadro?'),
        content: const Text(
          'Esta acción eliminará el cuadro actual y todos sus enfrentamientos. '
          'Solo podrás hacerlo si no hay resultados registrados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('REINICIAR'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);
      try {
        await ref
            .read(
              bracketProvider(widget.tournamentId, widget.categoryId).notifier,
            )
            .deleteBracket();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cuadro reiniciado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          // Volver a la pantalla anterior ya que el cuadro ya no existe
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }
}
