class CounterStationModel {
  const CounterStationModel({
    required this.id,
    required this.name,
    required this.isActive,
    this.location,
  });

  final String id;
  final String name;
  final String? location;
  final bool isActive;

  factory CounterStationModel.fromMap(Map<String, Object?> map) {
    final active = map['is_active'];
    return CounterStationModel(
      id: map['id'] as String,
      name: map['name'] as String,
      location: map['location'] as String?,
      isActive: active == true || active == 1,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'location': location,
    'is_active': isActive ? 1 : 0,
  };
}
