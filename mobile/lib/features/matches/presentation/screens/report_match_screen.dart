import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../ranking/domain/models/user_ranking.dart';
import '../providers/match_providers.dart';

class ReportMatchScreen extends ConsumerStatefulWidget {
  final UserRanking opponent;

  const ReportMatchScreen({super.key, required this.opponent});

  @override
  ConsumerState<ReportMatchScreen> createState() => _ReportMatchScreenState();
}

class _ReportMatchScreenState extends ConsumerState<ReportMatchScreen> {
  bool _iWon = true;
  bool _isTournament = false;
  bool _isOffPeak = false;

  final _scoreController = TextEditingController();

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final score = _scoreController.text.trim();
    if (score.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa el marcador (ej: 6-2, 6-4)'),
        ),
      );
      return;
    }

    final winnerId = _iWon ? 'CURRENT_USER' : widget.opponent.userId;
    final loserId = _iWon ? widget.opponent.userId : 'CURRENT_USER';

    await ref
        .read(recordMatchActionProvider.notifier)
        .execute(
          winnerId: winnerId,
          loserId: loserId,
          score: score,
          isTournament: _isTournament,
          isOffPeak: _isOffPeak,
        );

    final state = ref.read(recordMatchActionProvider);
    if (!mounted) return;

    if (state.hasError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${state.error}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resultado registrado exitosamente')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordMatchActionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Reportar Resultado'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: widget.opponent.avatarUrl != null
                        ? NetworkImage(widget.opponent.avatarUrl!)
                        : null,
                    child: widget.opponent.avatarUrl == null
                        ? Text(widget.opponent.name[0])
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Oponente',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          widget.opponent.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '¿Quién ganó?',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ChoiceCard(
                    label: 'Yo gané',
                    selected: _iWon,
                    onTap: () => setState(() => _iWon = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ChoiceCard(
                    label: 'Perdí',
                    selected: !_iWon,
                    onTap: () => setState(() => _iWon = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Marcador (Sets/Games)',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _scoreController,
              autofocus: false,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ej: 6-2, 6-4 o 6-7, 6-3, 10-8',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text(
                '¿Fue en horario valle?',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Otorga puntos extra en La Raza',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              value: _isOffPeak,
              activeTrackColor: const Color(0xFFCCFF00),
              activeThumbColor: Colors.black, // thumb color
              onChanged: (val) => setState(() => _isOffPeak = val),
            ),
            SwitchListTile(
              title: const Text(
                '¿Es de Torneo?',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Multiplica x2.5 los puntos',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              value: _isTournament,
              activeTrackColor: const Color(0xFFCCFF00),
              activeThumbColor: Colors.black, // thumb color
              onChanged: (val) => setState(() => _isTournament = val),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: recordingState.isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCCFF00),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: recordingState.isLoading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text(
                      'Confirmar Resultado',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFCCFF00) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFCCFF00) : Colors.white10,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
