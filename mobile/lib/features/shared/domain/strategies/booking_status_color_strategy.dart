import 'package:flutter/material.dart';
import 'status_color_strategy.dart';

class BookingStatusColorStrategy implements StatusColorStrategy {
  @override
  Color getColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  String getLabel(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmado';
      case 'pending':
        return 'Pendiente';
      case 'cancelled':
        return 'Cancelado';
      case 'completed':
        return 'Completado';
      default:
        return status;
    }
  }

  @override
  IconData getIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'cancelled':
        return Icons.cancel;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.help;
    }
  }
}
