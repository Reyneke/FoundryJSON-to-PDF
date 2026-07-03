import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:foundry_json_to_pdf/models/foundry_character.dart';
import 'package:foundry_json_to_pdf/screens/screen_converterWindow.dart';

/// Defines the visual theme for a specific RPG system's character sheet.
class _SystemTheme {
  final String name;
  final PdfColor primaryColor;
  final PdfColor secondaryColor;
  final PdfColor accentColor;
  final PdfColor backgroundColor;
  final PdfColor textColor;
  final PdfColor headerTextColor;
  final PdfColor tableHeaderColor;
  final PdfColor tableBorderColor;
  final PdfColor sectionUnderlineColor;

  const _SystemTheme({
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.textColor,
    required this.headerTextColor,
    required this.tableHeaderColor,
    required this.tableBorderColor,
    required this.sectionUnderlineColor,
  });

  static const _SystemTheme shadowrun6 = _SystemTheme(
    name: 'Shadowrun 6',
    primaryColor: PdfColor.fromInt(0xFF1B2A4A),
    secondaryColor: PdfColor.fromInt(0xFF2C3E6B),
    accentColor: PdfColor.fromInt(0xFFC0392B),
    backgroundColor: PdfColor.fromInt(0xFFF5F5F0),
    textColor: PdfColor.fromInt(0xFF1A1A2E),
    headerTextColor: PdfColor.fromInt(0xFFFFFFFF),
    tableHeaderColor: PdfColor.fromInt(0xFF1B2A4A),
    tableBorderColor: PdfColor.fromInt(0xFF34495E),
    sectionUnderlineColor: PdfColor.fromInt(0xFFC0392B),
  );

  static const _SystemTheme dud2014 = _SystemTheme(
    name: 'Dungeons & Dragons 2014',
    primaryColor: PdfColor.fromInt(0xFF5D4037),
    secondaryColor: PdfColor.fromInt(0xFF795548),
    accentColor: PdfColor.fromInt(0xFFD4A574),
    backgroundColor: PdfColor.fromInt(0xFFFEF9EF),
    textColor: PdfColor.fromInt(0xFF3E2723),
    headerTextColor: PdfColor.fromInt(0xFFFFFFFF),
    tableHeaderColor: PdfColor.fromInt(0xFF5D4037),
    tableBorderColor: PdfColor.fromInt(0xFF8D6E63),
    sectionUnderlineColor: PdfColor.fromInt(0xFFD4A574),
  );

  static const _SystemTheme dud2024 = _SystemTheme(
    name: 'Dungeons & Dragons 2024',
    primaryColor: PdfColor.fromInt(0xFF1A237E),
    secondaryColor: PdfColor.fromInt(0xFF283593),
    accentColor: PdfColor.fromInt(0xFF7C4DFF),
    backgroundColor: PdfColor.fromInt(0xFFF5F5FF),
    textColor: PdfColor.fromInt(0xFF1A1A2E),
    headerTextColor: PdfColor.fromInt(0xFFFFFFFF),
    tableHeaderColor: PdfColor.fromInt(0xFF1A237E),
    tableBorderColor: PdfColor.fromInt(0xFF7986CB),
    sectionUnderlineColor: PdfColor.fromInt(0xFF7C4DFF),
  );

  static const _SystemTheme dsa = _SystemTheme(
    name: 'Das Schwarze Auge',
    primaryColor: PdfColor.fromInt(0xFF1B5E20),
    secondaryColor: PdfColor.fromInt(0xFF2E7D32),
    accentColor: PdfColor.fromInt(0xFFD4A017),
    backgroundColor: PdfColor.fromInt(0xFFF9FBE7),
    textColor: PdfColor.fromInt(0xFF1B2E1B),
    headerTextColor: PdfColor.fromInt(0xFFFFFFFF),
    tableHeaderColor: PdfColor.fromInt(0xFF1B5E20),
    tableBorderColor: PdfColor.fromInt(0xFF66BB6A),
    sectionUnderlineColor: PdfColor.fromInt(0xFFD4A017),
  );

  /// Returns the theme for the given system.
  static _SystemTheme forSystem(SupportedSystem system) {
    switch (system) {
      case SupportedSystem.shadowrun6:
        return _SystemTheme.shadowrun6;
      case SupportedSystem.dud2014:
        return _SystemTheme.dud2014;
      case SupportedSystem.dud2024:
        return _SystemTheme.dud2024;
      case SupportedSystem.dsa:
        return _SystemTheme.dsa;
    }
  }
}

/// Service for generating PDF character sheets from [FoundryCharacter] data.
class PdfGenerator {
  /// Generates a PDF byte array from the given [character] data for the specified [system].
  ///
  /// The generated PDF uses system-specific theming to create character sheets
  /// that visually match the official templates for each RPG system.
  static Future<Uint8List> generate({
    required FoundryCharacter character,
    required SupportedSystem system,
  }) async {
    final theme = _SystemTheme.forSystem(system);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(character, system, theme),
          pw.SizedBox(height: 16),
          _buildSystemLabel(system, theme),
          pw.SizedBox(height: 16),
          if (character.attributes.isNotEmpty)
            _buildAttributesSection(character, system, theme),
          if (character.attributes.isNotEmpty &&
              character.skills.isNotEmpty)
            pw.SizedBox(height: 16),
          if (character.skills.isNotEmpty)
            _buildSkillsSection(character, system, theme),
          if (character.skills.isNotEmpty &&
              _hasDerivedStats(character))
            pw.SizedBox(height: 16),
          if (_hasDerivedStats(character))
            _buildDerivedStatsSection(character, system, theme),
          if (_hasDerivedStats(character) &&
              character.items.isNotEmpty)
            pw.SizedBox(height: 16),
          if (character.items.isNotEmpty)
            _buildItemsSection(character, system, theme),
        ],
      ),
    );

    return pdf.save();
  }

  /// Checks if the character has any derived stats worth displaying.
  static bool _hasDerivedStats(FoundryCharacter character) {
    return character.derived.isNotEmpty ||
        character.resist.isNotEmpty ||
        character.physical.base > 0 ||
        character.stun.base > 0;
  }

  /// Builds the header section with character name and basic info.
  static pw.Widget _buildHeader(
    FoundryCharacter character,
    SupportedSystem system,
    _SystemTheme theme,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: pw.BoxDecoration(
        color: theme.primaryColor,
        borderRadius: const pw.BorderRadius.only(
          topLeft: pw.Radius.circular(8),
          topRight: pw.Radius.circular(8),
          bottomLeft: pw.Radius.circular(4),
          bottomRight: pw.Radius.circular(4),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            character.name,
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: theme.headerTextColor,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            height: 2,
            color: theme.accentColor,
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              if (character.metatype.isNotEmpty)
                _buildInfoChip(
                    'Metatyp', character.metatype, theme),
              if (character.mortype.isNotEmpty)
                _buildInfoChip('Typ', character.mortype, theme),
              if (character.gender.isNotEmpty)
                _buildInfoChip(
                    'Geschlecht', character.gender, theme),
            ],
          ),
          if (character.generatorName.isNotEmpty ||
              character.generatorVersion.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                'Erstellt mit ${character.generatorName} v${character.generatorVersion}',
              style: pw.TextStyle(
                  fontSize: 10,
                  color: theme.accentColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds a small info chip for displaying key-value metadata.
  static pw.Widget _buildInfoChip(
    String label,
    String value,
    _SystemTheme theme,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      margin: const pw.EdgeInsets.only(right: 8),
      decoration: pw.BoxDecoration(
        color: theme.primaryColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        '$label: $value',
        style: pw.TextStyle(
          fontSize: 11,
          color: theme.headerTextColor,
        ),
      ),
    );
  }

  /// Builds the system label indicating which RPG system was used.
  static pw.Widget _buildSystemLabel(
    SupportedSystem system,
    _SystemTheme theme,
  ) {
    final systemNames = {
      SupportedSystem.shadowrun6: 'Shadowrun 6',
      SupportedSystem.dud2014: 'Dungeons & Dragons 2014',
      SupportedSystem.dud2024: 'Dungeons & Dragons 2024',
      SupportedSystem.dsa: 'Das Schwarze Auge',
    };

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: pw.BoxDecoration(
        color: theme.secondaryColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(
            width: 14,
            height: 14,
            decoration: pw.BoxDecoration(
              color: theme.accentColor,
              shape: pw.BoxShape.circle,
            ),
            alignment: pw.Alignment.center,
            child: pw.Text(
              system == SupportedSystem.shadowrun6
                  ? 'S'
                  : (system == SupportedSystem.dsa
                      ? 'A'
                      : 'D'),
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: theme.headerTextColor,
              ),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Text(
            systemNames[system] ?? 'Unbekannt',
            style: pw.TextStyle(
              fontSize: 11,
              color: theme.headerTextColor,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the attributes section of the character sheet.
  static pw.Widget _buildAttributesSection(
    FoundryCharacter character,
    SupportedSystem system,
    _SystemTheme theme,
  ) {
    if (character.attributes.isEmpty) return pw.SizedBox.shrink();

    // D&D systems use a different attribute display style (six core stats)
    if (system == SupportedSystem.dud2014 ||
        system == SupportedSystem.dud2024) {
      return _buildDndAttributesSection(character, theme);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Attribute', theme),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: theme.tableBorderColor),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(3),
          },
          children: [
            _buildTableHeader(['Attribut', 'Basis', 'Mod', 'Beschreibung'], theme),
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

  /// Builds a D&D-style attribute block with the six core stats highlighted.
  static pw.Widget _buildDndAttributesSection(
    FoundryCharacter character,
    _SystemTheme theme,
  ) {
    // Map the generic attribute keys to D&D-like names
    final dndAttrMap = <String, String>{
      'bod': 'ST (Stärke)',
      'agi': 'GE (Geschick)',
      'rea': 'KO (Konstitution)',
      'int': 'IN (Intelligenz)',
      'wil': 'WE (Weisheit)',
      'cha': 'CH (Charisma)',
    };

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Attribute', theme),
        pw.SizedBox(height: 8),
        // Display D&D attributes in a compact grid-like layout
        pw.Table(
          border: pw.TableBorder.all(color: theme.tableBorderColor),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(2),
          },
          children: [
            _buildTableHeader(
                ['Attribut', 'Wert', 'Mod', 'Temp'], theme),
            ...dndAttrMap.entries.map((entry) {
              final value =
                  character.attributes[entry.key]?.total ?? 0;
              final mod = ((value / 2) - 5).floor();
              final modStr = mod >= 0 ? '+$mod' : '$mod';
              return _buildTableRow([
                entry.value,
                value.toString(),
                modStr,
                '-',
              ]);
            }),
          ],
        ),
      ],
    );
  }

  /// Builds the skills section of the character sheet.
  static pw.Widget _buildSkillsSection(
    FoundryCharacter character,
    SupportedSystem system,
    _SystemTheme theme,
  ) {
    if (character.skills.isEmpty) return pw.SizedBox.shrink();

    // D&D uses saving throws and skills differently
    if (system == SupportedSystem.dud2014 ||
        system == SupportedSystem.dud2024) {
      return _buildDndSkillsSection(character, theme);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Fertigkeiten', theme),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: theme.tableBorderColor),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(3),
          },
          children: [
            _buildTableHeader(['Fertigkeit', 'Punkte', 'Mod', 'Beschreibung'], theme),
            ...character.skills.entries
                .where((e) =>
                    e.value.points > 0 || e.value.modString.isNotEmpty)
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

  /// Builds a D&D-style skills section with proficiency bonus.
  static pw.Widget _buildDndSkillsSection(
    FoundryCharacter character,
    _SystemTheme theme,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Fertigkeiten & Rettungswürfe', theme),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: theme.tableBorderColor),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(3),
          },
          children: [
            _buildTableHeader(['Fertigkeit', 'Punkte', 'Bonus', 'Merkmal'], theme),
            ...character.skills.entries
                .where((e) =>
                    e.value.points > 0 || e.value.modString.isNotEmpty)
                .map((entry) {
              final skill = entry.value;
              final modifier = skill.modifier != 0
                  ? skill.modifier
                  : skill.points;
              final modStr =
                  modifier > 0 ? '+$modifier' : modifier.toString();
              return _buildTableRow([
                _getSkillDisplayName(entry.key),
                skill.points.toString(),
                modStr,
                skill.modString,
              ]);
            }),
          ],
        ),
      ],
    );
  }

  /// Builds the derived stats section (composure, defense, etc.).
  static pw.Widget _buildDerivedStatsSection(
    FoundryCharacter character,
    SupportedSystem system,
    _SystemTheme theme,
  ) {
    if (!_hasDerivedStats(character)) return pw.SizedBox.shrink();

    // D&D shows hit points, armor class, etc.
    if (system == SupportedSystem.dud2014 ||
        system == SupportedSystem.dud2024) {
      return _buildDndCombatStats(character, theme);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Abgeleitete Werte', theme),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: theme.tableBorderColor),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(3),
          },
          children: [
            _buildTableHeader(['Wert', 'Basis', 'Mod', 'Pool'], theme),
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

  /// Builds D&D-style combat stats (HP, AC, etc.).
  static pw.Widget _buildDndCombatStats(
    FoundryCharacter character,
    _SystemTheme theme,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Kampfwerte', theme),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: theme.tableBorderColor),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(3),
          },
          children: [
            _buildTableHeader(['Wert', 'Basis', 'Mod', 'Pool'], theme),
            // Initiative
            if (character.initiative.isNotEmpty)
              ...character.initiative.entries.map((entry) {
                final init = entry.value;
                return _buildTableRow([
                  'Initiative',
                  init.dice.toString(),
                  init.mod.toString(),
                  '',
                ]);
              }),
            // Physical as HP
            if (character.physical.base > 0)
              _buildTableRow([
                'Trefferpunkte (max)',
                character.physical.base.toString(),
                character.physical.mod != 0
                    ? character.physical.mod.toString()
                    : '-',
                character.physical.value.toString(),
              ]),
            // Armor class from derived stats
            if (character.derived.containsKey('defense_rating'))
              _buildTableRow([
                'Rüstungsklasse',
                character
                    .derived['defense_rating']!.base
                    .toString(),
                character.derived['defense_rating']!.mod != 0
                    ? character
                        .derived['defense_rating']!.mod
                        .toString()
                    : '-',
                character
                    .derived['defense_rating']!.pool
                    .toString(),
              ]),
          ],
        ),
      ],
    );
  }

  /// Builds the items section (gear, spells, qualities, contacts).
  static pw.Widget _buildItemsSection(
    FoundryCharacter character,
    SupportedSystem system,
    _SystemTheme theme,
  ) {
    if (character.items.isEmpty) return pw.SizedBox.shrink();

    // Group items by type
    final grouped = <String, List<CharacterItem>>{};
    for (final item in character.items) {
      grouped.putIfAbsent(item.type, () => []).add(item);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Ausrüstung & Gegenstände', theme),
        pw.SizedBox(height: 8),
        ...grouped.entries.map((entry) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: theme.secondaryColor,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(3)),
                  ),
                  child: pw.Text(
                    _getItemTypeDisplayName(entry.key),
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: theme.headerTextColor,
                    ),
                  ),
                ),
              ),
              pw.Table(
                border: pw.TableBorder.all(color: theme.tableBorderColor),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1),
                },
                children: [
                  _buildTableHeader(
                      ['Name', 'Kategorie', 'Preis'], theme),
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

  /// Builds a section title with a styled underline matching the system theme.
  static pw.Widget _buildSectionTitle(String title, _SystemTheme theme) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
              color: theme.sectionUnderlineColor, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(
            width: 4,
            height: 16,
            color: theme.accentColor,
          ),
          pw.SizedBox(width: 6),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a table header row.
  static pw.TableRow _buildTableHeader(
    List<String> headers,
    _SystemTheme theme,
  ) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: theme.tableHeaderColor),
      children: headers
          .map((h) => pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  h,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: theme.headerTextColor,
                  ),
                ),
              ))
          .toList(),
    );
  }

  /// Builds a table data row with alternating background color.
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