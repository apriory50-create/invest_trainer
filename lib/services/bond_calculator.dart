import 'dart:math';

class BondCalculator {
  // Расчет НКД (Накопленного купонного дохода)
  // nominal - номинал (например, 1000)
  // couponRate - годовая ставка в процентах (например, 12.0)
  // lastCouponDate - дата выплаты последнего купона
  // settlementDate - текущая дата расчетов
  static double calculateNKD({
    required double nominal,
    required double couponRate,
    required DateTime lastCouponDate,
    required DateTime settlementDate,
  }) {
    int daysPassed = settlementDate.difference(lastCouponDate).inDays;
    // Считаем купонный период (обычно 182 или 91 день, берем стандарт полугодового купона 182 дня)
    double annualCoupon = nominal * (couponRate / 100.0);
    double dailyCoupon = annualCoupon / 365.0;
    return double.parse((dailyCoupon * daysPassed).toStringAsFixed(2));
  }

  // Расчет примерной доходности к погашению (YTM - Yield to Maturity)
  // currentPrice - текущая рыночная цена облигации
  // nominal - номинал
  // couponRate - годовая ставка купона (%)
  // yearsToMaturity - лет до погашения
  static double calculateYTM({
    required double currentPrice,
    required double nominal,
    required double couponRate,
    required double yearsToMaturity,
  }) {
    if (yearsToMaturity <= 0 || currentPrice <= 0) return 0.0;
    double annualCoupon = nominal * (couponRate / 100.0);
    double capitalGain = (nominal - currentPrice) / yearsToMaturity;
    double averagePrice = (currentPrice + nominal) / 2.0;
    
    double ytm = ((annualCoupon + capitalGain) / averagePrice) * 100.0;
    return double.parse(ytm.toStringAsFixed(2));
  }

  // Расчет дюрации Маколея (в годах)
  static double calculateDuration({
    required double currentPrice,
    required double nominal,
    required double couponRate,
    required double yearsToMaturity,
  }) {
    if (yearsToMaturity <= 0) return 0.0;
    double c = nominal * (couponRate / 100.0);
    double y = calculateYTM(currentPrice: currentPrice, nominal: nominal, couponRate: couponRate, yearsToMaturity: yearsToMaturity) / 100.0;
    
    if (y <= 0) return yearsToMaturity;
    
    // Упрощенная формула эффективной дюрации
    double duration = yearsToMaturity / (1.0 + y);
    return double.parse(duration.toStringAsFixed(2));
  }
}
