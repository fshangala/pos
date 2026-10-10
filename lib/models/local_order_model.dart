class LocalOrderModel {
  const LocalOrderModel({
    required this.localOrderId,
    required this.counterId,
    required this.bartenderId,
    required this.paymentType,
    required this.status,
    required this.totalAmount,
    required this.totalItemsCount,
    required this.syncStatus,
    required this.createdAt,
    this.notes,
    this.remoteOrderId,
    this.syncError,
  });

  final String localOrderId;
  final String? remoteOrderId;
  final String counterId;
  final String bartenderId;
  final String paymentType;
  final String status;
  final double totalAmount;
  final String? notes;
  final int totalItemsCount;
  final String syncStatus;
  final String? syncError;
  final String createdAt;

  Map<String, Object?> toMap() => {
    'local_order_id': localOrderId,
    'remote_order_id': remoteOrderId,
    'counter_id': counterId,
    'bartender_id': bartenderId,
    'payment_type': paymentType,
    'status': status,
    'total_amount': totalAmount,
    'notes': notes,
    'total_items_count': totalItemsCount,
    'sync_status': syncStatus,
    'sync_error': syncError,
    'created_at': createdAt,
  };

  factory LocalOrderModel.fromMap(Map<String, Object?> map) {
    return LocalOrderModel(
      localOrderId: map['local_order_id'] as String,
      remoteOrderId: map['remote_order_id'] as String?,
      counterId: map['counter_id'] as String,
      bartenderId: map['bartender_id'] as String,
      paymentType: map['payment_type'] as String,
      status: map['status'] as String,
      totalAmount: (map['total_amount'] as num).toDouble(),
      notes: map['notes'] as String?,
      totalItemsCount: map['total_items_count'] as int,
      syncStatus: map['sync_status'] as String,
      syncError: map['sync_error'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}
