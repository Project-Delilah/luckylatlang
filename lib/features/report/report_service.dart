import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/birth_profile.dart';
import '../../models/city_spot.dart';

// ── Brand palette ──────────────────────────────────────────────────────────────
const _coral = PdfColor(0.800, 0.471, 0.361);       // #CC785C
const _ink = PdfColor(0.078, 0.078, 0.075);         // #141413
const _body = PdfColor(0.239, 0.239, 0.227);        // #3D3D3A
const _muted = PdfColor(0.424, 0.416, 0.392);       // #6C6A64
const _card = PdfColor(0.937, 0.914, 0.871);        // #EFE9DE
const _hairline = PdfColor(0.902, 0.875, 0.847);    // #E6DFD8
const _lucky = PdfColor(0.365, 0.722, 0.447);       // #5DB872
const _challenging = PdfColor(0.776, 0.271, 0.271); // #C64545
const _neutral = PdfColor(0.910, 0.647, 0.353);     // #E8A55A

// Mix color c with white; white=1.0 gives pure white, white=0.0 gives pure c.
PdfColor _tint(PdfColor c, double white) => PdfColor(
      c.red + (1 - c.red) * white,
      c.green + (1 - c.green) * white,
      c.blue + (1 - c.blue) * white,
    );

Future<void> shareReport(BirthProfile profile, List<CitySpot> allSpots) async {
  final bytes = await _buildPdf(profile, allSpots);
  final safeName = profile.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  await Printing.sharePdf(bytes: bytes, filename: 'luckylatlang_$safeName.pdf');
}

Future<Uint8List> _buildPdf(BirthProfile profile, List<CitySpot> allSpots) async {
  pw.Font displayBold, bodyReg, bodyMed, bodyBold;
  try {
    displayBold = await PdfGoogleFonts.cormorantGaramondBold();
    bodyReg = await PdfGoogleFonts.interRegular();
    bodyMed = await PdfGoogleFonts.interMedium();
    bodyBold = await PdfGoogleFonts.interBold();
  } catch (_) {
    displayBold = pw.Font.helveticaBold();
    bodyReg = pw.Font.helvetica();
    bodyMed = pw.Font.helveticaBold();
    bodyBold = pw.Font.helveticaBold();
  }

  final lucky = (allSpots.where((s) => s.rating == SpotRating.lucky).toList()
        ..sort((a, b) => b.score.compareTo(a.score)))
      .take(10)
      .toList();
  final challenging = (allSpots
          .where((s) => s.rating == SpotRating.challenging)
          .toList()
        ..sort((a, b) => a.score.compareTo(b.score)))
      .take(5)
      .toList();

  final doc = pw.Document(
    author: 'Sapan Gajjar',
    title: "Lucky Lat·Lang — ${profile.name}'s Report",
  );

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: pw.EdgeInsets.zero,
    footer: (ctx) => pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _hairline, width: 0.5)),
      ),
      padding: const pw.EdgeInsets.fromLTRB(40, 10, 40, 14),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated ${DateFormat('d MMM yyyy').format(DateTime.now())}',
            style: pw.TextStyle(font: bodyReg, fontSize: 8, color: _muted),
          ),
          pw.UrlLink(
            destination: 'https://github.com/isg32',
            child: pw.Text(
              'Lucky Lat·Lang  ·  Sapan Gajjar',
              style: pw.TextStyle(font: bodyReg, fontSize: 8, color: _coral),
            ),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: pw.TextStyle(font: bodyReg, fontSize: 8, color: _muted),
          ),
        ],
      ),
    ),
    build: (ctx) => [
      // ── Coral branded header ───────────────────────────────────────────
      pw.Container(
        color: _coral,
        padding: const pw.EdgeInsets.fromLTRB(40, 44, 40, 40),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Lucky Lat·Lang',
                    style: pw.TextStyle(
                        font: displayBold, fontSize: 40, color: PdfColors.white),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'ASTROCARTOGRAPHY REPORT',
                    style: pw.TextStyle(
                        font: bodyMed,
                        fontSize: 9,
                        color: PdfColors.white,
                        letterSpacing: 2.5),
                  ),
                ],
              ),
            ),
            // Decorative accent bar
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(
                  width: 3,
                  height: 44,
                  color: PdfColor(1, 1, 1, 0.35),
                ),
              ],
            ),
          ],
        ),
      ),

      // ── Profile section ────────────────────────────────────────────────
      pw.Container(
        color: _card,
        padding: const pw.EdgeInsets.fromLTRB(40, 28, 40, 28),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              profile.name,
              style: pw.TextStyle(font: displayBold, fontSize: 28, color: _ink),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Born ${DateFormat('d MMMM yyyy').format(profile.birthDateTime)}'
              ' at ${DateFormat('HH:mm').format(profile.birthDateTime)}',
              style: pw.TextStyle(font: bodyReg, fontSize: 11, color: _body),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              profile.cityName,
              style: pw.TextStyle(font: bodyReg, fontSize: 11, color: _muted),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              children: [
                _statChip(lucky.length.toString(), 'Lucky cities', _lucky,
                    displayBold, bodyReg),
                pw.SizedBox(width: 12),
                _statChip(challenging.length.toString(), 'Challenging',
                    _challenging, displayBold, bodyReg),
                pw.SizedBox(width: 12),
                _statChip(allSpots.length.toString(), 'Total analysed', _muted,
                    displayBold, bodyReg),
              ],
            ),
          ],
        ),
      ),

      // ── Content ────────────────────────────────────────────────────────
      pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(40, 32, 40, 24),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (lucky.isNotEmpty) ...[
              _sectionHeader('Lucky Destinations', lucky.length, _lucky,
                  displayBold, bodyMed),
              pw.SizedBox(height: 16),
              ...lucky.map(
                  (c) => _cityBlock(c, displayBold, bodyReg, bodyMed, bodyBold)),
              if (challenging.isNotEmpty) pw.SizedBox(height: 28),
            ],
            if (challenging.isNotEmpty) ...[
              _sectionHeader('Challenging Destinations', challenging.length,
                  _challenging, displayBold, bodyMed),
              pw.SizedBox(height: 16),
              ...challenging.map(
                  (c) => _cityBlock(c, displayBold, bodyReg, bodyMed, bodyBold)),
            ],
            if (allSpots.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 40),
                child: pw.Text(
                  'No city data available. Ensure a profile is set and map has loaded.',
                  style: pw.TextStyle(font: bodyReg, fontSize: 11, color: _muted),
                ),
              ),

            // ── Links ───────────────────────────────────────────────────
            pw.SizedBox(height: 32),
            pw.Divider(color: _hairline, height: 1, thickness: 0.5),
            pw.SizedBox(height: 16),
            pw.Row(
              children: [
                pw.UrlLink(
                  destination: 'https://github.com/Project-Delilah/luckylatlang/releases',
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: pw.BoxDecoration(
                      color: _coral,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Text(
                      'Download App',
                      style: pw.TextStyle(font: bodyBold, fontSize: 9, color: PdfColors.white),
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.UrlLink(
                  destination: 'https://github.com/Project-Delilah/luckylatlang',
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: _hairline, width: 0.8),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Text(
                      'View on GitHub',
                      style: pw.TextStyle(font: bodyMed, fontSize: 9, color: _body),
                    ),
                  ),
                ),
                pw.Spacer(),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Made by',
                      style: pw.TextStyle(font: bodyReg, fontSize: 8, color: _muted),
                    ),
                    pw.SizedBox(height: 2),
                    pw.UrlLink(
                      destination: 'https://github.com/isg32',
                      child: pw.Text(
                        'Sapan Gajjar',
                        style: pw.TextStyle(font: bodyBold, fontSize: 10, color: _coral),
                      ),
                    ),
                    pw.UrlLink(
                      destination: 'https://github.com/isg32',
                      child: pw.Text(
                        'github.com/isg32',
                        style: pw.TextStyle(font: bodyReg, fontSize: 8, color: _muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
          ],
        ),
      ),
    ],
  ));

  return doc.save();
}

// ── Stat chip ──────────────────────────────────────────────────────────────────

pw.Widget _statChip(
    String value, String label, PdfColor accent, pw.Font bold, pw.Font reg) {
  return pw.Container(
    padding: const pw.EdgeInsets.fromLTRB(14, 10, 14, 10),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: accent, width: 0.8),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(value,
            style: pw.TextStyle(font: bold, fontSize: 20, color: _ink)),
        pw.SizedBox(height: 2),
        pw.Text(label,
            style: pw.TextStyle(font: reg, fontSize: 8, color: _muted)),
      ],
    ),
  );
}

// ── Section header ─────────────────────────────────────────────────────────────

pw.Widget _sectionHeader(
    String title, int count, PdfColor accent, pw.Font displayBold, pw.Font bodyMed) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(width: 4, height: 24, color: accent),
          pw.SizedBox(width: 10),
          pw.Text(title,
              style: pw.TextStyle(font: displayBold, fontSize: 20, color: _ink)),
          pw.Spacer(),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: pw.BoxDecoration(
              color: _tint(accent, 0.84),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              count == 1 ? '1 CITY' : '$count CITIES',
              style: pw.TextStyle(
                  font: bodyMed, fontSize: 8, color: accent, letterSpacing: 0.8),
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Divider(color: _hairline, height: 1, thickness: 0.5),
    ],
  );
}

// ── City block ─────────────────────────────────────────────────────────────────

pw.Widget _cityBlock(
  CitySpot city,
  pw.Font displayBold,
  pw.Font bodyReg,
  pw.Font bodyMed,
  pw.Font bodyBold,
) {
  final ratingColor = switch (city.rating) {
    SpotRating.lucky => _lucky,
    SpotRating.challenging => _challenging,
    SpotRating.neutral => _neutral,
  };
  final top = city.influences.take(2).toList();

  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 12),
    child: pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _hairline, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // City name + rating pill
          pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: pw.BoxDecoration(
              color: _card,
              borderRadius:
                  const pw.BorderRadius.vertical(top: pw.Radius.circular(8)),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(city.cityName,
                          style: pw.TextStyle(
                              font: displayBold, fontSize: 15, color: _ink)),
                      pw.SizedBox(height: 2),
                      pw.Text(city.countryName,
                          style: pw.TextStyle(
                              font: bodyReg, fontSize: 9, color: _muted)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: _tint(ratingColor, 0.84),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(20)),
                  ),
                  child: pw.Text(
                    city.ratingLabel.toUpperCase(),
                    style: pw.TextStyle(
                        font: bodyMed,
                        fontSize: 8,
                        color: ratingColor,
                        letterSpacing: 0.8),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Text(
                  city.score.toStringAsFixed(1),
                  style: pw.TextStyle(font: bodyBold, fontSize: 13, color: _ink),
                ),
              ],
            ),
          ),
          // Planetary influences
          if (top.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < top.length; i++) ...[
                    pw.Row(
                      children: [
                        pw.Text(
                          '${top[i].planet.displayName} ${top[i].type.displayName}',
                          style: pw.TextStyle(
                              font: bodyBold, fontSize: 9, color: _ink),
                        ),
                        pw.Text(
                          '  ·  ${top[i].distanceKm.round()} km'
                          '  ·  ${(top[i].strength * 100).round()}% strength',
                          style: pw.TextStyle(
                              font: bodyReg, fontSize: 9, color: _muted),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      top[i].interpretation,
                      style: pw.TextStyle(font: bodyReg, fontSize: 9, color: _body),
                    ),
                    if (i < top.length - 1) pw.SizedBox(height: 8),
                  ],
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
