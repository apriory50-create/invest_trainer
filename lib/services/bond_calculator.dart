import 'dart:math';

class BondCalculator {
  static double calculateNKD({
    required double nominal,
    required double couponRate,
    required DateTime lastCouponDate,
    required DateTime settlementDate,
  }) {
    final daysPassed = settlementDate.difference(lastCouponDate).inDays;
    if (daysPassed <= 0) return 0.0;
    final annualCoupon = nominal * (couponRate / 100.0);
    final dailyCoupon = annualCoupon / 365.0;
    return double.parse((dailyCoupon * daysPassed).toStringAsFixed(2));
  }

  static double calculateYTM({
    required double currentPrice,
    required double nominal,
    required double couponRate,
    required double yearsToMaturity,
  }) {
    if (yearsToMaturity <= 0 || currentPrice <= 0) return 0.0;
    final annualCoupon = nominal * (couponRate / 100.0);
    final capitalGain = (nominal - currentPrice) / yearsToMaturity;
    final averagePrice = (currentPrice + nominal) / 2.0;

    final ytm = ((annualCoupon + capitalGain) / averagePrice) * 100.0;
    return double.parse(ytm.toStringAsFixed(2));
  }

  // Расчет дюрации Маколея (в годах) по дисконтированным денежным потокам
  static double calculateDuration({
    required double currentPrice,
    required double nominal,
    required double couponRate,
    required double yearsToMaturity,
    int paymentsPerYear = 2,
  }) {
    if (yearsToMaturity <= 0 || currentPrice <= 0 || nominal <= 0) return 0.0;

    final ytmAnnual = calculateYTM(
          currentPrice: currentPrice,
          nominal: nominal,
          couponRate: couponRate,
          yearsToMaturity: yearsToMaturity,
        ) /
        100.0;

    final totalPeriods = max(1, (yearsToMaturity * paymentsPerYear).round());
    final periodYield = ytmAnnual / paymentsPerYear;
    final couponPayment = (nominal * (couponRate / 100.0)) / paymentsPerYear;

    double weightedTimeSum = 0.0;
    double presentValueSum = 0.0;

    for (int k = 1; k <= totalPeriods; k++) {
      final timeInYears = k / paymentsPerYear;
      final cashFlow =
          (k == totalPeriods) ? (couponPayment + nominal) : couponPayment;
      final discountFactor = pow(1.0 + max(0.0, periodYield), k).toDouble();
      final pv = cashFlow / discountFactor;

      weightedTimeSum += timeInYears * pv;
      presentValueSum += pv;
    }

    if (presentValueSum <= 0) return 0.0;
    final macaulayDuration = weightedTimeSum / presentValueSum;
    return double.parse(macaulayDuration.toStringAsFixed(2));
  }
}

