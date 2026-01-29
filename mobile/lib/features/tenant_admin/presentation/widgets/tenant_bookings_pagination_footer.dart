import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/tenant_booking_model.dart';
import '../providers/tenant_admin_provider.dart';

class TenantBookingsPaginationFooter extends ConsumerWidget {
  const TenantBookingsPaginationFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(tenantBookingsProvider)
        .when(
          data: (d) {
            final p = d['pagination'] as BookingPagination;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: p.hasPrevious
                        ? () => ref
                              .read(bookingPageProvider.notifier)
                              .setPage(p.currentPage - 1)
                        : null,
                  ),
                  Text('Página ${p.currentPage} de ${p.totalPages}'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: p.hasNext
                        ? () => ref
                              .read(bookingPageProvider.notifier)
                              .setPage(p.currentPage + 1)
                        : null,
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
