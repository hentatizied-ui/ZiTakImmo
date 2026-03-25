import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tenant.dart';
import '../models/payment.dart';
import '../models/property.dart';
import '../services/pdf_service.dart';

class TenantPaymentsScreen extends StatefulWidget {
  final Tenant tenant;

  const TenantPaymentsScreen({super.key, required this.tenant});

  @override
  State<TenantPaymentsScreen> createState() => _TenantPaymentsScreenState();
}

class _TenantPaymentsScreenState extends State<TenantPaymentsScreen> {
  List<Payment> _payments = [];
  double _monthlyRent = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    await _getMonthlyRent();
    await _loadPayments();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getMonthlyRent() async {
    if (widget.tenant.buildingId == null || widget.tenant.lotId == null) {
      _monthlyRent = 0;
      return;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final String? buildingsJson = prefs.getString('buildings');
    if (buildingsJson != null && buildingsJson.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(buildingsJson);
      final buildings = decoded.map((e) => Immeuble.fromJson(e)).toList();
      final building = buildings.firstWhere(
        (b) => b.id == widget.tenant.buildingId,
        orElse: () => Immeuble(id: '', name: '', address: '', lots: [])
      );
      final lot = building.lots.firstWhere(
        (l) => l.id == widget.tenant.lotId,
        orElse: () => Lot(id: '', name: '', type: '', area: 0, rent: 0, rooms: 0, status: '', floor: '')
      );
      _monthlyRent = lot.rent;
    }
  }

  Future<void> _loadPayments() async {
    final prefs = await SharedPreferences.getInstance();
    final String? paymentsJson = prefs.getString('payments');
    
    List<Payment> existingPayments = [];
    if (paymentsJson != null && paymentsJson.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(paymentsJson);
      existingPayments = decoded.map((e) => Payment.fromJson(e)).toList();
      existingPayments = existingPayments.where((p) => p.tenantId == widget.tenant.id).toList();
    }
    
    final now = DateTime.now();
    final startDate = widget.tenant.startDate;
    final payments = <Payment>[];
    
    DateTime current = DateTime(startDate.year, startDate.month, 5);
    while (current.isBefore(DateTime(now.year, now.month + 12, 5))) {
      final existingPayment = existingPayments.firstWhere(
        (p) => p.dueDate.year == current.year && p.dueDate.month == current.month,
        orElse: () => Payment(
          id: '',
          tenantId: widget.tenant.id,
          tenantName: widget.tenant.fullName,
          buildingId: widget.tenant.buildingId ?? '',
          lotId: widget.tenant.lotId ?? '',
          lotName: 'Lot ${widget.tenant.lotId}',
          amount: _monthlyRent,
          dueDate: current,
          status: 'pending',
        ),
      );
      
      payments.add(Payment(
        id: existingPayment.id.isNotEmpty ? existingPayment.id : '${widget.tenant.id}_${current.year}_${current.month}',
        tenantId: widget.tenant.id,
        tenantName: widget.tenant.fullName,
        buildingId: widget.tenant.buildingId ?? '',
        lotId: widget.tenant.lotId ?? '',
        lotName: 'Lot ${widget.tenant.lotId}',
        amount: _monthlyRent,
        dueDate: current,
        paymentDate: existingPayment.paymentDate,
        status: existingPayment.status,
      ));
      
      current = DateTime(current.year, current.month + 1, 5);
    }
    
    setState(() {
      _payments = payments;
    });
    await _savePayments();
  }

  Future<void> _savePayments() async {
    final prefs = await SharedPreferences.getInstance();
    final String? allPaymentsJson = prefs.getString('payments');
    List<Payment> allPayments = [];
    
    if (allPaymentsJson != null && allPaymentsJson.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(allPaymentsJson);
      allPayments = decoded.map((e) => Payment.fromJson(e)).toList();
    }
    
    allPayments.removeWhere((p) => p.tenantId == widget.tenant.id);
    allPayments.addAll(_payments);
    
    final String jsonString = jsonEncode(allPayments.map((e) => e.toJson()).toList());
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

  Future<void> _validatePayment(Payment payment) async {
    final now = DateTime.now();
    final isLate = payment.dueDate.isBefore(now);
    
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
              Text('Période : ${_formatMonth(payment.dueDate)}'),
              const SizedBox(height: 8),
              Text('Montant : ${payment.formattedAmount}'),
              const SizedBox(height: 8),
              if (isLate)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'Paiement en retard',
                        style: GoogleFonts.urbanist(color: Colors.red),
                      ),
                    ],
                  ),
                ),
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
              child: Text(
                'Annuler',
                style: GoogleFonts.urbanist(color: const Color(0xFF757575)),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                _confirmPayment(payment, generateReceipt: false);
              },
              child: Text(
                'Valider sans quittance',
                style: GoogleFonts.urbanist(color: Colors.blue),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                _confirmPayment(payment, generateReceipt: true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Valider et quittance'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmPayment(Payment payment, {required bool generateReceipt}) async {
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
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paiement validé pour ${_formatMonth(payment.dueDate)}'),
          backgroundColor: Colors.green,
        ),
      );
    }
    
    if (generateReceipt) {
      _generateAndSendReceipt(updatedPayment);
    }
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
                'Période : ${_formatMonth(payment.dueDate)}',
                style: GoogleFonts.urbanist(fontSize: 16),
              ),
              Text(
                'Montant : ${payment.formattedAmount}',
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
                        await PdfService.shareReceipt(payment, pdfBytes);
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
                        await PdfService.shareReceipt(payment, pdfBytes);
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

  void _viewReceipt(Payment payment) {
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
                'Période : ${_formatMonth(payment.dueDate)}',
                style: GoogleFonts.urbanist(fontSize: 16),
              ),
              Text(
                'Montant : ${payment.formattedAmount}',
                style: GoogleFonts.urbanist(fontSize: 14, color: Colors.grey),
              ),
              Text(
                'Payé le : ${payment.paymentDate!.day}/${payment.paymentDate!.month}/${payment.paymentDate!.year}',
                style: GoogleFonts.urbanist(fontSize: 14, color: Colors.green),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildSendButton(
                      icon: Icons.picture_as_pdf,
                      label: 'Ouvrir PDF',
                      color: Colors.red,
                      onPressed: () async {
                        Navigator.pop(context);
                        final pdfBytes = await PdfService.generateReceiptBytes(payment);
                        await PdfService.openReceipt(payment, pdfBytes);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSendButton(
                      icon: Icons.share,
                      label: 'Partager',
                      color: Colors.blue,
                      onPressed: () async {
                        Navigator.pop(context);
                        final pdfBytes = await PdfService.generateReceiptBytes(payment);
                        await PdfService.shareReceipt(payment, pdfBytes);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Fermer',
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

  String _formatMonth(DateTime date) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _getStatusText(String status, DateTime dueDate) {
    if (status == 'paid') return 'Payé';
    if (dueDate.isBefore(DateTime.now())) return 'En retard';
    return 'En attente';
  }

  Color _getStatusColor(String status, DateTime dueDate) {
    if (status == 'paid') return Colors.green;
    if (dueDate.isBefore(DateTime.now())) return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.tenant.fullName,
              style: GoogleFonts.urbanist(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Historique des paiements',
              style: GoogleFonts.urbanist(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryCards(),
                _buildInfoCard(),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildPaymentsList(),
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
              title: 'À payer',
              amount: _totalPending,
              color: Colors.orange,
              icon: Icons.pending_actions,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: 'Payé',
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
            color: Colors.grey.withValues(alpha: 0.1),
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

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 20, color: Color(0xFF1E88E5)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Entrée le ${widget.tenant.startDate.day}/${widget.tenant.startDate.month}/${widget.tenant.startDate.year}',
                  style: GoogleFonts.urbanist(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  'Loyer mensuel : ${_monthlyRent.toStringAsFixed(2)} €',
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E88E5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final payment = _payments[index];
        final isPaid = payment.status == 'paid';
        final isLate = !isPaid && payment.dueDate.isBefore(DateTime.now());
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getStatusColor(payment.status, payment.dueDate).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPaid ? Icons.check_circle : (isLate ? Icons.warning : Icons.pending),
                    color: _getStatusColor(payment.status, payment.dueDate),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatMonth(payment.dueDate),
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        payment.formattedAmount,
                        style: GoogleFonts.urbanist(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      if (isPaid && payment.paymentDate != null)
                        Text(
                          'Payé le ${payment.paymentDate!.day}/${payment.paymentDate!.month}/${payment.paymentDate!.year}',
                          style: GoogleFonts.urbanist(
                            fontSize: 10,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(payment.status, payment.dueDate).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(payment.status, payment.dueDate),
                    style: GoogleFonts.urbanist(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(payment.status, payment.dueDate),
                    ),
                  ),
                ),
                if (isPaid) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.receipt, color: Color(0xFF1E88E5)),
                    onPressed: () => _viewReceipt(payment),
                    tooltip: 'Voir la quittance',
                  ),
                ],
                if (!isPaid) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.payment, color: Colors.green),
                    onPressed: () => _validatePayment(payment),
                    tooltip: 'Valider le paiement',
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}