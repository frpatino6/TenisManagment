import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/models/booking_model.dart';
import '../providers/student_provider.dart';
import '../../../shared/domain/strategies/status_color_strategy_factory.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  final _statusStrategy =
      StatusColorStrategyFactory.getStrategy(StatusType.booking);
  late TabController _tabController;
  String? _serviceTypeFilter;
  String? _lastRouteName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    final currentRouteName = route?.settings.name;

    if (route != null &&
        route.isCurrent &&
        currentRouteName != null &&
        currentRouteName != _lastRouteName) {
      _lastRouteName = currentRouteName;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.invalidate(upcomingBookingsProvider(
            _serviceTypeFilter == 'classes' ? null : _serviceTypeFilter,
          ));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.myBookings,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(upcomingBookingsProvider(
                _serviceTypeFilter == 'classes' ? null : _serviceTypeFilter,
              ));
              if (_tabController.index == 1) {
                ref.invalidate(bookingHistoryProvider(
                  _serviceTypeFilter == 'classes' ? null : _serviceTypeFilter,
                ));
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(),
          onTap: (index) {
            if (index == 1 && _tabController.previousIndex == 0) {
              ref.read(bookingHistoryProvider(_serviceTypeFilter));
            }
          },
          tabs: const [
            Tab(
              icon: Icon(Icons.calendar_today, size: 20),
              text: 'Próximas',
            ),
            Tab(
              icon: Icon(Icons.history, size: 20),
              text: 'Historial',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildUpcomingTab() {
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: ref
              .watch(upcomingBookingsProvider(
                _serviceTypeFilter == 'classes' ? null : _serviceTypeFilter,
              ))
              .when(
                data: (bookings) {
                  final filteredBookings =
                      _filterBookingsByServiceType(bookings, _serviceTypeFilter);
                  if (filteredBookings.isEmpty) {
                    return EmptyStateWidget.booking(
                      action: ElevatedButton.icon(
                        onPressed: () => context.push('/book-class'),
                        icon: const Icon(Icons.book_online),
                        label: Text(AppStrings.bookClass),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    );
                  }
                  return _buildUpcomingList(filteredBookings);
                },
                loading: () => const LoadingWidget(),
                error: (error, stack) => AppErrorWidget.fromError(
                  error,
                  onRetry: () => ref.invalidate(upcomingBookingsProvider(
                        _serviceTypeFilter == 'classes'
                            ? null
                            : _serviceTypeFilter,
                      )),
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: ref
              .watch(bookingHistoryProvider(
                _serviceTypeFilter == 'classes' ? null : _serviceTypeFilter,
              ))
              .when(
                data: (bookings) {
                  final filteredBookings =
                      _filterBookingsByServiceType(bookings, _serviceTypeFilter);
                  if (filteredBookings.isEmpty) {
                    return const Center(
                      child: Text('No hay reservas en el historial'),
                    );
                  }
                  return _buildHistoryList(filteredBookings);
                },
                loading: () => const LoadingWidget(),
                error: (error, stack) => AppErrorWidget.fromError(
                  error,
                  onRetry: () =>
                      ref.invalidate(bookingHistoryProvider(_serviceTypeFilter)),
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Todas', null),
            const Gap(8),
            _buildFilterChip('Clases', 'classes'),
            const Gap(8),
            _buildFilterChip('Canchas', 'court_rental'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _serviceTypeFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _serviceTypeFilter = selected ? value : null;
        });
        ref.invalidate(upcomingBookingsProvider(_serviceTypeFilter));
        if (_tabController.index == 1) {
          ref.invalidate(bookingHistoryProvider(_serviceTypeFilter));
        }
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }

  List<BookingModel> _filterBookingsByServiceType(
    List<BookingModel> bookings,
    String? filter,
  ) {
    if (filter == null) {
      return bookings;
    }
    if (filter == 'classes') {
      return bookings
          .where((b) =>
              b.serviceType == 'individual_class' ||
              b.serviceType == 'group_class')
          .toList();
    }
    return bookings.where((b) => b.serviceType == filter).toList();
  }

  Widget _buildUpcomingList(List<BookingModel> bookings) {
    final now = DateTime.now();
    final endOfWeek = now.add(Duration(days: 7 - now.weekday));
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfWeekDate = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day);

    final thisWeekBookings = <BookingModel>[];
    final laterBookings = <BookingModel>[];

    for (final booking in bookings) {
      final startTime = DateTime.parse(booking.schedule.startTime);
      final bookingDate = DateTime(startTime.year, startTime.month, startTime.day);

      if (bookingDate.isAfter(endOfWeekDate)) {
        laterBookings.add(booking);
      } else if (bookingDate.compareTo(startOfWeekDate) >= 0 &&
          bookingDate.compareTo(endOfWeekDate) <= 0) {
        thisWeekBookings.add(booking);
      } else {
        laterBookings.add(booking);
      }
    }

    thisWeekBookings.sort((a, b) {
      final dateA = DateTime.parse(a.schedule.startTime);
      final dateB = DateTime.parse(b.schedule.startTime);
      return dateA.compareTo(dateB);
    });

    laterBookings.sort((a, b) {
      final dateA = DateTime.parse(a.schedule.startTime);
      final dateB = DateTime.parse(b.schedule.startTime);
      return dateA.compareTo(dateB);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (thisWeekBookings.isNotEmpty) ...[
            _buildSectionHeader(context, 'Esta Semana', thisWeekBookings.length),
            const Gap(12),
            ...thisWeekBookings.map(
              (booking) => _buildUpcomingCard(context, booking),
            ),
            const Gap(24),
          ],
          if (laterBookings.isNotEmpty) ...[
            _buildSectionHeader(context, 'Más adelante', laterBookings.length),
            const Gap(12),
            ...laterBookings.map(
              (booking) => _buildUpcomingCard(context, booking),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<BookingModel> bookings) {
    final sortedBookings = List<BookingModel>.from(bookings)
      ..sort((a, b) {
        final dateA = DateTime.parse(a.schedule.startTime);
        final dateB = DateTime.parse(b.schedule.startTime);
        return dateB.compareTo(dateA);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedBookings.length,
      itemBuilder: (context, index) {
        return _buildHistoryCard(context, sortedBookings[index]);
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const Gap(8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingCard(BuildContext context, BookingModel booking) {
    final startTime = DateTime.parse(booking.schedule.startTime);
    final endTime = DateTime.parse(booking.schedule.endTime);
    final isToday = startTime.day == DateTime.now().day &&
        startTime.month == DateTime.now().month &&
        startTime.year == DateTime.now().year;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _statusStrategy.getColor(booking.status),
                    shape: BoxShape.circle,
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    booking.professor.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'HOY',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
              ],
            ),
            const Gap(12),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const Gap(8),
                Text(
                  '${_formatTime(startTime)} - ${_formatTime(endTime)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Gap(16),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const Gap(8),
                Text(
                  _formatDate(startTime),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const Gap(8),
            Row(
              children: [
                Icon(
                  Icons.sports_tennis,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const Gap(8),
                Text(
                  _getServiceTypeText(booking.serviceType),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  CurrencyUtils.format(booking.price),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            if (booking.court != null) ...[
              const Gap(8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const Gap(8),
                  Text(
                    'Cancha: ${booking.court!.name}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ],
            if (booking.status == 'confirmed' || booking.status == 'pending') ...[
              const Gap(16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showCancelDialog(context, booking),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showBookingDetails(context, booking),
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Detalles'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, BookingModel booking) {
    final startTime = DateTime.parse(booking.schedule.startTime);
    final endTime = DateTime.parse(booking.schedule.endTime);
    final statusColor = _statusStrategy.getColor(booking.status);
    final statusLabel = _statusStrategy.getLabel(booking.status);
    final statusIcon = _getStatusIcon(booking.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: InkWell(
        onTap: () => _showBookingDetails(context, booking),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const Gap(4),
                        Text(
                          statusLabel,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const Gap(4),
                    Text(
                      booking.professor.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Gap(4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const Gap(4),
                        Text(
                          '${_formatDate(startTime)} • ${_formatTime(startTime)} - ${_formatTime(endTime)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const Gap(4),
                    Row(
                      children: [
                        Icon(
                          Icons.sports_tennis,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const Gap(4),
                        Text(
                          _getServiceTypeText(booking.serviceType),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (booking.court != null) ...[
                          const Gap(8),
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const Gap(4),
                          Text(
                            booking.court!.name,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyUtils.format(booking.price),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const Gap(4),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.info;
    }
  }

  String _getServiceTypeText(String serviceType) {
    switch (serviceType) {
      case 'individual_class':
        return 'Clase Individual';
      case 'group_class':
        return 'Clase Grupal';
      case 'court_rental':
        return 'Alquiler de Cancha';
      default:
        return serviceType;
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookingDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (bookingDate == today) {
      return 'Hoy';
    } else if (bookingDate == today.add(const Duration(days: 1))) {
      return 'Mañana';
    } else if (bookingDate == today.subtract(const Duration(days: 1))) {
      return 'Ayer';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showCancelDialog(BuildContext context, BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Reserva'),
        content: Text(
          '¿Estás seguro de que quieres cancelar tu clase con ${booking.professor.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelBooking(booking);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }

  void _showBookingDetails(BuildContext context, BookingModel booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles de la Reserva'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Profesor', booking.professor.name),
            _buildDetailRow(
              'Servicio',
              _getServiceTypeText(booking.serviceType),
            ),
            _buildDetailRow(
              'Fecha',
              _formatDate(DateTime.parse(booking.schedule.startTime)),
            ),
            _buildDetailRow(
              'Hora',
              '${_formatTime(DateTime.parse(booking.schedule.startTime))} - ${_formatTime(DateTime.parse(booking.schedule.endTime))}',
            ),
            _buildDetailRow('Precio', CurrencyUtils.format(booking.price)),
            _buildDetailRow('Estado', _statusStrategy.getLabel(booking.status)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _cancelBooking(BookingModel booking) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de cancelación en desarrollo'),
      ),
    );
  }
}
