import 'dart:html' as html;
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as uh;
import '../models/payment.dart';

class PdfService {
  static Future<Uint8List> generateReceiptBytes(Payment payment) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(payment),
          pw.SizedBox(height: 20),
          _buildTitle(),
          pw.SizedBox(height: 30),
          _buildInfo(payment),
          pw.SizedBox(height: 30),
          _buildTable(payment),
          pw.SizedBox(height: 40),
          _buildFooter(),
        ],
      ),
    );
    
    return await pdf.save();
  }

  static void downloadReceipt(Payment payment, Uint8List bytes) {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..target = 'blank'
      ..download = 'quittance_${payment.id}.pdf';
    anchor.click();
    html.Url.revokeObjectUrl(url);
  }

  static void openInNewTab(Payment payment, Uint8List bytes) {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    uh.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
  }

  static pw.Widget _buildHeader(Payment payment) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'QUITTANCE DE LOYER',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text('N° ${payment.id.substring(0, 8)}'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Date d\'émission'),
            pw.Text(
              '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTitle() {
    return pw.Center(
      child: pw.Text(
        'QUITTANCE DE LOYER',
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildInfo(Payment payment) {
    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Locataire : ${payment.tenantName}'),
          pw.SizedBox(height: 8),
          pw.Text('Bien : ${payment.lotName}'),
          pw.SizedBox(height: 8),
          pw.Text('Période concernée : ${_formatDate(payment.dueDate)}'),
        ],
      ),
    );
  }

  static pw.Widget _buildTable(Payment payment) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableCell('Désignation', fontWeight: pw.FontWeight.bold),
            _buildTableCell('Montant', fontWeight: pw.FontWeight.bold, alignment: pw.Alignment.centerRight),
          ],
        ),
        pw.TableRow(
          children: [
            _buildTableCell('Loyer mensuel'),
            _buildTableCell(payment.formattedAmount, alignment: pw.Alignment.centerRight),
          ],
        ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey50),
          children: [
            _buildTableCell('Charges', fontWeight: pw.FontWeight.bold),
            _buildTableCell('0,00 €', alignment: pw.Alignment.centerRight, fontWeight: pw.FontWeight.bold),
          ],
        ),
        pw.TableRow(
          children: [
            _buildTableCell('TOTAL', fontWeight: pw.FontWeight.bold),
            _buildTableCell(
              payment.formattedAmount,
              alignment: pw.Alignment.centerRight,
              fontWeight: pw.FontWeight.bold,
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    pw.Alignment alignment = pw.Alignment.centerLeft,
    pw.FontWeight? fontWeight,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.all(12),
      alignment: alignment,
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: fontWeight),
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              children: [
                pw.Text('Signature du locataire'),
                pw.SizedBox(height: 40),
                pw.Text('(précédée de la mention "lu et approuvé")'),
              ],
            ),
            pw.Column(
              children: [
                pw.Text('Signature du bailleur'),
                pw.SizedBox(height: 40),
                pw.Text('(Cachet de l\'agence)'),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 40),
        pw.Text(
          'Cette quittance tient lieu de reçu pour le paiement du loyer et des charges.',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}