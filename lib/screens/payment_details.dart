import 'package:flutter/material.dart';
import 'package:zitakimmo/services/pdf_service.dart';
import 'package:zitakimmo/models/payment.dart'; // Assure-toi que le chemin est correct

class PaymentDetailsScreen extends StatefulWidget {
  final Payment payment;
  const PaymentDetailsScreen({super.key, required this.payment});

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isGenerating = false;

  // Variables pré-remplies à partir du paiement reçu
  late String _tenantName;
  late String _propertyAddress; // Utilise lotName ou adresse si disponible
  late double _rentAmount;
  late double _chargesAmount;
  late double _totalAmount;
  late String _month;
  late String _paymentDate;
  late String _paymentMethod;
  late String _reference;

  @override
  void initState() {
    super.initState();
    // Initialiser les champs avec les données du paiement
    final p = widget.payment;
    _tenantName = p.tenantName;
    _propertyAddress = p.lotName; // On utilise le nom du lot comme adresse
    _rentAmount = p.amount; // Ici le loyer seul, mais on peut affiner
    _chargesAmount = 0.0; // Si ton modèle ne contient pas de charges, laisser 0
    _totalAmount = p.amount;

    // Mois à partir de dueDate
    _month = _formatMonth(p.dueDate);
    // Date de paiement : si déjà payé, utiliser paymentDate, sinon aujourd'hui
    _paymentDate = p.paymentDate != null
        ? _formatDate(p.paymentDate!)
        : _formatDate(DateTime.now());
    _paymentMethod = 'Virement'; // Valeur par défaut, à adapter si disponible
    _reference = p.id; // Utiliser l'ID du paiement comme référence
  }

  String _formatMonth(DateTime date) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

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
                onChanged: (value) =>
                    _rentAmount = double.tryParse(value) ?? 0,
              ),
              TextFormField(
                initialValue: _chargesAmount.toString(),
                decoration: const InputDecoration(labelText: 'Charges (€)'),
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                    _chargesAmount = double.tryParse(value) ?? 0,
              ),
              TextFormField(
                initialValue: _totalAmount.toString(),
                decoration: const InputDecoration(labelText: 'Total (€)'),
                keyboardType: TextInputType.number,
                onChanged: (value) =>
                    _totalAmount = double.tryParse(value) ?? 0,
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