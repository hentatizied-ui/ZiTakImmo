import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tenant.dart';
import '../models/property.dart';
import 'tenant_payments_screen.dart';

class TenantsScreen extends StatefulWidget {
  const TenantsScreen({super.key});

  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen> {
  List<Tenant> _tenants = [];
  List<Immeuble> _buildings = [];

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _depositController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedBuildingId;
  String? _selectedLotId;
  DateTime _selectedStartDate = DateTime.now();
  List<Lot> _availableLots = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final String? buildingsJson = prefs.getString('buildings');
    if (buildingsJson != null && buildingsJson.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(buildingsJson);
      setState(() {
        _buildings = decoded.map((e) => Immeuble.fromJson(e)).toList();
      });
    }

    final String? tenantsJson = prefs.getString('tenants');
    if (tenantsJson != null && tenantsJson.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(tenantsJson);
      setState(() {
        _tenants = decoded.map((e) => Tenant.fromJson(e)).toList();
      });
    } else {
      setState(() {
        _tenants = [];
      });
      await _saveTenants();
    }
  }

  Future<void> _saveTenants() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(_tenants.map((e) => e.toJson()).toList());
    await prefs.setString('tenants', jsonString);
  }

  Future<void> _saveBuildings() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(_buildings.map((e) => e.toJson()).toList());
    await prefs.setString('buildings', jsonString);
  }

  Future<void> _updateLotStatus(String buildingId, String lotId, String status) async {
    final buildingIndex = _buildings.indexWhere((b) => b.id == buildingId);
    if (buildingIndex != -1) {
      final lotIndex = _buildings[buildingIndex].lots.indexWhere((l) => l.id == lotId);
      if (lotIndex != -1) {
        final oldLot = _buildings[buildingIndex].lots[lotIndex];
        final updatedLot = Lot(
          id: oldLot.id,
          name: oldLot.name,
          type: oldLot.type,
          area: oldLot.area,
          rent: oldLot.rent,
          rooms: oldLot.rooms,
          status: status,
          floor: oldLot.floor,
        );
        setState(() {
          _buildings[buildingIndex].lots[lotIndex] = updatedLot;
        });
        await _saveBuildings();
      }
    }
  }

  void _goToPayments(Tenant tenant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TenantPaymentsScreen(tenant: tenant),
      ),
    );
  }

  void _addTenant() {
    _firstNameController.clear();
    _lastNameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _depositController.clear();
    _selectedBuildingId = null;
    _selectedLotId = null;
    _selectedStartDate = DateTime.now();
    _availableLots = [];

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
                  child: Form(
                    key: _formKey,
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
                          'Ajouter un locataire',
                          style: GoogleFonts.urbanist(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            labelText: 'Prénom *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Requis' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            labelText: 'Nom *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Requis' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Téléphone *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Requis' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedBuildingId,
                          decoration: InputDecoration(
                            labelText: 'Immeuble *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: _buildings.map((building) {
                            return DropdownMenuItem(
                              value: building.id,
                              child: Text(building.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() {
                              _selectedBuildingId = value;
                              _selectedLotId = null;
                              final building = _buildings.firstWhere((b) => b.id == value);
                              _availableLots = building.lots.where((l) => l.status == 'Libre').toList();
                            });
                          },
                          validator: (value) => value == null ? 'Sélectionnez un immeuble' : null,
                        ),
                        const SizedBox(height: 16),
                        if (_selectedBuildingId != null)
                          DropdownButtonFormField<String>(
                            initialValue: _selectedLotId,
                            decoration: InputDecoration(
                              labelText: 'Lot *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: _availableLots.map((lot) {
                              return DropdownMenuItem(
                                value: lot.id,
                                child: Text('${lot.name} - ${lot.floor} (${lot.rent}€/mois)'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setModalState(() {
                                _selectedLotId = value;
                              });
                            },
                            validator: (value) => value == null ? 'Sélectionnez un lot' : null,
                          ),
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Date d\'entrée'),
                          subtitle: Text(
                            '${_selectedStartDate.day}/${_selectedStartDate.month}/${_selectedStartDate.year}',
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedStartDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              setModalState(() {
                                _selectedStartDate = date;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _depositController,
                          decoration: InputDecoration(
                            labelText: 'Dépôt de garantie (€)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.euro, size: 18),
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
                                  if (_formKey.currentState!.validate() && _selectedLotId != null && _selectedBuildingId != null) {
                                    final newTenant = Tenant(
                                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                                      firstName: _firstNameController.text,
                                      lastName: _lastNameController.text,
                                      phone: _phoneController.text,
                                      email: _emailController.text,
                                      buildingId: _selectedBuildingId,
                                      lotId: _selectedLotId,
                                      startDate: _selectedStartDate,
                                      deposit: double.tryParse(_depositController.text) ?? 0,
                                    );
                                    
                                    setState(() {
                                      _tenants.add(newTenant);
                                    });
                                    _saveTenants();
                                    
                                    _updateLotStatus(_selectedBuildingId!, _selectedLotId!, 'Occupé');
                                    
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Locataire ${newTenant.fullName} ajouté !'),
                                        backgroundColor: Colors.green,
                                      ),
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
      },
    );
  }

  void _deleteTenant(Tenant tenant, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Supprimer le locataire',
            style: GoogleFonts.urbanist(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Voulez-vous vraiment supprimer "${tenant.fullName}" ?\n\nLe lot deviendra libre.',
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
                if (tenant.buildingId != null && tenant.lotId != null) {
                  await _updateLotStatus(tenant.buildingId!, tenant.lotId!, 'Libre');
                }
                
                setState(() {
                  _tenants.removeAt(index);
                });
                await _saveTenants();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Locataire "${tenant.fullName}" supprimé'),
                    backgroundColor: Colors.red,
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

  String _getLotName(String buildingId, String lotId) {
    final building = _buildings.firstWhere((b) => b.id == buildingId, orElse: () => Immeuble(id: '', name: '', address: '', lots: []));
    final lot = building.lots.firstWhere((l) => l.id == lotId, orElse: () => Lot(id: '', name: '', type: '', area: 0, rent: 0, rooms: 0, status: '', floor: ''));
    return lot.name.isNotEmpty ? '${building.name} - ${lot.name} (${lot.floor})' : 'Non attribué';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Locataires',
          style: GoogleFonts.urbanist(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            color: const Color(0xFF1E88E5),
            onPressed: _addTenant,
          ),
        ],
      ),
      body: _tenants.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun locataire',
                    style: GoogleFonts.urbanist(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cliquez sur + pour ajouter un locataire',
                    style: GoogleFonts.urbanist(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _tenants.length,
              itemBuilder: (context, index) {
                final tenant = _tenants[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1E88E5).withOpacity(0.1),
                          child: Text(
                            tenant.firstName[0].toUpperCase() + tenant.lastName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF1E88E5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          tenant.fullName,
                          style: GoogleFonts.urbanist(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              tenant.phone,
                              style: GoogleFonts.urbanist(fontSize: 12, color: Colors.grey),
                            ),
                            if (tenant.buildingId != null && tenant.lotId != null)
                              Text(
                                _getLotName(tenant.buildingId!, tenant.lotId!),
                                style: GoogleFonts.urbanist(
                                  fontSize: 11,
                                  color: const Color(0xFF1E88E5),
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.payment, color: Color(0xFF1E88E5)),
                              onPressed: () => _goToPayments(tenant),
                              tooltip: 'Voir les paiements',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deleteTenant(tenant, index),
                              tooltip: 'Supprimer',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}