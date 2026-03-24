import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../models/payment.dart';
import '../services/pdf_service.dart';

class PaymentDetailsScreen extends StatefulWidget {
  final Payment payment;
  final String tenantName;
  final String lotName;

  const PaymentDetailsScreen({
    super.key,
    required this.payment,
    required this.tenantName,
    required this.lotName,
  });

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Détails du paiement',
          style: GoogleFonts.urbanist(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildPaymentCard(),
            if (widget.payment.isPaid) ...[
              const SizedBox(height: 16),
              _buildActionsCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          const Icon(Icons.person, size: 50, color: Color(0xFF1E88E5)),
          const SizedBox(height: 12),
          Text(
            widget.tenantName,
            style: GoogleFonts.urbanist(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.lotName,
            style: GoogleFonts.urbanist(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          _buildInfoRow('Montant', widget.payment.formattedAmount),
          const Divider(),
          _buildInfoRow('Période', widget.payment.formattedDueDate),
          const Divider(),
          _buildInfoRow(
            'Statut',
            widget.payment.isPaid ? 'Payé' : 'En attente',
            valueColor: widget.payment.isPaid ? Colors.green : Colors.orange,
          ),
          if (widget.payment.paymentDate != null) ...[
            const Divider(),
            _buildInfoRow(
              'Date de paiement',
              '${widget.payment.paymentDate!.day}/${widget.payment.paymentDate!.month}/${widget.payment.paymentDate!.year}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.urbanist(fontSize: 14, color: Colors.grey),
          ),
          Text(
            value,
            style: GoogleFonts.urbanist(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Text(
            'Quittance disponible',
            style: GoogleFonts.urbanist(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.picture_as_pdf,
                  label: 'Voir PDF',
                  color: Colors.red,
                  onPressed: _generateAndViewPDF,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.share,
                  label: 'Partager',
                  color: Colors.blue,
                  onPressed: _sharePDF,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
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

  Future<void> _generateAndViewPDF() async {
    setState(() {
      _isGenerating = true;
    });
    final pdfBytes = await PdfService.generateReceiptBytes(widget.payment);
    setState(() {
      _isGenerating = false;
    });
    PdfService.openInNewTab(widget.payment, pdfBytes);
  }

  Future<void> _sharePDF() async {
    setState(() {
      _isGenerating = true;
    });
    final pdfBytes = await PdfService.generateReceiptBytes(widget.payment);
    setState(() {
      _isGenerating = false;
    });
    await Share.shareXFiles(
      [XFile.fromData(pdfBytes, name: 'quittance.pdf', mimeType: 'application/pdf')],
      text: 'Quittance de loyer',
    );
  }
}