import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/shared/presentation/screens/paginated_list_screen.dart';
import '../../domain/models/tenant_booking_model.dart';
import '../providers/tenant_admin_provider.dart';
import '../utils/tenant_booking_actions.dart';
import '../widgets/tenant_booking_card.dart';
import '../widgets/tenant_bookings_list_header.dart';
import '../widgets/tenant_bookings_pagination_footer.dart';
import '../widgets/tenant_bookings_search_and_filters.dart';

class TenantBookingsListScreen extends PaginatedListScreen<TenantBookingModel> {
  const TenantBookingsListScreen({super.key});

  @override
  ConsumerState<PaginatedListScreen<TenantBookingModel>> createState() =>
      _TenantBookingsListScreenState();
}

class _TenantBookingsListScreenState
    extends PaginatedListScreenState<TenantBookingModel> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  AsyncValue<List<TenantBookingModel>> watchData() {
    return ref
        .watch(tenantBookingsProvider)
        .when(
          data: (d) =>
              AsyncValue.data(d['bookings'] as List<TenantBookingModel>),
          loading: () => const AsyncValue.loading(),
          error: (e, s) => AsyncValue.error(e, s),
        );
  }

  @override
  String getTitle(BuildContext context) => 'Reservas';

  @override
  Widget buildListItem(BuildContext context, TenantBookingModel item) {
    return TenantBookingCard(
      booking: item,
      onTap: () async {
        final refresh = await context.push<bool>(
          '/tenant-admin-home/bookings/${item.id}',
        );
        if (refresh == true) ref.invalidate(tenantBookingsProvider);
      },
      onConfirmPayment: () => confirmBookingQuickPayment(context, ref, item),
    );
  }

  @override
  Widget buildSearchAndFilters(BuildContext context) =>
      TenantBookingsSearchAndFilters(searchController: _searchController);

  @override
  Widget? buildListHeader(
    BuildContext context,
    List<TenantBookingModel> items,
  ) => TenantBookingsListHeader(items: items);

  @override
  Widget? buildPaginationFooter(BuildContext context) =>
      const TenantBookingsPaginationFooter();

  @override
  String get emptyMessage =>
      'No se encontraron reservas con los filtros aplicados.';

  @override
  VoidCallback? get onRetry =>
      () => ref.refresh(tenantBookingsProvider);

  @override
  List<Widget>? appBarActions(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.calendar_month),
      onPressed: () => context.push('/tenant-admin-home/bookings/calendar'),
      tooltip: 'Vista de calendario',
    ),
    IconButton(
      icon: const Icon(Icons.bar_chart),
      onPressed: () => context.push('/tenant-admin-home/bookings/stats'),
      tooltip: 'Estadísticas',
    ),
  ];
}
