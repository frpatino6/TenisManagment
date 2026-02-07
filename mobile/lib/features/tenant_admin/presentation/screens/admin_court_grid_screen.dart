import 'dart:async';
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

class _PillDragContext {
  const _PillDragContext({
    required this.booking,
    required this.courtIndex,
    required this.courts,
    required this.allBookings,
    required this.courtBookings,
    required this.firstHour,
    required this.lastHour,
    required this.start,
    required this.durationMinutes,
  });
  final TenantBookingModel booking;
  final int courtIndex;
  final List<TenantCourtModel> courts;
  final List<TenantBookingModel> allBookings;
  final List<TenantBookingModel> courtBookings;
  final int firstHour;
  final int lastHour;
  final DateTime start;
  final int durationMinutes;
}

class AdminCourtGridScreen extends ConsumerStatefulWidget {
  const AdminCourtGridScreen({super.key});

  @override
  ConsumerState<AdminCourtGridScreen> createState() =>
      _AdminCourtGridScreenState();
}

class _AdminCourtGridScreenState extends ConsumerState<AdminCourtGridScreen> {
  static const double _courtLabelWidth = 100;
  static const double _rowHeight = 64;
  static const double kColumnWidth = 100.0;

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
  static const Color _emeraldGreen = Color(0xFF10B981);
  static const Color _vibrantOrange = Color(0xFFF59E0B);

  static const TextStyle _courtNameStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    height: 1.2,
  );

  late DateTime _selectedDate;
  Timer? _currentTimeTimer;
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final GlobalKey _scrollContentKey = GlobalKey();
  double _horizontalOffset = 0;
  double _verticalOffset = 0;
  String? _draggingBookingId;
  double _dragStartTimelineX = 0;
  double _dragStartContentY = 0;
  double _dragDeltaX = 0;
  double _dragDeltaY = 0;
  bool _justFinishedDrag = false;
  String? _reschedulingBookingId;
  double _rescheduleOffsetX = 0;
  double _rescheduleOffsetY = 0;
  int? _draggingPointerId;
  _PillDragContext? _pillDragContext;
  bool _dragMovedBeyondThreshold = false;
  bool? _dragLockedHorizontal;
  bool _hasAutoScrolledToNow = false;
  int? _dragHoverCourtIndex;
  int? _dragHoverSlotHour;
  int? _dragHoverSlotMinute;
  int _cachedFirstHour = 6;
  int _cachedLastHour = 24;
  int _cachedCourtCount = 0;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _horizontalController.addListener(_onScroll);
    _verticalController.addListener(_onScroll);
    _currentTimeTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _onScroll() {
    setState(() {
      _horizontalOffset = _horizontalController.offset;
      _verticalOffset = _verticalController.offset;
    });
  }

  (double?, double?) _globalToContentPosition(Offset global) {
    final box =
        _scrollContentKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return (null, null);
    final local = box.globalToLocal(global);
    return (local.dx - _courtLabelWidth, local.dy);
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (_draggingBookingId == null) return;
    final (timelineX, contentY) = _globalToContentPosition(e.position);
    if (timelineX == null || contentY == null) return;

    final rawDeltaX = timelineX - _dragStartTimelineX;
    final rawDeltaY = contentY - _dragStartContentY;
    final distanceSq = rawDeltaX * rawDeltaX + rawDeltaY * rawDeltaY;

    if (_dragLockedHorizontal == null &&
        distanceSq >= _dragThresholdPixels * _dragThresholdPixels) {
      _dragLockedHorizontal = rawDeltaX.abs() >= rawDeltaY.abs();
      _dragMovedBeyondThreshold = true;
    }

    int? hoverCourt;
    int? hoverHour;
    int? hoverMinute;
    if (timelineX >= 0 && contentY >= _rowHeight) {
      final hourIdx = (timelineX / kColumnWidth).floor();
      final courtIdx = ((contentY - _rowHeight) / _rowHeight).floor();
      if (hourIdx >= 0 &&
          hourIdx < _cachedLastHour - _cachedFirstHour &&
          courtIdx >= 0 &&
          courtIdx < _cachedCourtCount) {
        hoverCourt = courtIdx;
        hoverHour = _cachedFirstHour + hourIdx;
        hoverMinute = (timelineX % kColumnWidth) < kColumnWidth / 2 ? 0 : 30;
      }
    }
    setState(() {
      _dragDeltaX = rawDeltaX;
      _dragDeltaY = rawDeltaY;
      _dragHoverCourtIndex = hoverCourt;
      _dragHoverSlotHour = hoverHour;
      _dragHoverSlotMinute = hoverMinute;
      if (distanceSq >= _dragThresholdPixels * _dragThresholdPixels) {
        _dragMovedBeyondThreshold = true;
      }
    });

    final isHorizontal =
        _dragLockedHorizontal ?? (rawDeltaX.abs() >= rawDeltaY.abs());

    if (isHorizontal && _horizontalController.hasClients) {
      final pos = _horizontalController.position;
      const margin = 80.0;
      const step = 12.0;
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
        setState(() => _dragDeltaX = rawDeltaX + scrollDelta);
      }
    }

    if (!isHorizontal && _verticalController.hasClients) {
      final vPos = _verticalController.position;
      const vMargin = 60.0;
      const vStep = 20.0;
      final vTop = vPos.pixels;
      final vBottom = vPos.pixels + vPos.viewportDimension;
      double? vTarget;
      if (contentY < vTop + vMargin) {
        vTarget = (vPos.pixels - vStep).clamp(0.0, vPos.maxScrollExtent);
      } else if (contentY > vBottom - vMargin) {
        vTarget = (vPos.pixels + vStep).clamp(0.0, vPos.maxScrollExtent);
      }
      if (vTarget != null && (vTarget - vPos.pixels).abs() > 1) {
        final vScrollDelta = vTarget - vPos.pixels;
        _verticalController.jumpTo(vTarget);
        setState(() {
          _dragStartContentY += vScrollDelta;
          _dragDeltaY = rawDeltaY + vScrollDelta;
        });
      }
    }
  }

  static const double _dragThresholdPixels = 8;

  void _clearDragState() {
    setState(() {
      _draggingBookingId = null;
      _draggingPointerId = null;
      _pillDragContext = null;
      _dragDeltaX = 0;
      _dragDeltaY = 0;
      _dragMovedBeyondThreshold = false;
      _dragLockedHorizontal = null;
      _dragHoverCourtIndex = null;
      _dragHoverSlotHour = null;
      _dragHoverSlotMinute = null;
    });
  }

  void _onPointerUp(PointerUpEvent e) {
    if (_draggingBookingId == null ||
        _draggingPointerId == null ||
        e.pointer != _draggingPointerId)
      return;
    final distance = (_dragDeltaX * _dragDeltaX + _dragDeltaY * _dragDeltaY)
        .abs();
    if (distance < _dragThresholdPixels * _dragThresholdPixels) {
      _clearDragState();
      return;
    }
    _completeDrag();
  }

  void _onPointerCancel(PointerCancelEvent e) {
    if (_draggingBookingId == null ||
        _draggingPointerId == null ||
        e.pointer != _draggingPointerId)
      return;
    _clearDragState();
  }

  Future<void> _completeDrag() async {
    final ctx = _pillDragContext;
    if (ctx == null) return;
    final totalDeltaX = _dragDeltaX;
    final totalDeltaY = _dragDeltaY;
    _pillDragContext = null;
    _draggingBookingId = null;
    _draggingPointerId = null;
    setState(() {
      _dragDeltaX = 0;
      _dragDeltaY = 0;
      _reschedulingBookingId = ctx.booking.id;
      _rescheduleOffsetX = totalDeltaX;
      _rescheduleOffsetY = totalDeltaY;
      _justFinishedDrag = true;
    });
    Future.microtask(() {
      if (mounted) setState(() => _justFinishedDrag = false);
    });

    final targetCourtIndex =
        (ctx.courtIndex + (totalDeltaY / _rowHeight).round()).clamp(
          0,
          ctx.courts.length - 1,
        );
    final targetCourt = ctx.courts[targetCourtIndex];
    final changeCourt = targetCourtIndex != ctx.courtIndex;

    final hourOffset = totalDeltaX / kColumnWidth;
    final newStartHour = ctx.start.hour + ctx.start.minute / 60.0 + hourOffset;
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
    final newEnd = newStart.add(Duration(minutes: ctx.durationMinutes));

    if (newStart.hour < ctx.firstHour ||
        (newEnd.hour > ctx.lastHour ||
            (newEnd.hour == ctx.lastHour && newEnd.minute > 0))) {
      setState(() {
        _reschedulingBookingId = null;
        _rescheduleOffsetX = 0;
        _rescheduleOffsetY = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'El horario debe estar entre ${ctx.firstHour}:00 y ${ctx.lastHour}:00',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final bookingsToCheck = changeCourt
        ? _bookingsForCourt(ctx.allBookings, targetCourt)
        : ctx.courtBookings;
    final others = bookingsToCheck
        .where((b) => b.id != ctx.booking.id)
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
        _rescheduleOffsetY = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se puede superponer con otra reserva'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    try {
      await ref
          .read(tenantAdminRepositoryProvider)
          .rescheduleBooking(
            ctx.booking.id,
            startTime: newStart,
            endTime: newEnd,
            courtId: changeCourt ? targetCourt.id : null,
          );
      ref.invalidate(adminCourtGridDataProvider(_selectedDate));
      ref.invalidate(tenantBookingsProvider);
      await ref.read(adminCourtGridDataProvider(_selectedDate).future);
      if (mounted) {
        setState(() {
          _reschedulingBookingId = null;
          _rescheduleOffsetX = 0;
          _rescheduleOffsetY = 0;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              changeCourt
                  ? 'Reserva movida a ${targetCourt.name}'
                  : 'Reserva movida',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _reschedulingBookingId = null;
          _rescheduleOffsetX = 0;
          _rescheduleOffsetY = 0;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _currentTimeTimer?.cancel();
    _horizontalController.removeListener(_onScroll);
    _verticalController.removeListener(_onScroll);
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  double _timelineWidth(int firstHour, int lastHour) =>
      (lastHour - firstHour) * kColumnWidth;

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
    return (hour - firstHour) * kColumnWidth;
  }

  double _widthForDuration(DateTime start, DateTime end) {
    final hours = end.difference(start).inMinutes / 60.0;
    return (hours * kColumnWidth).clamp(24.0, double.infinity);
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
    if (lastHour <= firstHour) return 0.0;
    final rawX = (hour - firstHour) * kColumnWidth;
    final maxX = (lastHour - firstHour) * kColumnWidth;
    return rawX.clamp(0.0, maxX - 1);
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
        backgroundColor: Colors.transparent,
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
    );
  }

  Widget _buildBody(
    BuildContext context,
    AdminCourtGridData data,
    Set<String> debtorIds,
    int firstHour,
    int lastHour,
  ) {
    if (_isToday &&
        !_hasAutoScrolledToNow &&
        _currentTimeX(firstHour, lastHour) != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_horizontalController.hasClients) return;
        _hasAutoScrolledToNow = true;
        final x = _currentTimeX(firstHour, lastHour)!;
        final target = (x - kColumnWidth).clamp(
          0.0,
          _horizontalController.position.maxScrollExtent,
        );
        _horizontalController.animateTo(
          target,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      });
    }
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
              _buildLegendBar(data, firstHour, lastHour),
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
          Positioned(
            left: _courtLabelWidth,
            top: _headerSectionHeight(),
            bottom: 0,
            width: 1,
            child: IgnorePointer(child: Container(color: Colors.white10)),
          ),
          if (_currentTimeX(firstHour, lastHour) != null)
            Positioned(
              left:
                  _courtLabelWidth +
                  _currentTimeX(firstHour, lastHour)! -
                  _horizontalOffset -
                  3,
              top: _headerSectionHeight() + _rowHeight + 1,
              bottom: 0,
              width: 6,
              child: IgnorePointer(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 6,
                      color: Colors.cyanAccent.withValues(alpha: 0.1),
                    ),
                    Container(
                      width: 4,
                      color: Colors.cyanAccent.withValues(alpha: 0.3),
                    ),
                    Container(width: 2, color: Colors.cyanAccent),
                  ],
                ),
              ),
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
      final target = (x - kColumnWidth).clamp(
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

  double _computeOccupancy(
    List<TenantBookingModel> bookings,
    int courtCount,
    int firstHour,
    int lastHour,
  ) {
    if (courtCount == 0 || lastHour <= firstHour) return 0;
    final totalMinutes = courtCount * (lastHour - firstHour) * 60;
    var occupiedMinutes = 0;
    for (final b in bookings) {
      final s = b.startTime;
      final e = b.endTime;
      if (s == null || e == null) continue;
      final duration = e.difference(s).inMinutes;
      if (duration <= 0) continue;
      occupiedMinutes += duration;
    }
    if (totalMinutes <= 0) return 0;
    return (occupiedMinutes / totalMinutes * 100).clamp(0.0, 100.0);
  }

  Widget _buildLegendBar(AdminCourtGridData data, int firstHour, int lastHour) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final shrink = (_verticalOffset / 80).clamp(0.0, 1.0);
    final barHeight = _legendBarHeight * (1 - shrink * 0.35);
    final fontSize = 14.0 - (shrink * 3);
    final occupancy = _computeOccupancy(
      data.bookings,
      data.courts.length,
      firstHour,
      lastHour,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: Colors.transparent,
          child: Text(
            'Ocupación: ${occupancy.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: barHeight,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8 * (1 - shrink * 0.5),
            ),
            decoration: BoxDecoration(
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
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    fontSize: fontSize,
                  ),
                  child: Text(
                    DateFormat('EEEE d MMM', 'es').format(_selectedDate),
                  ),
                ),
                const Spacer(),
                if (_isToday)
                  TextButton.icon(
                    onPressed: _scrollToNow,
                    icon: Icon(
                      Icons.today,
                      size: 16,
                      color: colorScheme.primary,
                    ),
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
        ),
      ],
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
    _cachedFirstHour = firstHour;
    _cachedLastHour = lastHour;
    _cachedCourtCount = data.courts.length;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final timelineW = _timelineWidth(firstHour, lastHour);
    return NotificationListener<ScrollNotification>(
      onNotification: (_) {
        setState(() {});
        return false;
      },
      child: SingleChildScrollView(
        controller: _verticalController,
        physics: _draggingBookingId != null
            ? const NeverScrollableScrollPhysics()
            : null,
        child: SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          physics: _draggingBookingId != null
              ? const NeverScrollableScrollPhysics()
              : null,
          child: Listener(
            key: _scrollContentKey,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerCancel,
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
                      pixelsPerHour: kColumnWidth,
                      hourCount: lastHour - firstHour,
                      color: Colors.white10,
                    ),
                  ),
                ),
                Positioned(
                  left: _courtLabelWidth,
                  top: _rowHeight,
                  width: timelineW,
                  height: data.courts.length * _rowHeight,
                  child: CustomPaint(
                    size: Size(timelineW, data.courts.length * _rowHeight),
                    painter: _HalfHourDashedPainter(
                      pixelsPerHour: kColumnWidth,
                      hourCount: lastHour - firstHour,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHourHeader(colorScheme, firstHour, lastHour),
                    Container(
                      height: 1,
                      width:
                          _courtLabelWidth +
                          _timelineWidth(firstHour, lastHour),
                      color: Colors.white10,
                    ),
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
                    Container(
                      height: 1,
                      width:
                          _courtLabelWidth +
                          _timelineWidth(firstHour, lastHour),
                      color: Colors.white10,
                    ),
                  ],
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
              color: _darkBackground,
              padding: const EdgeInsets.only(left: 12, right: 8),
              alignment: Alignment.centerLeft,
              child: Text(
                'Cancha',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
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
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  color: Colors.transparent,
                  child: Row(
                    children: List.generate(lastHour - firstHour, (i) {
                      final hour = firstHour + i;
                      return Container(
                        width: kColumnWidth,
                        height: _rowHeight,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Colors.white10, width: 1),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${hour.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.75),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
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
              color: _darkBackground,
              padding: const EdgeInsets.only(left: 12, right: 8),
              alignment: Alignment.centerLeft,
              child: Text(
                court.name,
                style: _courtNameStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
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
            pixelsPerHour: kColumnWidth,
            gridLineColor: Colors.white10,
          ),
        ),
        _buildEmptyLaneTapTarget(
          court,
          courtIndex,
          colorScheme,
          firstHour,
          lastHour,
        ),
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
    const pillRadius = 12.0;
    final showFullName = durationMinutes > 60 && pillWidth > 80;
    final padding = showFullName ? 8.0 : 4.0;
    final avatarRadius = showFullName ? 12.0 : 8.0;

    final isDragging = _draggingBookingId == booking.id;
    final isRescheduling = _reschedulingBookingId == booking.id;
    final baseLeftPx = baseLeft + 4;

    return Positioned(
      left:
          baseLeftPx +
          (isDragging ? 0 : (isRescheduling ? _rescheduleOffsetX : 0)),
      top: 4,
      bottom: 4,
      width: pillWidth,
      child: Transform.translate(
        offset: Offset(
          0,
          isDragging ? 0 : (isRescheduling ? _rescheduleOffsetY : 0),
        ),
        child: Listener(
          onPointerDown: (e) {
            final box =
                _scrollContentKey.currentContext?.findRenderObject()
                    as RenderBox?;
            if (box != null && box.hasSize) {
              final local = box.globalToLocal(e.position);
              setState(() {
                _draggingBookingId = booking.id;
                _draggingPointerId = e.pointer;
                _dragStartTimelineX = baseLeft + 4;
                _dragStartContentY = local.dy;
                _dragDeltaX = 0;
                _dragDeltaY = 0;
                _pillDragContext = _PillDragContext(
                  booking: booking,
                  courtIndex: courtIndex,
                  courts: courts,
                  allBookings: allBookings,
                  courtBookings: courtBookings,
                  firstHour: firstHour,
                  lastHour: lastHour,
                  start: start,
                  durationMinutes: durationMinutes,
                );
              });
            }
          },
          child: GestureDetector(
            onPanEnd: (_) {
              if (_draggingBookingId != booking.id) return;
              _completeDrag();
            },
            child: isDragging && _dragMovedBeyondThreshold
                ? Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Opacity(
                        opacity: 0.3,
                        child: _buildPillBody(
                          pillRadius: pillRadius,
                          sidebarColor: sidebarColor,
                          padding: padding,
                          showFullName: showFullName,
                          avatarRadius: avatarRadius,
                          displayName: displayName,
                          initial: initial,
                          isPaid: isPaid,
                          booking: booking,
                          hasShadow: false,
                          start: start,
                          end: end,
                        ),
                      ),
                      Positioned(
                        left: _dragDeltaX,
                        top: _dragDeltaY,
                        child: Transform.scale(
                          scale: 1.1,
                          child: _buildPillBody(
                            pillRadius: pillRadius,
                            sidebarColor: sidebarColor,
                            padding: padding,
                            showFullName: showFullName,
                            avatarRadius: avatarRadius,
                            displayName: displayName,
                            initial: initial,
                            isPaid: isPaid,
                            booking: booking,
                            hasShadow: true,
                            start: start,
                            end: end,
                          ),
                        ),
                      ),
                    ],
                  )
                : Material(
                    color: Colors.transparent,
                    elevation: 0,
                    borderRadius: BorderRadius.circular(pillRadius),
                    child: InkWell(
                      onTap: () async {
                        if (_justFinishedDrag || _reschedulingBookingId != null)
                          return;
                        if (_draggingBookingId == booking.id &&
                            _dragMovedBeyondThreshold)
                          return;
                        if (_draggingBookingId != null &&
                            _draggingBookingId != booking.id)
                          return;
                        final refresh = await context.push<bool>(
                          '/tenant-admin-home/bookings/${booking.id}',
                          extra: {'gridDate': _selectedDate},
                        );
                        if (refresh == true && mounted) {
                          ref.invalidate(
                            adminCourtGridDataProvider(_selectedDate),
                          );
                        }
                      },
                      onLongPress: () {
                        if (_justFinishedDrag || _reschedulingBookingId != null)
                          return;
                        if (_draggingBookingId == booking.id &&
                            _dragMovedBeyondThreshold)
                          return;
                        if (_draggingBookingId != null &&
                            _draggingBookingId != booking.id)
                          return;
                        if (_draggingBookingId == booking.id) _clearDragState();
                        _showBookingQuickActionsSheet(context, booking);
                      },
                      borderRadius: BorderRadius.circular(pillRadius),
                      child: _buildPillBody(
                        pillRadius: pillRadius,
                        sidebarColor: sidebarColor,
                        padding: padding,
                        showFullName: showFullName,
                        avatarRadius: avatarRadius,
                        displayName: displayName,
                        initial: initial,
                        isPaid: isPaid,
                        booking: booking,
                        hasShadow: false,
                        start: start,
                        end: end,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillBody({
    required double pillRadius,
    required Color sidebarColor,
    required double padding,
    required bool showFullName,
    required double avatarRadius,
    required String displayName,
    required String initial,
    required bool isPaid,
    required TenantBookingModel booking,
    required bool hasShadow,
    DateTime? start,
    DateTime? end,
  }) {
    double? progress;
    if (start != null && end != null) {
      final now = DateTime.now();
      if (!now.isBefore(start) && !now.isAfter(end)) {
        final total = end.difference(start).inMilliseconds;
        final elapsed = now.difference(start).inMilliseconds;
        if (total > 0) progress = (elapsed / total).clamp(0.0, 1.0);
      }
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(pillRadius),
        gradient: LinearGradient(
          colors: [
            sidebarColor.withValues(alpha: 0.18),
            sidebarColor.withValues(alpha: 0.08),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
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
                            const SizedBox(width: 8),
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
          if (progress != null)
            Container(
              margin: const EdgeInsets.only(top: 4, left: 5, right: 5),
              height: 2,
              decoration: BoxDecoration(
                color: sidebarColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(1),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final fillW = (constraints.maxWidth * progress!).clamp(
                    0.0,
                    double.infinity,
                  );
                  return Row(
                    children: [
                      SizedBox(
                        width: fillW,
                        child: Container(
                          decoration: BoxDecoration(
                            color: sidebarColor,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyLaneTapTarget(
    TenantCourtModel court,
    int courtIndex,
    ColorScheme colorScheme,
    int firstHour,
    int lastHour,
  ) {
    const double hitWidth = 36.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (int h = firstHour; h < lastHour; h++) ...[
          for (int m in [0, 30]) ...[
            Builder(
              builder: (_) {
                final isHighlighted =
                    _draggingBookingId != null &&
                    _dragHoverCourtIndex == courtIndex &&
                    _dragHoverSlotHour == h &&
                    _dragHoverSlotMinute == m;
                final left =
                    (h - firstHour) * kColumnWidth +
                    (m == 0 ? kColumnWidth / 4 : 3 * kColumnWidth / 4) -
                    hitWidth / 2;
                return Positioned(
                  left: left,
                  top: 0,
                  bottom: 0,
                  width: hitWidth,
                  child: Stack(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _openCreateBooking(court, h, m),
                      ),
                      if (isHighlighted)
                        IgnorePointer(
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.cyanAccent.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ],
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

  static const double _occupationBarHeight = 28;
  static const double _legendBarHeight = 48;

  double _headerSectionHeight() =>
      _occupationBarHeight +
      _legendBarHeight * (1 - (_verticalOffset / 80).clamp(0.0, 1.0) * 0.35);

  Widget _buildStickyTopBar(
    AdminCourtGridData data,
    int firstHour,
    int lastHour,
  ) {
    final showBar = _verticalOffset > 4;

    if (!showBar) return const SizedBox.shrink();

    return Positioned(
      top: _headerSectionHeight(),
      left: 0,
      right: 0,
      height: _rowHeight,
      child: IgnorePointer(
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                color: _darkBackground.withValues(alpha: 0.92),
                border: Border(bottom: BorderSide(color: Colors.white10)),
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
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.85),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    ...List.generate(lastHour - firstHour, (i) {
                      final hour = firstHour + i;
                      return Container(
                        width: kColumnWidth,
                        height: _rowHeight,
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Colors.white10, width: 1),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${hour.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.75),
                              letterSpacing: 0.5,
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
      top: _headerSectionHeight(),
      left: 0,
      bottom: 0,
      width: _courtLabelWidth,
      child: IgnorePointer(
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                color: _darkBackground.withValues(alpha: 0.95),
                border: Border(right: BorderSide(color: Colors.white10)),
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
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12, right: 8),
                            child: Text(
                              court.name,
                              style: _courtNameStyle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.left,
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
      ..color = gridLineColor
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
  bool shouldRepaint(covariant _HourGuidesPainter oldDelegate) =>
      oldDelegate.pixelsPerHour != pixelsPerHour ||
      oldDelegate.hourCount != hourCount ||
      oldDelegate.color != color;
}

class _HalfHourDashedPainter extends CustomPainter {
  final double pixelsPerHour;
  final int hourCount;
  final Color color;

  _HalfHourDashedPainter({
    required this.pixelsPerHour,
    required this.hourCount,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < hourCount; i++) {
      final x = (i + 0.5) * pixelsPerHour;
      _drawDashedLine(canvas, Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 6.0;
    final delta = end - start;
    final length = delta.distance;
    final unit = Offset(delta.dx / length, delta.dy / length);
    double pos = 0;
    while (pos < length) {
      final p1 = start + Offset(unit.dx * pos, unit.dy * pos);
      pos += dashWidth;
      final p2 =
          start +
          Offset(
            unit.dx * (pos < length ? pos : length),
            unit.dy * (pos < length ? pos : length),
          );
      canvas.drawLine(p1, p2, paint);
      pos += dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _HalfHourDashedPainter oldDelegate) =>
      oldDelegate.pixelsPerHour != pixelsPerHour ||
      oldDelegate.hourCount != hourCount ||
      oldDelegate.color != color;
}
