import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tenant.dart';
import '../models/payment.dart';
import '../models/property.dart';
import '../services/pdf_service.dart';
import '../services/share_service.dart';
import 'payment_details.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<Tenant> _tenants = [];
  List<Payment> _payments = [];
  int _selectedIndex = 0; // 0: échéances, 1: historique

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Charger les locataires
    final String? tenantsJson = prefs.getString('tenants');
    if (tenantsJson != null && tenantsJson.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(tenantsJson);
      setState(() {
        _tenants = decoded.map((e) => Tenant.fromJson(e)).toList();
      });
    }

    // Charger les paiements
    final String? paymentsJson = prefs.getString('payments');
    if (paymentsJson != null && paymentsJson.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(paymentsJson);
      setState(() {
        _payments = decoded.map((e) => Payment.fromJson(e)).toList();
      });
    } else {
      _generateInitialPayments();
    }
  }

  Future<void> _generateInitialPayments() async {
    final now = DateTime.now();
    final payments = <Payment>[];
    
    for (var tenant in _tenants) {
      final lotRent = await _getLotRent(tenant.buildingId, tenant.lotId);
      
      for (int i = 0; i < 3; i++) {
        final dueDate = DateTime(now.year, now.month + i, 5);
        payments.add(Payment(
          id: '${tenant.id}_${dueDate.year}_${dueDate.month}',
          tenantId: tenant.id,
          tenantName: tenant.fullName,
          buildingId: tenant.buildingId ?? '',
          lotId: tenant.lotId ?? '',
          lotName: 'Lot ${tenant.lotId}',
          amount: lotRent,
          dueDate: dueDate,
          status: 'pending',
        ));
      }
    }
    
    setState(() {
      _payments = payments;
    });
    await _savePayments();
  }

  Future<double> _getLotRent(String? buildingId, String? lotId) async {
    if (buildingId == null || lotId == null) return 0;
    
    final prefs = await SharedPreferences.getInstance();
    final String? buildingsJson = prefs.getString('buildings');
    if (buildingsJson != null && buildingsJson.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(buildingsJson);
      final buildings = decoded.map((e) => Immeuble.fromJson(e)).toList();
      final building = buildings.firstWhere(
        (b) => b.id == buildingId,
        orElse: () => Immeuble(id: '', name: '', address: '', lots: [])
      );
      final lot = building.lots.firstWhere(
        (l) => l.id == lotId,
        orElse: () => Lot(id: '', name: '', type: '', area: 0, rent: 0, rooms: 0, status: '', floor: '')
      );
      return lot.rent;
    }
    return 0;
  }

  Future<void> _savePayments() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(_payments.map((e) => e.toJson()).toList());
    await prefs.setString('payments', jsonString);
  }

  List<Payment> get _pendingPayments {
    return _payments.where((p) => p.status == 'pending').toList();
  }

  List<Payment> get _paidPayments {
    return _payments.where((p) => p.status == 'paid').toList();
  }

  double get _totalPending {
    return _pendingPayments.fold(0, (sum, p) => sum + p.amount);
  }

  double get _totalPaid {
    return _paidPayments.fold(0, (sum, p) => sum + p.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Paiements',
          style: GoogleFonts.urbanist(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: _buildSummaryCards(),
        ),
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _selectedIndex == 0
                ? _buildPendingList()
                : _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'À encaisser',
              amount: _totalPending,
              color: Colors.orange,
              icon: Icons.pending_actions,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: 'Encaissé',
              amount: _totalPaid,
              color: Colors.green,
              icon: Icons.check_circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.urbanist(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${amount.toStringAsFixed(2)} €',
            style: GoogleFonts.urbanist(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              title: 'Échéances',
              index: 0,
              count: _pendingPayments.length,
              isActive: _selectedIndex == 0,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              title: 'Historique',
              index: 1,
              count: _paidPayments.length,
              isActive: _selectedIndex == 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required int index,
    required int count,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E88E5) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? Colors.white : Colors.grey,
              ),
            ),
            if (count > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.urbanist(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isActive ? const Color(0xFF1E88E5) : Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingList() {
    if (_pendingPayments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Tous les loyers sont à jour !',
              style: GoogleFonts.urbanist(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingPayments.length,
      itemBuilder: (context, index) {
        final payment = _pendingPayments[index];
        return _buildPaymentCard(payment);
      },
    );
  }

  Widget _buildHistoryList() {
    if (_paidPayments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Aucun historique',
              style: GoogleFonts.urbanist(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _paidPayments.length,
      itemBuilder: (context, index) {
        final payment = _paidPayments[index];
        return _buildPaymentCard(payment, isHistory: true);
      },
    );
  }

  Widget _buildPaymentCard(Payment payment, {bool isHistory = false}) {
    final isLate = payment.isLate && !isHistory;
    
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentDetailsScreen(
                  payment: payment,
                  tenantName: payment.tenantName,
                  lotName: payment.lotName,
                ),
              ),
            );
            if (result == true) {
              _loadData();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: (isHistory ? Colors.green : (isLate ? Colors.red : Colors.orange)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isHistory ? Icons.receipt : (isLate ? Icons.warning : Icons.pending),
                    color: isHistory ? Colors.green : (isLate ? Colors.red : Colors.orange),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.tenantName,
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        payment.lotName,
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            payment.formattedAmount,
                            style: GoogleFonts.urbanist(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isHistory ? Colors.green : Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            payment.formattedDueDate,
                            style: GoogleFonts.urbanist(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          if (isLate && !isHistory)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'En retard',
                                style: GoogleFonts.urbanist(
                                  fontSize: 10,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isHistory)
                  ElevatedButton(
                    onPressed: () {
                      _validatePayment(payment);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Valider'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _validatePayment(Payment payment) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Valider le paiement',
            style: GoogleFonts.urbanist(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Locataire : ${payment.tenantName}'),
              const SizedBox(height: 8),
              Text('Montant : ${payment.formattedAmount}'),
              const SizedBox(height: 8),
              Text('Période : ${payment.formattedDueDate}'),
              const SizedBox(height: 16),
              Text(
                'Souhaitez-vous générer une quittance ?',
                style: GoogleFonts.urbanist(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                
                final updatedPayment = Payment(
                  id: payment.id,
                  tenantId: payment.tenantId,
                  tenantName: payment.tenantName,
                  buildingId: payment.buildingId,
                  lotId: payment.lotId,
                  lotName: payment.lotName,
                  amount: payment.amount,
                  dueDate: payment.dueDate,
                  paymentDate: DateTime.now(),
                  status: 'paid',
                );
                
                final index = _payments.indexWhere((p) => p.id == payment.id);
                setState(() {
                  _payments[index] = updatedPayment;
                });
                await _savePayments();
                
                _generateAndSendReceipt(updatedPayment);
              },
              child: Text(
                'Valider',
                style: GoogleFonts.urbanist(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _generateAndSendReceipt(Payment payment) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt, size: 60, color: Color(0xFF1E88E5)),
              const SizedBox(height: 16),
              Text(
                'Quittance de loyer',
                style: GoogleFonts.urbanist(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Montant : ${payment.formattedAmount}',
                style: GoogleFonts.urbanist(fontSize: 16),
              ),
              Text(
                'Date : ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: GoogleFonts.urbanist(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildSendButton(
                      icon: Icons.email,
                      label: 'Email',
                      color: Colors.blue,
                      onPressed: () async {
                        Navigator.pop(context);
                        final pdfBytes = await PdfService.generateReceiptBytes(payment);
                        await ShareService.sendEmail(payment.tenantName, pdfBytes);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSendButton(
                      icon: Icons.message,
                      label: 'WhatsApp',
                      color: Colors.green,
                      onPressed: () async {
                        Navigator.pop(context);
                        final pdfBytes = await PdfService.generateReceiptBytes(payment);
                        await ShareService.sendWhatsApp(payment.tenantName, pdfBytes);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Plus tard',
                  style: GoogleFonts.urbanist(color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSendButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: Colors.white),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}