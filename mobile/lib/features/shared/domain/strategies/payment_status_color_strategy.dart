import 'package:flutter/material.dart';
import 'status_color_strategy.dart';

class PaymentStatusColorStrategy implements StatusColorStrategy {
  @override
  Color getColor(String status) {
    switch (status) {
      case 'APPROVED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'DECLINED':
        return Colors.red;
      case 'VOIDED':
        return Colors.grey;
      case 'ERROR':
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }

  @override
  String getLabel(String status) {
    switch (status) {
      case 'APPROVED':
        return 'Aprobado';
      case 'PENDING':
        return 'Pendiente';
      case 'DECLINED':
        return 'Rechazado';
      case 'VOIDED':
        return 'Anulado';
      case 'ERROR':
        return 'Error';
      default:
        return status;
    }
  }

  @override
  IconData getIcon(String status) {
    switch (status) {
      case 'APPROVED':
        return Icons.check_circle;
      case 'PENDING':
        return Icons.pending;
      case 'DECLINED':
        return Icons.cancel;
      case 'VOIDED':
        return Icons.block;
      case 'ERROR':
        return Icons.error;
      default:
        return Icons.help;
    }
  }
}
