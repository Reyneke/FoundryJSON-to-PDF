/// Represents an attribute with a base value, modifier, and pool.
class CharacterAttribute {
  final int base;
  final int mod;
  final int pool;
  final int value;
  final int max;
  final String modString;

  const CharacterAttribute({
    required this.base,
    this.mod = 0,
    this.pool = 0,
    this.value = 0,
    this.max = 0,
    this.modString = '',
  });

  int get total => base + mod;

  factory CharacterAttribute.fromJson(Map<String, dynamic> json) {
    return CharacterAttribute(
      base: json['base'] as int? ?? 0,
      mod: json['mod'] as int? ?? 0,
      pool: json['pool'] as int? ?? 0,
      value: json['value'] as int? ?? 0,
      max: json['max'] as int? ?? 0,
      modString: json['modString'] as String? ?? '',
    );
  }
}

/// Represents a skill with points, modifier, and description.
class CharacterSkill {
  final int points;
  final int modifier;
  final String modString;
  final int augment;

  const CharacterSkill({
    required this.points,
    this.modifier = 0,
    this.modString = '',
    this.augment = 0,
  });

  int get total => points + modifier + augment;

  factory CharacterSkill.fromJson(Map<String, dynamic> json) {
    return CharacterSkill(
      points: json['points'] as int? ?? 0,
      modifier: json['modifier'] as int? ?? 0,
      modString: json['modString'] as String? ?? '',
      augment: json['augment'] as int? ?? 0,
    );
  }
}

/// Represents a derived stat (composure, defense, etc.).
class DerivedStat {
  final int base;
  final int mod;
  final int pool;

  const DerivedStat({
    required this.base,
    this.mod = 0,
    this.pool = 0,
  });

  int get total => base + mod;

  factory DerivedStat.fromJson(Map<String, dynamic> json) {
    return DerivedStat(
      base: json['base'] as int? ?? 0,
      mod: json['mod'] as int? ?? 0,
      pool: json['pool'] as int? ?? 0,
    );
  }
}

/// Represents an item in the character's inventory (gear, weapon, spell, etc.).
class CharacterItem {
  final String type;
  final String name;
  final String? category;
  final String? subtype;
  final int? rating;
  final int? price;
  final Map<String, dynamic> data;

  const CharacterItem({
    required this.type,
    required this.name,
    this.category,
    this.subtype,
    this.rating,
    this.price,
    required this.data,
  });

  factory CharacterItem.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return CharacterItem(
      type: json['type'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: data['category'] as String?,
      subtype: data['subtype'] as String?,
      rating: data['rating'] as int?,
      price: data['price'] as int?,
      data: data,
    );
  }
}

/// Represents the initiative dice configuration.
class InitiativeData {
  final int mod;
  final int dice;

  const InitiativeData({
    this.mod = 0,
    this.dice = 1,
  });

  factory InitiativeData.fromJson(Map<String, dynamic> json) {
    return InitiativeData(
      mod: json['mod'] as int? ?? 0,
      dice: json['dice'] as int? ?? 1,
    );
  }
}

/// Represents a fully parsed Foundry VTT character from a JSON file.
///
/// This model is designed to be flexible enough to handle multiple RPG systems
/// (Shadowrun 6, D&D 2014/2024, DSA) by storing parsed data in a structured format.
class FoundryCharacter {
  final String name;
  final String type;
  final String generatorName;
  final String generatorVersion;
  final String? systemType;

  // Shadowrun 6 specific fields
  final int nuyen;
  final String metatype;
  final String gender;
  final String mortype;
  final Map<String, CharacterAttribute> attributes;
  final Map<String, CharacterSkill> skills;
  final Map<String, DerivedStat> derived;
  final Map<String, CharacterAttribute> resist;
  final Map<String, InitiativeData> initiative;
  final CharacterAttribute overflow;
  final CharacterAttribute physical;
  final CharacterAttribute stun;
  final Map<String, int> edge;
  final Map<String, int> movement;

  // Items (gear, spells, qualities, contacts, etc.)
  final List<CharacterItem> items;

  /// Raw JSON data preserved for system-specific parsing.
  final Map<String, dynamic> rawData;

  const FoundryCharacter({
    required this.name,
    required this.type,
    this.generatorName = '',
    this.generatorVersion = '',
    this.systemType,
    this.nuyen = 0,
    this.metatype = '',
    this.gender = '',
    this.mortype = '',
    this.attributes = const {},
    this.skills = const {},
    this.derived = const {},
    this.resist = const {},
    this.initiative = const {},
    this.overflow = const CharacterAttribute(base: 0),
    this.physical = const CharacterAttribute(base: 0),
    this.stun = const CharacterAttribute(base: 0),
    this.edge = const {},
    this.movement = const {},
    this.items = const [],
    this.rawData = const {},
  });

  /// Attempts to detect which RPG system this character belongs to.
  String detectSystem() {
    if (attributes.containsKey('bod') &&
        attributes.containsKey('agi') &&
        skills.containsKey('sorcery')) {
      return 'shadowrun6';
    }
    if (rawData['system'] is Map) {
      final system = rawData['system'] as Map<String, dynamic>;
      if (system.containsKey('abilities') || system.containsKey('spells')) {
        return 'dnd';
      }
    }
    return 'unknown';
  }

  factory FoundryCharacter.fromJson(Map<String, dynamic> json) {
    final system = json['system'] as Map<String, dynamic>? ?? {};
    final itemsRaw = json['items'] as List<dynamic>? ?? [];

    // Parse attributes (Shadowrun 6 style)
    final attrsRaw = system['attributes'] as Map<String, dynamic>? ?? {};
    final attributes = <String, CharacterAttribute>{};
    for (final key in attrsRaw.keys) {
      if (attrsRaw[key] is Map<String, dynamic>) {
        attributes[key] = CharacterAttribute.fromJson(
          attrsRaw[key] as Map<String, dynamic>,
        );
      }
    }

    // Parse skills (Shadowrun 6 style)
    final skillsRaw = system['skills'] as Map<String, dynamic>? ?? {};
    final skills = <String, CharacterSkill>{};
    for (final key in skillsRaw.keys) {
      if (skillsRaw[key] is Map<String, dynamic>) {
        skills[key] = CharacterSkill.fromJson(
          skillsRaw[key] as Map<String, dynamic>,
        );
      }
    }

    // Parse derived stats
    final derivedRaw = system['derived'] as Map<String, dynamic>? ?? {};
    final derived = <String, DerivedStat>{};
    for (final key in derivedRaw.keys) {
      if (derivedRaw[key] is Map<String, dynamic>) {
        derived[key] = DerivedStat.fromJson(
          derivedRaw[key] as Map<String, dynamic>,
        );
      }
    }

    // Parse resist stats
    final resistRaw = system['resist'] as Map<String, dynamic>? ?? {};
    final resist = <String, CharacterAttribute>{};
    for (final key in resistRaw.keys) {
      if (resistRaw[key] is Map<String, dynamic>) {
        resist[key] = CharacterAttribute.fromJson(
          resistRaw[key] as Map<String, dynamic>,
        );
      }
    }

    // Parse initiative
    final initRaw = system['initiative'] as Map<String, dynamic>? ?? {};
    final initiative = <String, InitiativeData>{};
    for (final key in initRaw.keys) {
      if (initRaw[key] is Map<String, dynamic>) {
        initiative[key] = InitiativeData.fromJson(
          initRaw[key] as Map<String, dynamic>,
        );
      }
    }

    // Parse items
    final items = itemsRaw
        .map((e) => CharacterItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return FoundryCharacter(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      generatorName: json['generatorName'] as String? ?? '',
      generatorVersion: json['generatorVersion'] as String? ?? '',
      systemType: system['type'] as String?,
      nuyen: system['nuyen'] as int? ?? 0,
      metatype: system['metatype'] as String? ?? '',
      gender: system['gender'] as String? ?? '',
      mortype: system['mortype'] as String? ?? '',
      attributes: attributes,
      skills: skills,
      derived: derived,
      resist: resist,
      initiative: initiative,
      overflow: system['overflow'] is Map<String, dynamic>
          ? CharacterAttribute.fromJson(
              system['overflow'] as Map<String, dynamic>,
            )
          : const CharacterAttribute(base: 0),
      physical: system['physical'] is Map<String, dynamic>
          ? CharacterAttribute.fromJson(
              system['physical'] as Map<String, dynamic>,
            )
          : const CharacterAttribute(base: 0),
      stun: system['stun'] is Map<String, dynamic>
          ? CharacterAttribute.fromJson(
              system['stun'] as Map<String, dynamic>,
            )
          : const CharacterAttribute(base: 0),
      edge: _parseEdge(system['edge']),
      movement: _parseMovement(system['movement']),
      items: items,
      rawData: json,
    );
  }

  static Map<String, int> _parseEdge(dynamic edgeData) {
    if (edgeData is Map) {
      return {
        'value': (edgeData['value'] as int?) ?? 0,
        'max': (edgeData['max'] as int?) ?? 0,
      };
    }
    return {};
  }

  static Map<String, int> _parseMovement(dynamic movementData) {
    if (movementData is Map) {
      return {
        'walk': (movementData['walk'] as int?) ?? 0,
        'sprint': (movementData['sprint'] as int?) ?? 0,
        'perHit': (movementData['perHit'] as int?) ?? 0,
      };
    }
    return {};
  }
}