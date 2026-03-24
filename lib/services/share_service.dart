import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

class ShareService {
  static Future<void> sendEmail(String recipient, Uint8List pdfBytes) async {
    await Share.shareXFiles(
      [XFile.fromData(pdfBytes, name: 'quittance.pdf', mimeType: 'application/pdf')],
      text: 'Bonjour,\n\nVeuillez trouver ci-joint votre quittance de loyer.\n\nCordialement.',
    );
  }

  static Future<void> sendWhatsApp(String recipient, Uint8List pdfBytes) async {
    await Share.shareXFiles(
      [XFile.fromData(pdfBytes, name: 'quittance.pdf', mimeType: 'application/pdf')],
      text: 'Bonjour,\n\nVeuillez trouver ci-joint votre quittance de loyer.\n\nCordialement.',
    );
  }
}