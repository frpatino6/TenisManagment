import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/core/constants/timeouts.dart';

void main() {
  group('Timeouts', () {
    test('should have httpRequest timeout defined', () {
      expect(Timeouts.httpRequest, isA<Duration>());
      expect(Timeouts.httpRequest.inSeconds, greaterThan(0));
    });

    test('should have httpRequestLong timeout defined', () {
      expect(Timeouts.httpRequestLong, isA<Duration>());
      expect(
        Timeouts.httpRequestLong.inSeconds,
        greaterThan(Timeouts.httpRequest.inSeconds),
      );
    });

    test('should have httpRequestShort timeout defined', () {
      expect(Timeouts.httpRequestShort, isA<Duration>());
      expect(
        Timeouts.httpRequestShort.inSeconds,
        lessThan(Timeouts.httpRequest.inSeconds),
      );
    });

    test('should have snackbar durations defined', () {
      expect(Timeouts.snackbarSuccess, isA<Duration>());
      expect(Timeouts.snackbarError, isA<Duration>());
      expect(Timeouts.snackbarInfo, isA<Duration>());
      expect(
        Timeouts.snackbarError.inSeconds,
        greaterThanOrEqualTo(Timeouts.snackbarSuccess.inSeconds),
      );
    });

    test('should have animation durations defined', () {
      expect(Timeouts.animationShort, isA<Duration>());
      expect(Timeouts.animationMedium, isA<Duration>());
      expect(Timeouts.animationLong, isA<Duration>());
      expect(Timeouts.animationExtraLong, isA<Duration>());

      expect(
        Timeouts.animationShort.inMilliseconds,
        lessThan(Timeouts.animationMedium.inMilliseconds),
      );
      expect(
        Timeouts.animationMedium.inMilliseconds,
        lessThan(Timeouts.animationLong.inMilliseconds),
      );
      expect(
        Timeouts.animationLong.inMilliseconds,
        lessThan(Timeouts.animationExtraLong.inMilliseconds),
      );
    });

    test('should have specific delays defined', () {
      expect(Timeouts.debounceSearch, isA<Duration>());
      expect(Timeouts.loadingDelay, isA<Duration>());
      expect(Timeouts.loadingHideDelay, isA<Duration>());
      expect(Timeouts.firebaseTokenDelay, isA<Duration>());
      expect(Timeouts.dialogTimeout, isA<Duration>());
    });

    test('should have analytics animation durations defined', () {
      expect(Timeouts.shimmerAnimation, isA<Duration>());
      expect(Timeouts.metricAnimation, isA<Duration>());
      expect(Timeouts.chartAnimation, isA<Duration>());
      expect(Timeouts.widgetAnimation, isA<Duration>());
    });
  });
}
