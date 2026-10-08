class BartenderModel {
  const BartenderModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.pinHash,
    required this.isActive,
    this.counterId,
  });

  final String id;
  final String? counterId;
  final String name;
  final String phone;
  final String pinHash;
  final bool isActive;

  factory BartenderModel.fromMap(Map<String, Object?> map) {
    final active = map['is_active'];
    return BartenderModel(
      id: map['id'] as String,
      counterId: map['counter_id'] as String?,
      name: map['name'] as String,
      phone: map['phone'] as String,
      pinHash: map['pin_hash'] as String,
      isActive: active == true || active == 1,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'counter_id': counterId,
    'name': name,
    'phone': phone,
    'pin_hash': pinHash,
    'is_active': isActive ? 1 : 0,
  };
}
