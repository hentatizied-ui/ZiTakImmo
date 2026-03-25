import 'package:flutter/material.dart';
import 'package:zitakimmo/services/pdf_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class PaymentDetailsScreen extends StatefulWidget {
  @override
  _PaymentDetailsScreenState createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  // Contrôleurs et variables
  final _formKey = GlobalKey<FormState>();
  bool _isGenerating = false;

  // Exemples de données (remplace par tes propres données)
  String _tenantName = 'Jean Dupont';
  String _propertyAddress = '12 rue de Paris, 75001 Paris';
  double _rentAmount = 800.0;
  double _chargesAmount = 150.0;
  double _totalAmount = 950.0;
  String _month = 'Mars 2026';
  String _paymentDate = '25/03/2026';
  String _paymentMethod = 'Virement bancaire';
  String _reference = 'QUIT-2026-001';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du paiement'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _tenantName,
                decoration: const InputDecoration(labelText: 'Locataire'),
                onChanged: (value) => _tenantName = value,
              ),
              TextFormField(
                initialValue: _propertyAddress,
                decoration: const InputDecoration(labelText: 'Adresse du bien'),
                onChanged: (value) => _propertyAddress = value,
              ),
              TextFormField(
                initialValue: _rentAmount.toString(),
                decoration: const InputDecoration(labelText: 'Loyer (€)'),
                keyboardType: TextInputType.number,
                onChanged: (value) => _rentAmount = double.tryParse(value) ?? 0,
              ),
              TextFormField(
                initialValue: _chargesAmount.toString(),
                decoration: const InputDecoration(labelText: 'Charges (€)'),
                keyboardType: TextInputType.number,
                onChanged: (value) => _chargesAmount = double.tryParse(value) ?? 0,
              ),
              TextFormField(
                initialValue: _totalAmount.toString(),
                decoration: const InputDecoration(labelText: 'Total (€)'),
                keyboardType: TextInputType.number,
                onChanged: (value) => _totalAmount = double.tryParse(value) ?? 0,
              ),
              TextFormField(
                initialValue: _month,
                decoration: const InputDecoration(labelText: 'Mois'),
                onChanged: (value) => _month = value,
              ),
              TextFormField(
                initialValue: _paymentDate,
                decoration: const InputDecoration(labelText: 'Date de paiement'),
                onChanged: (value) => _paymentDate = value,
              ),
              TextFormField(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(labelText: 'Mode de paiement'),
                onChanged: (value) => _paymentMethod = value,
              ),
              TextFormField(
                initialValue: _reference,
                decoration: const InputDecoration(labelText: 'Référence'),
                onChanged: (value) => _reference = value,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isGenerating ? null : _generateAndShare,
                child: _isGenerating
                    ? const CircularProgressIndicator()
                    : const Text('Générer et partager le PDF'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateAndShare() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isGenerating = true);

    try {
      final file = await PdfService.generateAndSave(
        tenantName: _tenantName,
        propertyAddress: _propertyAddress,
        rentAmount: _rentAmount,
        chargesAmount: _chargesAmount,
        totalAmount: _totalAmount,
        month: _month,
        paymentDate: _paymentDate,
        paymentMethod: _paymentMethod,
        reference: _reference,
      );

      if (file != null) {
        // Proposer le partage après génération
        final shouldShare = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('PDF généré'),
            content: const Text('Voulez-vous partager ce PDF ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Ouvrir'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Partager'),
              ),
            ],
          ),
        );

        if (shouldShare == true) {
          await PdfService.sharePDF(file);
        } else {
          await PdfService.openPDF(file);
        }

        // Optionnel : supprimer le fichier après un certain temps
        // await PdfService.deletePDF(file);
      } else {
        _showSnackBar('Erreur lors de la génération du PDF');
      }
    } catch (e) {
      _showSnackBar('Une erreur est survenue : $e');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}