import 'status_color_strategy.dart';
import 'booking_status_color_strategy.dart';
import 'payment_status_color_strategy.dart';

enum StatusType {
  booking,
  payment,
}

class StatusColorStrategyFactory {
  static StatusColorStrategy getStrategy(StatusType type) {
    switch (type) {
      case StatusType.booking:
        return BookingStatusColorStrategy();
      case StatusType.payment:
        return PaymentStatusColorStrategy();
    }
  }
}
