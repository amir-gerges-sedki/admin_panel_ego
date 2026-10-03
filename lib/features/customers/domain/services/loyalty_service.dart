/// Centralized Loyalty Points Calculation and Configuration
class LoyaltyService {
  LoyaltyService._();

  /// Whether the loyalty points reward program is active
  static bool isLoyaltyEnabled = true;

  /// How much money spent gives 1 point.
  /// Default: Every 10 EGP spent earns 1 loyalty point (e.g. 200 EGP = 20 points).
  static double egpPerEarnedPoint = 10.0;

  /// How much monetary discount 1 point is worth when redeemed in EGP.
  /// Default: 1 point = 0.5 EGP (e.g. 20 points = 10 EGP discount).
  static double egpValuePerRedeemedPoint = 0.5;

  /// Minimum points required before a customer is eligible to redeem.
  static int minPointsToRedeem = 10;

  /// Synchronize loyalty rules dynamically from StoreSettingsModel
  static void syncFromSettings({
    bool? isLoyaltyEnabled,
    double? egpPerEarnedPoint,
    double? egpValuePerRedeemedPoint,
    int? minPointsToRedeem,
  }) {
    if (isLoyaltyEnabled != null) {
      LoyaltyService.isLoyaltyEnabled = isLoyaltyEnabled;
    }
    if (egpPerEarnedPoint != null && egpPerEarnedPoint > 0) {
      LoyaltyService.egpPerEarnedPoint = egpPerEarnedPoint;
    }
    if (egpValuePerRedeemedPoint != null && egpValuePerRedeemedPoint > 0) {
      LoyaltyService.egpValuePerRedeemedPoint = egpValuePerRedeemedPoint;
    }
    if (minPointsToRedeem != null && minPointsToRedeem >= 0) {
      LoyaltyService.minPointsToRedeem = minPointsToRedeem;
    }
  }

  /// Calculate how many loyalty points a sale earns based on payable amount
  static int calculateEarnedPoints(double netAmount) {
    if (!isLoyaltyEnabled || netAmount <= 0 || egpPerEarnedPoint <= 0) return 0;
    return (netAmount / egpPerEarnedPoint).floor();
  }

  /// Calculate the monetary discount in EGP for a given number of points
  static double calculateDiscount(int points) {
    if (!isLoyaltyEnabled || points <= 0 || egpValuePerRedeemedPoint <= 0) return 0.0;
    return points * egpValuePerRedeemedPoint;
  }

  /// Calculate maximum points a customer can redeem for a given bill total
  static int calculateMaxRedeemablePoints({
    required int customerPoints,
    required double billTotal,
  }) {
    if (!isLoyaltyEnabled ||
        customerPoints < minPointsToRedeem ||
        billTotal <= 0 ||
        egpValuePerRedeemedPoint <= 0) {
      return 0;
    }
    // Points cannot discount more than the bill total
    final maxPointsForBill = (billTotal / egpValuePerRedeemedPoint).floor();
    return customerPoints < maxPointsForBill ? customerPoints : maxPointsForBill;
  }
}
