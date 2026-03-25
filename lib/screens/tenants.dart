import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tenant.dart';
import '../models/property.dart';
import '../screens/tenant_payments_screen.dart';

class TenantsScreen extends StatefulWidget {
  const TenantsScreen({super.key});

  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen> {
  List<Tenant> _tenants = [];
  List<Immeuble> _buildings = [];
  bool _isLoading = true;

  // Contrôleurs pour le formulaire
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime _startDate = DateTime.now();
  String? _selectedBuildingId;
  String? _selectedLotId;
  List<Lot> _availableLots = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _loadBuildings();
    await _loadTenants();
    setState(() => _isLoading = false);
  }

  Future<void> _loadBuildings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? buildingsJson = prefs.getString('buildings');
    if (buildingsJson != null && buildingsJson.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(buildingsJson);
      setState(() {
        _buildings = decoded.map((e) => Immeuble.fromJson(e)).toList();
      });
    }
  }

  Future<void> _loadTenants() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tenantsJson = prefs.getString('tenants');
    if (tenantsJson != null && tenantsJson.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(tenantsJson);
      setState(() {
        _tenants = decoded.map((e) => Tenant.fromJson(e)).toList();
      });
    }
  }

  Future<void> _saveTenants() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(_tenants.map((e) => e.toJson()).toList());
    await prefs.setString('tenants', jsonString);
  }

  void _updateLots(String? buildingId) {
    setState(() {
      _selectedBuildingId = buildingId;
      _selectedLotId = null;
      final building = _buildings.firstWhere(
        (b) => b.id == buildingId,
        orElse: () => Immeuble(id: '', name: '', address: '', lots: []),
      );
      _availableLots = building.lots;
    });
  }

  void _addTenant() async {
    final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
    if (fullName.isEmpty) {
      _showSnackBar('Veuillez entrer le nom du locataire');
      return;
    }
    if (_selectedBuildingId == null || _selectedLotId == null) {
      _showSnackBar('Veuillez sélectionner un bien');
      return;
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newTenant = Tenant(
      id: id,
      fullName: fullName,
      buildingId: _selectedBuildingId,
      lotId: _selectedLotId,
      startDate: _startDate,
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
    );

    setState(() {
      _tenants.add(newTenant);
    });
    await _saveTenants();

    // Réinitialiser le formulaire
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _startDate = DateTime.now();
    _selectedBuildingId = null;
    _selectedLotId = null;
    _availableLots = [];

    Navigator.pop(context);
    _showSnackBar('Locataire ajouté avec succès');
    _loadData();
  }

  void _editTenant(Tenant tenant) {
    // Extraire prénom et nom du fullName
    final nameParts = tenant.fullName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    _firstNameController.text = firstName;
    _lastNameController.text = lastName;
    _emailController.text = tenant.email ?? '';
    _phoneController.text = tenant.phone ?? '';
    _startDate = tenant.startDate;
    _selectedBuildingId = tenant.buildingId;
    _selectedLotId = tenant.lotId;

    if (tenant.buildingId != null) {
      _updateLots(tenant.buildingId);
    }

    showDialog(
      context: context,
      builder: (context) => _buildTenantDialog(isEdit: true, tenant: tenant),
    );
  }

  Future<void> _updateTenant(Tenant oldTenant) async {
    final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
    if (fullName.isEmpty) {
      _showSnackBar('Veuillez entrer le nom du locataire');
      return;
    }

    final updatedTenant = Tenant(
      id: oldTenant.id,
      fullName: fullName,
      buildingId: _selectedBuildingId,
      lotId: _selectedLotId,
      startDate: _startDate,
      email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
    );

    final index = _tenants.indexWhere((t) => t.id == oldTenant.id);
    setState(() {
      _tenants[index] = updatedTenant;
    });
    await _saveTenants();

    Navigator.pop(context);
    _showSnackBar('Locataire modifié avec succès');
    _loadData();
  }

  void _deleteTenant(Tenant tenant) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le locataire'),
        content: Text('Voulez-vous vraiment supprimer ${tenant.fullName} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              setState(() {
                _tenants.removeWhere((t) => t.id == tenant.id);
              });
              await _saveTenants();
              Navigator.pop(context);
              _showSnackBar('Locataire supprimé');
              _loadData();
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantDialog({bool isEdit = false, Tenant? tenant}) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(isEdit ? 'Modifier le locataire' : 'Ajouter un locataire'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedBuildingId,
                decoration: const InputDecoration(
                  labelText: 'Immeuble',
                  border: OutlineInputBorder(),
                ),
                items: _buildings.map((building) {
                  return DropdownMenuItem(
                    value: building.id,
                    child: Text(building.name),
                  );
                }).toList(),
                onChanged: (value) {
                  _updateLots(value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedLotId,
                decoration: const InputDecoration(
                  labelText: 'Lot',
                  border: OutlineInputBorder(),
                ),
                items: _availableLots.map((lot) {
                  return DropdownMenuItem(
                    value: lot.id,
                    child: Text('${lot.name} - ${lot.rent.toStringAsFixed(2)} €'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLotId = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Date d\'entrée'),
                subtitle: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _startDate = date;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (isEdit && tenant != null) {
              _updateTenant(tenant);
            } else {
              _addTenant();
            }
          },
          child: Text(isEdit ? 'Modifier' : 'Ajouter'),
        ),
      ],
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
            icon: const Icon(Icons.add, color: Colors.black87),
            onPressed: () {
              _firstNameController.clear();
              _lastNameController.clear();
              _emailController.clear();
              _phoneController.clear();
              _startDate = DateTime.now();
              _selectedBuildingId = null;
              _selectedLotId = null;
              _availableLots = [];
              showDialog(
                context: context,
                builder: (context) => _buildTenantDialog(),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tenants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun locataire',
                        style: GoogleFonts.urbanist(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Appuyez sur le bouton + pour ajouter',
                        style: GoogleFonts.urbanist(fontSize: 12, color: Colors.grey),
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
                            color: Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TenantPaymentsScreen(tenant: tenant),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: const Color(0xFF1E88E5).withValues(alpha: 0.1),
                                  child: Text(
                                    tenant.fullName.isNotEmpty 
                                        ? tenant.fullName[0].toUpperCase() 
                                        : '?',
                                    style: GoogleFonts.urbanist(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E88E5),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tenant.fullName,
                                        style: GoogleFonts.urbanist(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (tenant.email != null && tenant.email!.isNotEmpty)
                                        Text(
                                          tenant.email!,
                                          style: GoogleFonts.urbanist(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      if (tenant.phone != null && tenant.phone!.isNotEmpty)
                                        Text(
                                          tenant.phone!,
                                          style: GoogleFonts.urbanist(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      Text(
                                        'Entrée : ${tenant.startDate.day}/${tenant.startDate.month}/${tenant.startDate.year}',
                                        style: GoogleFonts.urbanist(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _editTenant(tenant),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteTenant(tenant),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}