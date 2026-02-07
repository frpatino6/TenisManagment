import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../preferences/domain/models/user_preferences_model.dart';
import '../../../student/presentation/providers/student_provider.dart';
import '../../../student/domain/models/booking_model.dart';

/// Widget to display favorite professor card in home screen
/// Shows professor info, next class (if any), and action buttons
class FavoriteProfessorCard extends ConsumerWidget {
  final FavoriteProfessor professor;

  const FavoriteProfessorCard({super.key, required this.professor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bookingsAsync = ref.watch(studentBookingsProvider);

    // Find next upcoming class with this professor
    BookingModel? nextClass = bookingsAsync.maybeWhen(
      data: (bookings) {
        final now = DateTime.now();
        return bookings
            .where(
              (b) =>
                  b.professor.id == professor.id &&
                  b.status != 'cancelled' &&
                  b.status != 'completed',
            )
            .map((b) {
              try {
                final startTime = DateTime.parse(b.schedule.startTime);
                return startTime.isAfter(now) ? b : null;
              } catch (e) {
                return null;
              }
            })
            .whereType<BookingModel>()
            .fold<BookingModel?>(null, (prev, current) {
              if (prev == null) return current;
              try {
                final prevTime = DateTime.parse(prev.schedule.startTime);
                final currentTime = DateTime.parse(current.schedule.startTime);
                return currentTime.isBefore(prevTime) ? current : prev;
              } catch (e) {
                return prev;
              }
            });
      },
      orElse: () => null,
    );

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Navigate to professor schedules
          context.push(
            '/professor/${professor.id}/schedules?name=${professor.name}',
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer,
                colorScheme.primaryContainer.withValues(alpha: 0.7),
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary.withValues(alpha: 0.2),
                    ),
                    child: Center(
                      child: Text(
                        professor.name.isNotEmpty
                            ? professor.name[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.favorite,
                              color: colorScheme.error,
                              size: 18,
                            ),
                            const Gap(4),
                            Text(
                              'Profesor Favorito',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                        const Gap(4),
                        Text(
                          professor.name,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        if (professor.specialties.isNotEmpty) ...[
                          const Gap(4),
                          Text(
                            professor.specialties.join(', '),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: colorScheme.onPrimaryContainer.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      color: colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                    onPressed: () {
                      context.push(
                        '/professor/${professor.id}/schedules?name=${professor.name}',
                      );
                    },
                  ),
                ],
              ),
              // Next class info
              if (nextClass != null) ...[
                const Gap(16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      const Gap(8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Próxima clase',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onPrimaryContainer
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            const Gap(2),
                            Text(
                              _formatNextClassDate(nextClass),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Gap(16),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.push(
                          '/professor/${professor.id}/schedules?name=${professor.name}',
                        );
                      },
                      icon: const Icon(Icons.schedule, size: 18),
                      label: Text(
                        'Ver horarios',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push(
                          '/professor/${professor.id}/schedules?name=${professor.name}',
                        );
                      },
                      icon: const Icon(Icons.book_online, size: 18),
                      label: Text(
                        'Reservar ahora',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  String _formatNextClassDate(BookingModel booking) {
    try {
      final startTime = DateTime.parse(booking.schedule.startTime);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final classDate = DateTime(
        startTime.year,
        startTime.month,
        startTime.day,
      );

      if (classDate == today) {
        return 'Hoy ${DateFormat('HH:mm').format(startTime)}';
      } else if (classDate == today.add(const Duration(days: 1))) {
        return 'Mañana ${DateFormat('HH:mm').format(startTime)}';
      } else {
        return DateFormat('EEE d MMM, HH:mm', 'es').format(startTime);
      }
    } catch (e) {
      return 'Próximamente';
    }
  }
}
