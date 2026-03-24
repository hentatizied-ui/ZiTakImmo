// lib/services/share_service.dart
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareService {
  static Future<void> sendEmail(String recipient, Uint8List pdfBytes) async {
    // Pour le web, on utilise le partage via l'API
    final uri = Uri(
      scheme: 'mailto',
      path: recipient,
      query: 'subject=Quittance de loyer&body=Bonjour,\n\nVeuillez trouver ci-joint votre quittance de loyer.\n\nCordialement.',
    );
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback: partager le fichier
      await Share.shareXFiles(
        [XFile.fromData(pdfBytes, name: 'quittance.pdf', mimeType: 'application/pdf')],
        text: 'Quittance de loyer pour $recipient',
      );
    }
  }

  static Future<void> sendWhatsApp(String recipient, Uint8List pdfBytes) async {
    await Share.shareXFiles(
      [XFile.fromData(pdfBytes, name: 'quittance.pdf', mimeType: 'application/pdf')],
      text: 'Bonjour,\n\nVeuillez trouver ci-joint votre quittance de loyer.\n\nCordialement.',
    );
  }
}