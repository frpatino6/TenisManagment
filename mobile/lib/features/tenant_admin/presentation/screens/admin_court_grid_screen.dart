import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../domain/models/tenant_booking_model.dart';
import '../../domain/models/tenant_config_model.dart';
import '../../domain/models/tenant_court_model.dart';
import '../../domain/models/tenant_debt_report_model.dart';
import '../providers/tenant_admin_provider.dart';
import '../utils/tenant_booking_actions.dart';

class AdminCourtGridScreen extends ConsumerStatefulWidget {
  const AdminCourtGridScreen({super.key});

  @override
  ConsumerState<AdminCourtGridScreen> createState() =>
      _AdminCourtGridScreenState();
}

class _AdminCourtGridScreenState extends ConsumerState<AdminCourtGridScreen> {
  // Layout constants (sidebar +15% for longer court names)
  static const double _courtLabelWidth = 100;
  static const double _rowHeight = 64;
  static const double _pixelsPerHour = 80;

  static const int _defaultFirstHour = 6;
  static const int _defaultLastHour = 24;

  (int, int) _hoursForDate(DateTime date, TenantConfigModel? tenant) {
    int openH = _defaultFirstHour, closeH = _defaultLastHour;
    final oh = tenant?.config?.operatingHours;
    if (oh != null) {
      if (oh.schedule != null && oh.schedule!.isNotEmpty) {
        final dartWeekday = date.weekday;
        final modelDay = dartWeekday == 7 ? 0 : dartWeekday;
        final daySchedule = oh.schedule!
            .where((s) => s.dayOfWeek == modelDay)
            .toList();
        if (daySchedule.isNotEmpty) {
          final ds = daySchedule.first;
          final o = _parseHHmm(ds.open);
          final c = _parseHHmm(ds.close);
          openH = o.$1;
          closeH = c.$1;
        }
      } else if (oh.open != null && oh.close != null) {
        final o = _parseHHmm(oh.open!);
        final c = _parseHHmm(oh.close!);
        openH = o.$1;
        closeH = c.$1;
      }
    }
    return (openH, closeH);
  }

  (int, int) _parseHHmm(String s) {
    final parts = s.split(':');
    return (
      int.tryParse(parts[0]) ?? 0,
      parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
  }

  // Premium color palette
  static const Color _darkBackground = Color(0xFF0F1115);
  static const Color _cardBackground = Color(0xFF1C1F26);
  static const Color _emeraldGreen = Color(0xFF10B981);
  static const Color _vibrantOrange = Color(0xFFF59E0B);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _currentTimeCyan = Color(0xFF00E5FF);

  static const TextStyle _courtNameStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  late DateTime _selectedDate;
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final GlobalKey _scrollContentKey = GlobalKey();
  double _horizontalOffset = 0;
  double _verticalOffset = 0;
  String? _draggingBookingId;
  double _dragStartTimelineX = 0;
  double _dragDeltaX = 0;
  bool _justFinishedDrag = false;
  String? _reschedulingBookingId;
  double _rescheduleOffsetX = 0;
  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _horizontalController.addListener(_onScroll);
    _verticalController.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() {
      _horizontalOffset = _horizontalController.offset;
      _verticalOffset = _verticalController.offset;
    });
  }

  double? _globalToTimelineX(Offset global) {
    final box =
        _scrollContentKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final local = box.globalToLocal(global);
    return local.dx - _courtLabelWidth;
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (_draggingBookingId == null) return;
    final timelineX = _globalToTimelineX(e.position);
    if (timelineX == null) return;
    setState(() => _dragDeltaX = timelineX - _dragStartTimelineX);

    if (!_horizontalController.hasClients) return;
    final pos = _horizontalController.position;
    const margin = 60.0;
    const step = 20.0;
    final contentX = timelineX + _courtLabelWidth;
    final vLeft = pos.pixels;
    final vRight = pos.pixels + pos.viewportDimension;

    double? target;
    if (contentX > vRight - margin) {
      target = (pos.pixels + step).clamp(0.0, pos.maxScrollExtent);
    } else if (contentX < vLeft + margin) {
      target = (pos.pixels - step).clamp(0.0, pos.maxScrollExtent);
    }
    if (target != null && (target - pos.pixels).abs() > 1) {
      final scrollDelta = target - pos.pixels;
      _horizontalController.jumpTo(target);
      setState(() => _dragDeltaX += scrollDelta);
    }
  }

  @override
  void dispose() {
    _horizontalController.removeListener(_onScroll);
    _verticalController.removeListener(_onScroll);
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  double _timelineWidth(int firstHour, int lastHour) =>
      (lastHour - firstHour) * _pixelsPerHour;

  List<TenantBookingModel> _bookingsForCourt(
    List<TenantBookingModel> bookings,
    TenantCourtModel court,
  ) {
    return bookings
        .where(
          (b) =>
              b.court?.id == court.id &&
              b.startTime != null &&
              b.endTime != null &&
              b.status != 'cancelled',
        )
        .toList();
  }

  double _leftForTime(DateTime time, int firstHour) {
    final hour = time.hour + time.minute / 60.0 + time.second / 3600.0;
    return (hour - firstHour) * _pixelsPerHour;
  }

  double _widthForDuration(DateTime start, DateTime end) {
    final hours = end.difference(start).inMinutes / 60.0;
    return (hours * _pixelsPerHour).clamp(24.0, double.infinity);
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  double? _currentTimeX(int firstHour, int lastHour) {
    if (!_isToday) return null;
    final now = DateTime.now();
    final hour = now.hour + now.minute / 60.0;
    if (hour < firstHour || hour >= lastHour) return null;
    return (hour - firstHour) * _pixelsPerHour;
  }

  Set<String> _debtorStudentIds(AsyncValue<TenantDebtReportModel> debtAsync) {
    return debtAsync.when(
      data: (d) => d.debtors
          .where((x) => x.totalDebt > 0)
          .map((x) => x.studentId)
          .toSet(),
      loading: () => <String>{},
      error: (_, __) => <String>{},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gridDataAsync = ref.watch(adminCourtGridDataProvider(_selectedDate));
    final debtAsync = ref.watch(debtReportProvider);
    final tenantAsync = ref.watch(tenantInfoProvider);
    final tenant = tenantAsync.whenOrNull(data: (d) => d);
    final (firstHour, lastHour) = _hoursForDate(_selectedDate, tenant);
    final debtorIds = _debtorStudentIds(debtAsync);

    return Scaffold(
      backgroundColor: _darkBackground,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          'Vista Canchas',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, size: 20),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
        ],
      ),
      body: gridDataAsync.when(
        data: (data) =>
            _buildBody(context, data, debtorIds, firstHour, lastHour),
        loading: () =>
            const LoadingWidget(message: 'Cargando canchas y reservas...'),
        error: (err, st) => AppErrorWidget.fromError(
          err,
          onRetry: () =>
              ref.invalidate(adminCourtGridDataProvider(_selectedDate)),
        ),
      ),
      floatingActionButton: gridDataAsync.maybeWhen(
        data: (data) => data.courts.isNotEmpty
            ? FloatingActionButton(
                onPressed: () {
                  // Use first court and current time as defaults
                  final now = DateTime.now();
                  final roundedMinute = now.minute < 30 ? 0 : 30;
                  final startHour = roundedMinute == 30
                      ? now.hour
                      : (now.minute > 0 ? now.hour + 1 : now.hour);
                  final startTime = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    startHour,
                    roundedMinute,
                  );

                  context.push(
                    '/tenant-admin-home/bookings/create',
                    extra: {
                      'courtId': data.courts.first.id,
                      'courtName': data.courts.first.name,
                      'courtPrice': data.courts.first.price,
                      'date': _selectedDate,
                      'startTime': startTime,
                    },
                  );
                },
                backgroundColor: _emeraldGreen,
                foregroundColor: Colors.white,
                elevation: 4,
                child: const Icon(Icons.add, size: 24),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AdminCourtGridData data,
    Set<String> debtorIds,
    int firstHour,
    int lastHour,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminCourtGridDataProvider(_selectedDate));
        ref.invalidate(debtReportProvider);
        ref.invalidate(tenantInfoProvider);
      },
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendBar(),
              Expanded(
                child: _buildScrollableGrid(
                  data,
                  debtorIds,
                  firstHour,
                  lastHour,
                ),
              ),
            ],
          ),
          _buildStickyTopBar(data, firstHour, lastHour),
          _buildStickyLeftBar(data, firstHour, lastHour),
        ],
      ),
    );
  }

  void _scrollToNow() {
    setState(() => _selectedDate = DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_horizontalController.hasClients) return;
      final tenant = ref.read(tenantInfoProvider).whenOrNull(data: (d) => d);
      final (firstHour, lastHour) = _hoursForDate(_selectedDate, tenant);
      final x = _currentTimeX(firstHour, lastHour);
      if (x == null) return;
      final target = (x - 80).clamp(
        0.0,
        _horizontalController.position.maxScrollExtent,
      );
      _horizontalController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Widget _buildLegendBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SizedBox(
      height: _legendBarHeight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              DateFormat('EEEE d MMM', 'es').format(_selectedDate),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (_isToday)
              TextButton.icon(
                onPressed: _scrollToNow,
                icon: Icon(Icons.today, size: 16, color: colorScheme.primary),
                label: Text(
                  'Hoy',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            const Gap(12),
            _legendChip(_emeraldGreen, 'Pago', colorScheme),
            const Gap(8),
            _legendChip(_vibrantOrange, 'Pendiente', colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _legendChip(Color color, String label, ColorScheme colorScheme) {
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Gap(6),
          Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                height: 1.2,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableGrid(
    AdminCourtGridData data,
    Set<String> debtorIds,
    int firstHour,
    int lastHour,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final timelineW = _timelineWidth(firstHour, lastHour);
    final currentX = _currentTimeX(firstHour, lastHour);
    return NotificationListener<ScrollNotification>(
      onNotification: (_) {
        setState(() {});
        return false;
      },
      child: SingleChildScrollView(
        controller: _verticalController,
        child: SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          child: Listener(
            key: _scrollContentKey,
            onPointerMove: _onPointerMove,
            behavior: HitTestBehavior.translucent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: _courtLabelWidth,
                  top: _rowHeight,
                  width: timelineW,
                  height: data.courts.length * _rowHeight,
                  child: CustomPaint(
                    size: Size(timelineW, data.courts.length * _rowHeight),
                    painter: _HourGuidesPainter(
                      pixelsPerHour: _pixelsPerHour,
                      hourCount: lastHour - firstHour,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHourHeader(colorScheme, firstHour, lastHour),
                    ...List.generate(data.courts.length, (i) {
                      return _buildCourtLane(
                        data.courts[i],
                        _bookingsForCourt(data.bookings, data.courts[i]),
                        i,
                        data.courts,
                        data.bookings,
                        debtorIds,
                        theme,
                        colorScheme,
                        firstHour,
                        lastHour,
                      );
                    }),
                  ],
                ),
                if (currentX != null)
                  Positioned(
                    left: _courtLabelWidth + currentX - 1,
                    top: _rowHeight,
                    width: 2,
                    height: data.courts.length * _rowHeight,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          color: _currentTimeCyan.withValues(alpha: 0.8),
                          boxShadow: [
                            BoxShadow(
                              color: _currentTimeCyan.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHourHeader(
    ColorScheme colorScheme,
    int firstHour,
    int lastHour,
  ) {
    final timelineW = _timelineWidth(firstHour, lastHour);
    return SizedBox(
      height: _rowHeight,
      width: _courtLabelWidth + timelineW,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _courtLabelWidth,
            child: Container(
              color: colorScheme.surface,
              alignment: Alignment.center,
              child: Text(
                'Cancha',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Positioned(
            left: _courtLabelWidth,
            top: 0,
            bottom: 0,
            right: 0,
            child: Row(
              children: List.generate(lastHour - firstHour, (i) {
                final hour = firstHour + i;
                return SizedBox(
                  width: _pixelsPerHour,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourtLane(
    TenantCourtModel court,
    List<TenantBookingModel> bookings,
    int courtIndex,
    List<TenantCourtModel> courts,
    List<TenantBookingModel> allBookings,
    Set<String> debtorIds,
    ThemeData theme,
    ColorScheme colorScheme,
    int firstHour,
    int lastHour,
  ) {
    final timelineW = _timelineWidth(firstHour, lastHour);
    return SizedBox(
      height: _rowHeight,
      width: _courtLabelWidth + timelineW,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: _courtLabelWidth,
            child: Container(
              color: colorScheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              child: Text(
                court.name,
                style: _courtNameStyle.copyWith(color: colorScheme.onSurface),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Positioned(
            left: _courtLabelWidth,
            top: 0,
            bottom: 0,
            width: timelineW,
            child: _buildTimelineLane(
              court,
              bookings,
              courtIndex,
              courts,
              allBookings,
              debtorIds,
              theme,
              colorScheme,
              firstHour,
              lastHour,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineLane(
    TenantCourtModel court,
    List<TenantBookingModel> bookings,
    int courtIndex,
    List<TenantCourtModel> courts,
    List<TenantBookingModel> allBookings,
    Set<String> debtorIds,
    ThemeData theme,
    ColorScheme colorScheme,
    int firstHour,
    int lastHour,
  ) {
    final timelineW = _timelineWidth(firstHour, lastHour);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          size: Size(timelineW, _rowHeight),
          painter: _TimelineGridPainter(
            firstHour: firstHour,
            lastHour: lastHour,
            pixelsPerHour: _pixelsPerHour,
            gridLineColor: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        _buildEmptyLaneTapTarget(court, colorScheme, firstHour, lastHour),
        ...bookings.map(
          (b) => _buildBookingPill(
            b,
            court,
            courtIndex,
            courts,
            allBookings,
            bookings,
            debtorIds.contains(b.student.id),
            theme,
            colorScheme,
            firstHour,
            lastHour,
          ),
        ),
      ],
    );
  }

  String _initialFromName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final first = trimmed[0].toUpperCase();
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return '${first}${parts[1][0].toUpperCase()}';
    }
    return first;
  }

  static bool _isValidDisplayName(String name) {
    final t = name.trim();
    if (t.isEmpty) return false;
    if (t.contains('FontWeight') || t.contains('TextStyle') || t.length > 80) {
      return false;
    }
    return true;
  }

  String _studentDisplayName(TenantBookingModel booking) {
    final n = booking.student.name;
    return _isValidDisplayName(n) ? n : 'Sin nombre';
  }

  bool _bookingsOverlap(DateTime a1, DateTime a2, DateTime b1, DateTime b2) {
    return a1.isBefore(b2) && b1.isBefore(a2);
  }

  Widget _buildBookingPill(
    TenantBookingModel booking,
    TenantCourtModel court,
    int courtIndex,
    List<TenantCourtModel> courts,
    List<TenantBookingModel> allBookings,
    List<TenantBookingModel> courtBookings,
    bool hasDebt,
    ThemeData theme,
    ColorScheme colorScheme,
    int firstHour,
    int lastHour,
  ) {
    final start = booking.startTime!;
    final end = booking.endTime!;
    final durationMinutes = end.difference(start).inMinutes;
    final baseLeft = _leftForTime(start, firstHour);
    final width = _widthForDuration(start, end);
    final isPaid = booking.paymentStatus == 'paid';
    final sidebarColor = isPaid ? _emeraldGreen : _vibrantOrange;
    final displayName = _studentDisplayName(booking);
    final initial = _initialFromName(displayName);
    final pillWidth = (width - 8).clamp(60.0, double.infinity);
    const pillRadius = 6.0;
    final showFullName = durationMinutes > 60 && pillWidth > 80;
    final padding = showFullName ? 8.0 : 4.0;
    final avatarRadius = showFullName ? 12.0 : 8.0;

    final isDragging = _draggingBookingId == booking.id;
    final isRescheduling = _reschedulingBookingId == booking.id;
    final left =
        baseLeft +
        4 +
        (isDragging ? _dragDeltaX : (isRescheduling ? _rescheduleOffsetX : 0));

    return Positioned(
      left: left,
      top: 4,
      bottom: 4,
      width: pillWidth,
      child: GestureDetector(
        onHorizontalDragStart: (_) {
          setState(() {
            _draggingBookingId = booking.id;
            _dragStartTimelineX = baseLeft + 4;
            _dragDeltaX = 0;
          });
        },
        onHorizontalDragUpdate: (_) {},
        onHorizontalDragEnd: (details) async {
          final totalDelta = _dragDeltaX;
          setState(() {
            _draggingBookingId = null;
            _dragDeltaX = 0;
            _reschedulingBookingId = booking.id;
            _rescheduleOffsetX = totalDelta;
            _justFinishedDrag = true;
          });
          Future.microtask(() {
            if (mounted) setState(() => _justFinishedDrag = false);
          });

          final hourOffset = totalDelta / _pixelsPerHour;
          final newStartHour = start.hour + start.minute / 60.0 + hourOffset;
          final newStartHourInt = newStartHour.floor();
          final newStartMinute = (newStartHour - newStartHourInt) * 60;
          final roundedMinute = newStartMinute < 30 ? 0 : 30;
          final newStart = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            newStartHourInt,
            roundedMinute,
          );
          final newEnd = newStart.add(Duration(minutes: durationMinutes));

          if (newStart.hour < firstHour ||
              (newEnd.hour > lastHour ||
                  (newEnd.hour == lastHour && newEnd.minute > 0))) {
            setState(() {
              _reschedulingBookingId = null;
              _rescheduleOffsetX = 0;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'El horario debe estar entre $firstHour:00 y $lastHour:00',
                  ),
                  backgroundColor: colorScheme.error,
                ),
              );
            }
            return;
          }

          final others = courtBookings
              .where((b) => b.id != booking.id)
              .toList();
          final hasOverlap = others.any((o) {
            final oStart = o.startTime!;
            final oEnd = o.endTime!;
            return _bookingsOverlap(newStart, newEnd, oStart, oEnd);
          });
          if (hasOverlap) {
            setState(() {
              _reschedulingBookingId = null;
              _rescheduleOffsetX = 0;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'No se puede superponer con otra reserva',
                  ),
                  backgroundColor: colorScheme.error,
                ),
              );
            }
            return;
          }

          try {
            await ref
                .read(tenantAdminRepositoryProvider)
                .rescheduleBooking(
                  booking.id,
                  startTime: newStart,
                  endTime: newEnd,
                );
            ref.invalidate(adminCourtGridDataProvider(_selectedDate));
            ref.invalidate(tenantBookingsProvider);
            await ref.read(adminCourtGridDataProvider(_selectedDate).future);
            if (mounted) {
              setState(() {
                _reschedulingBookingId = null;
                _rescheduleOffsetX = 0;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Reserva movida'),
                  backgroundColor: colorScheme.primary,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _reschedulingBookingId = null;
                _rescheduleOffsetX = 0;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}'),
                  backgroundColor: colorScheme.error,
                ),
              );
            }
          }
        },
        child: Material(
          color: Colors.transparent,
          elevation: 0,
          borderRadius: BorderRadius.circular(pillRadius),
          child: InkWell(
            onTap: () async {
              if (_draggingBookingId != null ||
                  _justFinishedDrag ||
                  _reschedulingBookingId != null)
                return;
              final refresh = await context.push<bool>(
                '/tenant-admin-home/bookings/${booking.id}',
                extra: {'gridDate': _selectedDate},
              );
              if (refresh == true && mounted) {
                ref.invalidate(adminCourtGridDataProvider(_selectedDate));
              }
            },
            onLongPress: () {
              if (_draggingBookingId != null ||
                  _justFinishedDrag ||
                  _reschedulingBookingId != null)
                return;
              _showBookingQuickActionsSheet(context, booking);
            },
            borderRadius: BorderRadius.circular(pillRadius),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(pillRadius),
                color: _cardBackground.withValues(alpha: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: sidebarColor,
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(pillRadius),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: showFullName
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: avatarRadius,
                                  backgroundColor: sidebarColor.withValues(
                                    alpha: 0.15,
                                  ),
                                  foregroundColor: sidebarColor,
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                SizedBox(width: padding),
                                Expanded(
                                  child: Text(
                                    displayName,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isPaid)
                                  Icon(
                                    Icons.lock_rounded,
                                    size: 14,
                                    color: _emeraldGreen,
                                  ),
                                if (booking.isConfirmed) ...[
                                  if (isPaid) const SizedBox(width: 4),
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 14,
                                    color: _emeraldGreen,
                                  ),
                                ],
                              ],
                            )
                          : Center(
                              child: CircleAvatar(
                                radius: avatarRadius,
                                backgroundColor: sidebarColor.withValues(
                                  alpha: 0.15,
                                ),
                                foregroundColor: sidebarColor,
                                child: Text(
                                  initial,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    fontSize: avatarRadius > 12 ? 12 : 10,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyLaneTapTarget(
    TenantCourtModel court,
    ColorScheme colorScheme,
    int firstHour,
    int lastHour,
  ) {
    const double iconSize = 14;
    const double padding = 6;
    const double hitRadius = 18.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (int h = firstHour; h < lastHour; h++) ...[
          Positioned(
            left:
                (h - firstHour) * _pixelsPerHour +
                _pixelsPerHour / 4 -
                (iconSize / 2 + padding),
            top: 0,
            bottom: 0,
            child: Center(
              child: _buildPlusButton(
                colorScheme,
                iconSize,
                padding,
                hitRadius,
                () => _openCreateBooking(court, h, 0),
              ),
            ),
          ),
          Positioned(
            left:
                (h - firstHour) * _pixelsPerHour +
                3 * _pixelsPerHour / 4 -
                (iconSize / 2 + padding),
            top: 0,
            bottom: 0,
            child: Center(
              child: _buildPlusButton(
                colorScheme,
                iconSize,
                padding,
                hitRadius,
                () => _openCreateBooking(court, h, 30),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlusButton(
    ColorScheme colorScheme,
    double iconSize,
    double padding,
    double hitRadius,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: onTap,
        radius: hitRadius,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.add,
            size: iconSize,
            color: colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateBooking(
    TenantCourtModel court,
    int hour,
    int minute,
  ) async {
    final slotStart = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
      minute,
    );
    final refresh = await context.push<bool>(
      '/tenant-admin-home/bookings/create',
      extra: {
        'courtId': court.id,
        'courtName': court.name,
        'courtPrice': court.price,
        'date': _selectedDate,
        'startTime': slotStart,
      },
    );
    if (refresh == true) {
      ref.invalidate(adminCourtGridDataProvider(_selectedDate));
    }
  }

  static const double _legendBarHeight = 48;

  Widget _buildStickyTopBar(
    AdminCourtGridData data,
    int firstHour,
    int lastHour,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showBar = _verticalOffset > 4;

    if (!showBar) return const SizedBox.shrink();

    return Positioned(
      top: _legendBarHeight,
      left: 0,
      right: 0,
      height: _rowHeight,
      child: IgnorePointer(
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.92),
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Transform.translate(
                offset: Offset(-_horizontalOffset, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: _courtLabelWidth,
                      height: _rowHeight,
                      child: Center(
                        child: Text(
                          'Cancha',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    ...List.generate(lastHour - firstHour, (i) {
                      final hour = firstHour + i;
                      return SizedBox(
                        width: _pixelsPerHour,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            '${hour.toString().padLeft(2, '0')}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStickyLeftBar(
    AdminCourtGridData data,
    int firstHour,
    int lastHour,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showBar = _horizontalOffset > 4;

    if (!showBar) return const SizedBox.shrink();

    return Positioned(
      top: _legendBarHeight,
      left: 0,
      bottom: 0,
      width: _courtLabelWidth,
      child: IgnorePointer(
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.92),
                border: Border(
                  right: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Transform.translate(
                offset: Offset(0, -_verticalOffset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: _rowHeight,
                      width: _courtLabelWidth,
                      child: Center(
                        child: Text(
                          'Cancha',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    ...data.courts.map(
                      (court) => SizedBox(
                        height: _rowHeight,
                        width: _courtLabelWidth,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              court.name,
                              style: _courtNameStyle.copyWith(
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBookingQuickActionsSheet(
    BuildContext context,
    TenantBookingModel booking,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Gap(12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _studentDisplayName(booking),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const Gap(4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _formatTimeRange(booking.startTime!, booking.endTime!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Gap(20),
            ListTile(
              leading: Icon(
                Icons.person_outline,
                color: colorScheme.onSurfaceVariant,
              ),
              title: const Text('Ver Perfil / Ranking'),
              onTap: () {
                Navigator.of(ctx).pop();
                context.push(
                  '/tenant-admin-home/students/${booking.student.id}',
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.account_balance_wallet,
                color: colorScheme.primary,
              ),
              title: const Text('Cobrar saldo'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await confirmBookingQuickPayment(ctx, ref, booking);
                if (context.mounted) {
                  ref.invalidate(adminCourtGridDataProvider(_selectedDate));
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: colorScheme.error),
              title: const Text('Borrar reserva'),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _showCancelBookingDialog(context, booking);
              },
            ),
            const Gap(24),
          ],
        ),
      ),
    );
  }

  Future<void> _showCancelBookingDialog(
    BuildContext context,
    TenantBookingModel booking,
  ) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final reasonController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Cancelar la reserva de ${_studentDisplayName(booking)}?',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            const Gap(12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            child: const Text('Cancelar reserva'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref
          .read(tenantAdminRepositoryProvider)
          .cancelBooking(
            booking.id,
            reason: reasonController.text.trim().isEmpty
                ? null
                : reasonController.text.trim(),
          );
      ref.invalidate(adminCourtGridDataProvider(_selectedDate));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reserva cancelada'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    return '${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}';
  }
}

class _TimelineGridPainter extends CustomPainter {
  final int firstHour;
  final int lastHour;
  final double pixelsPerHour;
  final Color gridLineColor;

  _TimelineGridPainter({
    required this.firstHour,
    required this.lastHour,
    required this.pixelsPerHour,
    required this.gridLineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = gridLineColor.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= lastHour - firstHour; i++) {
      final x = i * pixelsPerHour;
      if (x <= 0) continue;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HourGuidesPainter extends CustomPainter {
  final double pixelsPerHour;
  final int hourCount;
  final Color color;

  _HourGuidesPainter({
    required this.pixelsPerHour,
    required this.hourCount,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    for (int i = 0; i <= hourCount; i++) {
      final x = i * pixelsPerHour;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
