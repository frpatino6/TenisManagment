import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/tenant_booking_model.dart';
import '../providers/tenant_admin_provider.dart';

class TenantBookingsListHeader extends ConsumerWidget {
  final List<TenantBookingModel> items;

  const TenantBookingsListHeader({super.key, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(tenantBookingsProvider)
        .when(
          data: (d) {
            final p = d['pagination'] as BookingPagination;
            final t = Theme.of(context).textTheme;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Mostrando ${items.length} de ${p.totalItems} reservas',
                    style: t.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    'Página ${p.currentPage} / ${p.totalPages}',
                    style: t.bodySmall,
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (err, st) => const SizedBox.shrink(),
        );
  }
}
