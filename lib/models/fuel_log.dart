class Vehicle {
  final String id;
  final String name;      // Es. "Yamaha TMAX" o "Vespa 125"
  final String type;      // Es. "Scooter"

  Vehicle({
    required this.id,
    required this.name,
    required this.type,
  });

  // Utile in seguito per il salvataggio sul database o file locali
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'],
      name: map['name'],
      type: map['type'],
    );
  }
}

class FuelLog {
  final String id;
  final String vehicleId; // A quale veicolo appartiene il rifornimento
  final DateTime date;
  final double liters;
  final double costEuro;
  final double odometer;  // I chilometri totali segnati dal cruscotto

  FuelLog({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.liters,
    required this.costEuro,
    required this.odometer,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'date': date.toIso8601String(),
      'liters': liters,
      'costEuro': costEuro,
      'odometer': odometer,
    };
  }

  factory FuelLog.fromMap(Map<String, dynamic> map) {
    return FuelLog(
      id: map['id'],
      vehicleId: map['vehicleId'],
      date: DateTime.parse(map['date']),
      liters: map['liters'],
      costEuro: map['costEuro'],
      odometer: map['odometer'],
    );
  }
}