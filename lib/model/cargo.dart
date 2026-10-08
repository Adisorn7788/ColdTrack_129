class CargoItem {
  final String id;
  final String code;
  final String type;
  final String inspector;
  final double temp;
  final String daysLeft;

  CargoItem({
    required this.id,
    required this.code,
    required this.type,
    required this.inspector,
    required this.temp,
    required this.daysLeft,
  });

  factory CargoItem.fromMap(Map<String, dynamic> data, String id) {
    return CargoItem(
      id: id,
      code: data['code'] ?? '',
      type: data['type'] ?? '',
      inspector: data['inspector'] ?? '',
      temp: (data['temp'] as num?)?.toDouble() ?? 0.0,
      daysLeft: data['daysLeft'] ?? '',
    );
  }
}