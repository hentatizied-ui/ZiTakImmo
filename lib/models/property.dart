class Immeuble {
  final String id;
  final String name;
  final String address;
  final List<Lot> lots;
  
  Immeuble({
    required this.id,
    required this.name,
    required this.address,
    required this.lots,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'lots': lots.map((e) => e.toJson()).toList(),
  };
  
  factory Immeuble.fromJson(Map<String, dynamic> json) => Immeuble(
    id: json['id'],
    name: json['name'],
    address: json['address'],
    lots: (json['lots'] as List).map((e) => Lot.fromJson(e)).toList(),
  );
}

class Lot {
  final String id;
  final String name;
  final String type;
  final double area;
  final double rent;
  final int rooms;
  final String status;
  final String? tenantId;
  final String floor;

  Lot({
    required this.id,
    required this.name,
    required this.type,
    required this.area,
    required this.rent,
    required this.rooms,
    required this.status,
    this.tenantId,
    required this.floor,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'area': area,
    'rent': rent,
    'rooms': rooms,
    'status': status,
    'tenantId': tenantId,
    'floor': floor,
  };
  
  factory Lot.fromJson(Map<String, dynamic> json) => Lot(
    id: json['id'],
    name: json['name'],
    type: json['type'],
    area: json['area'],
    rent: json['rent'],
    rooms: json['rooms'],
    status: json['status'],
    tenantId: json['tenantId'],
    floor: json['floor'] ?? 'RDC',
  );
}