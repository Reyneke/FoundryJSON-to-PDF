import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:foundry_json_to_pdf/models/foundry_character.dart';
import 'package:foundry_json_to_pdf/screens/screen_converterWindow.dart';

/// Service for generating PDF character sheets from [FoundryCharacter] data.
class PdfGenerator {
  /// Generates a PDF byte array from the given [character] data for the specified [system].
  ///
  /// The generated PDF is a formatted character sheet suitable for printing or sharing.
  static Future<Uint8List> generate({
    required FoundryCharacter character,
    required SupportedSystem system,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(character),
          pw.SizedBox(height: 16),
          _buildSystemLabel(system),
          pw.SizedBox(height: 16),
          _buildAttributesSection(character),
          pw.SizedBox(height: 16),
          _buildSkillsSection(character),
          pw.SizedBox(height: 16),
          _buildDerivedStatsSection(character),
          pw.SizedBox(height: 16),
          _buildItemsSection(character),
        ],
      ),
    );

    return pdf.save();
  }

  /// Builds the header section with character name and basic info.
  static pw.Widget _buildHeader(FoundryCharacter character) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          character.name,
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          children: [
            if (character.metatype.isNotEmpty)
              _buildInfoChip('Metatyp', character.metatype),
            if (character.mortype.isNotEmpty)
              _buildInfoChip('Typ', character.mortype),
            if (character.gender.isNotEmpty)
              _buildInfoChip('Geschlecht', character.gender),
          ],
        ),
        if (character.generatorName.isNotEmpty ||
            character.generatorVersion.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(
              'Erstellt mit ${character.generatorName} v${character.generatorVersion}',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          ),
      ],
    );
  }

  /// Builds a small info chip for displaying key-value metadata.
  static pw.Widget _buildInfoChip(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(right: 12),
      child: pw.Text(
        '$label: $value',
        style: const pw.TextStyle(fontSize: 12),
      ),
    );
  }

  /// Builds the system label indicating which RPG system was used.
  static pw.Widget _buildSystemLabel(SupportedSystem system) {
    final systemNames = {
      SupportedSystem.shadowrun6: 'Shadowrun 6',
      SupportedSystem.dud2014: 'Dungeons & Dragons 2014',
      SupportedSystem.dud2024: 'Dungeons & Dragons 2024',
      SupportedSystem.dsa: 'Das Schwarze Auge',
    };

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        'System: ${systemNames[system] ?? 'Unbekannt'}',
        style: pw.TextStyle(
          fontSize: 11,
          color: PdfColors.blueGrey700,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  /// Builds the attributes section of the character sheet.
  static pw.Widget _buildAttributesSection(FoundryCharacter character) {
    if (character.attributes.isEmpty) return pw.SizedBox.shrink();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Attribute'),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(3),
          },
          children: [
            _buildTableHeader(['Attribut', 'Basis', 'Mod', 'Beschreibung']),
            ...character.attributes.entries.map((entry) {
              final attr = entry.value;
              return _buildTableRow([
                _getAttributeDisplayName(entry.key),
                attr.base.toString(),
                attr.mod != 0 ? attr.mod.toString() : '-',
                attr.modString,
              ]);
            }),
          ],
        ),
      ],
    );
  }

  /// Builds the skills section of the character sheet.
  static pw.Widget _buildSkillsSection(FoundryCharacter character) {
    if (character.skills.isEmpty) return pw.SizedBox.shrink();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Fertigkeiten'),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(3),
          },
          children: [
            _buildTableHeader(['Fertigkeit', 'Punkte', 'Mod', 'Beschreibung']),
            ...character.skills.entries
                .where((e) => e.value.points > 0 || e.value.modString.isNotEmpty)
                .map((entry) {
              final skill = entry.value;
              return _buildTableRow([
                _getSkillDisplayName(entry.key),
                skill.points.toString(),
                skill.modifier != 0 ? skill.modifier.toString() : '-',
                skill.modString,
              ]);
            }),
          ],
        ),
      ],
    );
  }

  /// Builds the derived stats section (composure, defense, etc.).
  static pw.Widget _buildDerivedStatsSection(FoundryCharacter character) {
    if (character.derived.isEmpty &&
        character.resist.isEmpty &&
        character.physical.base == 0 &&
        character.stun.base == 0) {
      return pw.SizedBox.shrink();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Abgeleitete Werte'),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(3),
          },
          children: [
            _buildTableHeader(['Wert', 'Basis', 'Mod', 'Pool']),
            ...character.derived.entries.map((entry) {
              final stat = entry.value;
              return _buildTableRow([
                _getDerivedDisplayName(entry.key),
                stat.base.toString(),
                stat.mod != 0 ? stat.mod.toString() : '-',
                stat.pool.toString(),
              ]);
            }),
            // Physical and Stun monitors
            if (character.physical.base > 0)
              _buildTableRow([
                'Körperlicher Monitor',
                character.physical.base.toString(),
                character.physical.mod != 0
                    ? character.physical.mod.toString()
                    : '-',
                character.physical.value.toString(),
              ]),
            if (character.stun.base > 0)
              _buildTableRow([
                'Geistiger Monitor',
                character.stun.base.toString(),
                character.stun.mod != 0
                    ? character.stun.mod.toString()
                    : '-',
                character.stun.value.toString(),
              ]),
            // Edge
            if (character.edge.isNotEmpty)
              _buildTableRow([
                'Edge',
                character.edge['value']?.toString() ?? '0',
                '-',
                character.edge['max']?.toString() ?? '0',
              ]),
            // Nuyen
            if (character.nuyen > 0)
              _buildTableRow([
                'Nuyen',
                character.nuyen.toString(),
                '-',
                '-',
              ]),
          ],
        ),
      ],
    );
  }

  /// Builds the items section (gear, spells, qualities, contacts).
  static pw.Widget _buildItemsSection(FoundryCharacter character) {
    if (character.items.isEmpty) return pw.SizedBox.shrink();

    // Group items by type
    final grouped = <String, List<CharacterItem>>{};
    for (final item in character.items) {
      grouped.putIfAbsent(item.type, () => []).add(item);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Ausrüstung & Gegenstände'),
        pw.SizedBox(height: 8),
        ...grouped.entries.map((entry) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
                child: pw.Text(
                  _getItemTypeDisplayName(entry.key),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey700,
                  ),
                ),
              ),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1),
                },
                children: [
                  _buildTableHeader(['Name', 'Kategorie', 'Preis']),
                  ...entry.value.map((item) => _buildTableRow([
                        item.name,
                        item.category ?? item.subtype ?? '-',
                        item.price != null ? '${item.price}¥' : '-',
                      ])),
                ],
              ),
            ],
          );
        }),
      ],
    );
  }

  /// Builds a section title with a bottom border.
  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blueGrey, width: 2),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blueGrey800,
        ),
      ),
    );
  }

  /// Builds a table header row.
  static pw.TableRow _buildTableHeader(List<String> headers) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
      children: headers
          .map((h) => pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  h,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey800,
                  ),
                ),
              ))
          .toList(),
    );
  }

  /// Builds a table data row.
  static pw.TableRow _buildTableRow(List<dynamic> cells) {
    return pw.TableRow(
      children: cells
          .map((c) => pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  c.toString(),
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ))
          .toList(),
    );
  }

  /// Maps attribute keys to human-readable names.
  static String _getAttributeDisplayName(String key) {
    const names = {
      'bod': 'Konstitution',
      'agi': 'Geschicklichkeit',
      'rea': 'Reaktion',
      'str': 'Stärke',
      'wil': 'Willenskraft',
      'log': 'Logik',
      'int': 'Intuition',
      'cha': 'Charisma',
      'mag': 'Magie',
      'res': 'Widerstand',
    };
    return names[key] ?? key;
  }

  /// Maps skill keys to human-readable names.
  static String _getSkillDisplayName(String key) {
    const names = {
      'astral': 'Astral',
      'athletics': 'Athletik',
      'biotech': 'Biotech',
      'close_combat': 'Nahkampf',
      'con': 'Überreden',
      'conjuring': 'Beschwörung',
      'cracking': 'Cracking',
      'electronics': 'Elektronik',
      'enchanting': 'Verzaubern',
      'engineering': 'Technik',
      'exotic_weapons': 'Exotische Waffen',
      'firearms': 'Feuerwaffen',
      'influence': 'Einfluss',
      'outdoors': 'Natur',
      'perception': 'Wahrnehmung',
      'piloting': 'Pilot',
      'sorcery': 'Hexerei',
      'stealth': 'Heimlichkeit',
      'tasking': 'Tasking',
    };
    return names[key] ?? key;
  }

  /// Maps derived stat keys to human-readable names.
  static String _getDerivedDisplayName(String key) {
    const names = {
      'attack_rating': 'Angriffswert',
      'defense_rating': 'Verteidigungswert',
      'composure': 'Fassung',
      'judge_intentions': 'Menschenkenntnis',
      'memory': 'Erinnerungsvermögen',
      'lift_carry': 'Heben/Tragen',
    };
    return names[key] ?? key;
  }

  /// Maps item type keys to human-readable names.
  static String _getItemTypeDisplayName(String key) {
    const names = {
      'skill': 'Sprachen & Wissen',
      'quality': 'Eigenschaften',
      'gear': 'Ausrüstung',
      'spell': 'Zauber',
      'lifestyle': 'Lebensstil',
      'contact': 'Kontakte',
    };
    return names[key] ?? key;
  }
}