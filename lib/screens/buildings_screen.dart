import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/property.dart';

class BuildingsScreen extends StatefulWidget {
  const BuildingsScreen({super.key});

  @override
  State<BuildingsScreen> createState() => _BuildingsScreenState();
}

class _BuildingsScreenState extends State<BuildingsScreen> {
  List<Immeuble> _buildings = [];

  // Contrôleurs pour l'ajout d'immeuble
  final TextEditingController _buildingNameController = TextEditingController();
  final TextEditingController _buildingAddressController = TextEditingController();
  final _buildingFormKey = GlobalKey<FormState>();

  // Contrôleurs pour l'ajout de lot
  final TextEditingController _lotNameController = TextEditingController();
  final TextEditingController _lotAreaController = TextEditingController();
  final TextEditingController _lotRentController = TextEditingController();
  final TextEditingController _lotRoomsController = TextEditingController();
  String _selectedLotType = 'Appartement';
  String _selectedFloor = 'RDC';
  String _selectedStatus = 'Libre';
  Immeuble? _selectedBuilding;

  final List<String> _lotTypes = [
    'Appartement',
    'Local Commercial',
    'Parking',
    'Studio',
    'Villa',
    'Terrain',
  ];

  final List<String> _floors = [
    'RDC',
    '1er étage',
    '2ème étage',
    '3ème étage',
    '4ème étage',
    '5ème étage',
    '6ème étage',
    'Sous-sol',
  ];

  final List<String> _statusList = [
    'Libre',
    'En travaux',
  ];

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  @override
  void dispose() {
    _buildingNameController.dispose();
    _buildingAddressController.dispose();
    _lotNameController.dispose();
    _lotAreaController.dispose();
    _lotRentController.dispose();
    _lotRoomsController.dispose();
    super.dispose();
  }

  // ==================== CHARGEMENT ====================
  
  Future<void> _loadBuildings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? buildingsJson = prefs.getString('buildings');
    
    if (buildingsJson != null && buildingsJson.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(buildingsJson);
      setState(() {
        _buildings = decoded.map((e) => Immeuble.fromJson(e)).toList();
      });
    } else {
      // Données par défaut
      setState(() {
        _buildings = [
          Immeuble(
            id: '1',
            name: 'Immeuble A',
            address: '3 rue de Paris, 75001 Paris',
            lots: [
              Lot(
                id: '1-1',
                name: 'Local Commercial',
                type: 'Local Commercial',
                area: 80,
                rent: 1500,
                rooms: 0,
                status: 'Libre',
                floor: 'RDC',
              ),
              Lot(
                id: '1-2',
                name: 'Appartement',
                type: 'Appartement',
                area: 65,
                rent: 1200,
                rooms: 3,
                status: 'Occupé',
                floor: '1er étage',
              ),
              Lot(
                id: '1-3',
                name: 'Appartement',
                type: 'Appartement',
                area: 70,
                rent: 1300,
                rooms: 3,
                status: 'En travaux',
                floor: '2ème étage',
              ),
            ],
          ),
          Immeuble(
            id: '2',
            name: 'Immeuble B',
            address: '8 avenue des Roses, 69002 Lyon',
            lots: [
              Lot(
                id: '2-1',
                name: 'Appartement',
                type: 'Appartement',
                area: 85,
                rent: 1500,
                rooms: 4,
                status: 'Occupé',
                floor: '1er étage',
              ),
              Lot(
                id: '2-2',
                name: 'Appartement',
                type: 'Appartement',
                area: 75,
                rent: 1350,
                rooms: 3,
                status: 'Libre',
                floor: '2ème étage',
              ),
              Lot(
                id: '2-3',
                name: 'Appartement',
                type: 'Appartement',
                area: 90,
                rent: 1650,
                rooms: 4,
                status: 'En travaux',
                floor: '3ème étage',
              ),
            ],
          ),
        ];
      });
      await _saveBuildings();
    }
  }

  Future<void> _saveBuildings() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(_buildings.map((e) => e.toJson()).toList());
    await prefs.setString('buildings', jsonString);
  }

  // ==================== GESTION DES STATUTS ====================
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Occupé':
        return Colors.green;
      case 'En travaux':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Occupé':
        return 'Occupé';
      case 'En travaux':
        return 'En travaux';
      default:
        return 'Libre';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Occupé':
        return Icons.person;
      case 'En travaux':
        return Icons.construction;
      default:
        return Icons.check_circle_outline;
    }
  }

  Future<void> _updateLotStatus(int buildingIndex, int lotIndex, String newStatus) async {
    setState(() {
      final oldLot = _buildings[buildingIndex].lots[lotIndex];
      final updatedLot = Lot(
        id: oldLot.id,
        name: oldLot.name,
        type: oldLot.type,
        area: oldLot.area,
        rent: oldLot.rent,
        rooms: oldLot.rooms,
        status: newStatus,
        floor: oldLot.floor,
      );
      _buildings[buildingIndex].lots[lotIndex] = updatedLot;
    });
    await _saveBuildings();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lot mis à jour : ${_getStatusText(newStatus)}'),
          backgroundColor: _getStatusColor(newStatus),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ==================== AJOUT IMEUBLE ====================
  
  void _addBuilding() {
    _buildingNameController.clear();
    _buildingAddressController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _buildingFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Ajouter un immeuble',
                      style: GoogleFonts.urbanist(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _buildingNameController,
                      decoration: InputDecoration(
                        labelText: 'Nom de l\'immeuble *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _buildingAddressController,
                      decoration: InputDecoration(
                        labelText: 'Adresse *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (_buildingFormKey.currentState!.validate()) {
                                final newBuilding = Immeuble(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  name: _buildingNameController.text,
                                  address: _buildingAddressController.text,
                                  lots: [],
                                );
                                setState(() {
                                  _buildings.add(newBuilding);
                                });
                                _saveBuildings();
                                _buildingNameController.clear();
                                _buildingAddressController.clear();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Immeuble ajouté !')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E88E5),
                            ),
                            child: const Text('Ajouter'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== AJOUT LOT ====================
  
  void _addLot(Immeuble building, int buildingIndex) {
    _lotNameController.clear();
    _lotAreaController.clear();
    _lotRentController.clear();
    _lotRoomsController.clear();
    _selectedLotType = 'Appartement';
    _selectedFloor = 'RDC';
    _selectedStatus = 'Libre';
    _selectedBuilding = building;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Ajouter un lot à ${building.name}',
                        style: GoogleFonts.urbanist(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _lotNameController,
                        decoration: InputDecoration(
                          labelText: 'Nom du lot *',
                          hintText: 'Ex: Appartement, Local Commercial...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedLotType,
                        decoration: InputDecoration(
                          labelText: 'Type de lot *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _lotTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setModalState(() {
                            _selectedLotType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedFloor,
                        decoration: InputDecoration(
                          labelText: 'Étage *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.location_city, size: 18),
                        ),
                        items: _floors.map((floor) {
                          return DropdownMenuItem(
                            value: floor,
                            child: Row(
                              children: [
                                Icon(
                                  floor == 'RDC' ? Icons.other_houses : Icons.location_city,
                                  size: 18,
                                  color: const Color(0xFF1E88E5),
                                ),
                                const SizedBox(width: 8),
                                Text(floor),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setModalState(() {
                            _selectedFloor = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Statut initial *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _statusList.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: status == 'Libre' ? Colors.grey : Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(status),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setModalState(() {
                            _selectedStatus = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _lotAreaController,
                              decoration: InputDecoration(
                                labelText: 'Surface (m²) *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                suffixText: 'm²',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lotRentController,
                              decoration: InputDecoration(
                                labelText: 'Loyer (€) *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.euro, size: 16),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _lotRoomsController,
                        decoration: InputDecoration(
                          labelText: 'Nombre de pièces',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.bed, size: 18),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Annuler'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                final newLot = Lot(
                                  id: '${building.id}-${building.lots.length + 1}',
                                  name: _lotNameController.text.isNotEmpty 
                                      ? _lotNameController.text 
                                      : _selectedLotType,
                                  type: _selectedLotType,
                                  area: double.tryParse(_lotAreaController.text) ?? 0,
                                  rent: double.tryParse(_lotRentController.text) ?? 0,
                                  rooms: int.tryParse(_lotRoomsController.text) ?? 0,
                                  status: _selectedStatus,
                                  floor: _selectedFloor,
                                );
                                setState(() {
                                  _buildings[buildingIndex].lots.add(newLot);
                                });
                                _saveBuildings();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Lot "${newLot.name}" ajouté (${_getStatusText(newLot.status)})'),
                                    backgroundColor: _getStatusColor(newLot.status),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                              ),
                              child: const Text('Ajouter'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== SUPPRESSION ====================
  
  void _deleteBuilding(Immeuble building, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Supprimer l\'immeuble',
            style: GoogleFonts.urbanist(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Voulez-vous vraiment supprimer "${building.name}" ?\n\n${building.lots.length} lot(s) seront également supprimés.',
            style: GoogleFonts.urbanist(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: GoogleFonts.urbanist(color: const Color(0xFF757575)),
              ),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  _buildings.removeAt(index);
                });
                await _saveBuildings();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Immeuble "${building.name}" supprimé'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                'Supprimer',
                style: GoogleFonts.urbanist(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteLot(Immeuble building, int lotIndex, int buildingIndex) {
    final lot = building.lots[lotIndex];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Supprimer le lot',
            style: GoogleFonts.urbanist(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Voulez-vous vraiment supprimer "${lot.name}" (${lot.floor}) ?',
            style: GoogleFonts.urbanist(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: GoogleFonts.urbanist(color: const Color(0xFF757575)),
              ),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  _buildings[buildingIndex].lots.removeAt(lotIndex);
                });
                await _saveBuildings();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lot "${lot.name}" supprimé'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                'Supprimer',
                style: GoogleFonts.urbanist(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==================== AFFICHAGE ====================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Mes immeubles',
          style: GoogleFonts.urbanist(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business, size: 28),
            color: const Color(0xFF1E88E5),
            onPressed: _addBuilding,
          ),
        ],
      ),
      body: _buildings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.business, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun immeuble',
                    style: GoogleFonts.urbanist(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cliquez sur + pour ajouter un immeuble',
                    style: GoogleFonts.urbanist(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _buildings.length,
              itemBuilder: (context, index) {
                final building = _buildings[index];
                return _buildBuildingCard(building, index);
              },
            ),
    );
  }

  Widget _buildBuildingCard(Immeuble building, int buildingIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de l'immeuble
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.business, color: Color(0xFF1E88E5), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        building.name,
                        style: GoogleFonts.urbanist(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        building.address,
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${building.lots.length} lot(s)',
                        style: GoogleFonts.urbanist(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteBuilding(building, buildingIndex),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: const Color(0xFF1E88E5),
                  onPressed: () => _addLot(building, buildingIndex),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Liste des lots
          if (building.lots.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Aucun lot. Cliquez sur + pour ajouter',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: building.lots.length,
              itemBuilder: (context, lotIndex) {
                final lot = building.lots[lotIndex];
                return _buildLotTile(lot, buildingIndex, lotIndex);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLotTile(Lot lot, int buildingIndex, int lotIndex) {
    final statusColor = _getStatusColor(lot.status);
    final statusText = _getStatusText(lot.status);
    final statusIcon = _getStatusIcon(lot.status);
    
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5).withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                lot.type == 'Local Commercial' ? Icons.store : Icons.apartment,
                size: 20,
                color: const Color(0xFF1E88E5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        lot.name,
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          lot.floor,
                          style: GoogleFonts.urbanist(
                            fontSize: 10,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${lot.area} m² • ${lot.rent} €/mois',
                    style: GoogleFonts.urbanist(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            // Statut avec icône
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    statusIcon,
                    size: 12,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Menu pour changer le statut
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
              onSelected: (value) {
                _updateLotStatus(buildingIndex, lotIndex, value);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'Libre',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 18, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Libre'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'Occupé',
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 18, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Occupé'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'En travaux',
                  child: Row(
                    children: [
                      Icon(Icons.construction, size: 18, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('En travaux'),
                    ],
                  ),
                ),
              ],
            ),
            // Bouton supprimer le lot
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.red),
              onPressed: () => _deleteLot(_buildings[buildingIndex], lotIndex, buildingIndex),
            ),
          ],
        ),
      ),
    );
  }
}