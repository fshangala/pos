class ShiftSummaryModel {
  const ShiftSummaryModel({
    required this.cashTotal,
    required this.mobileMoneyTotal,
    required this.completedOrders,
    required this.pendingOrders,
  });

  final double cashTotal;
  final double mobileMoneyTotal;
  final int completedOrders;
  final int pendingOrders;

  double get total => cashTotal + mobileMoneyTotal;
}
