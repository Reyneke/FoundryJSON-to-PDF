import 'dart:convert';
import 'dart:io';
import 'package:foundry_json_to_pdf/models/foundry_character.dart';

/// Service for parsing Foundry VTT JSON files into [FoundryCharacter] models.
class JsonParser {
  /// Parses a Foundry VTT JSON file from the given [file] path.
  ///
  /// Throws an exception if the file cannot be read or parsed.
  static Future<FoundryCharacter> parseFile(File file) async {
    final contents = await file.readAsString();
    return parseString(contents);
  }

  /// Parses a Foundry VTT JSON string into a [FoundryCharacter] model.
  ///
  /// Throws a [FormatException] if the JSON is malformed.
  static FoundryCharacter parseString(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return FoundryCharacter.fromJson(json);
    } on FormatException catch (e) {
      throw FormatException('Ungültiges JSON-Format: ${e.message}');
    } catch (e) {
      throw Exception('Fehler beim Parsen der Charakterdaten: $e');
    }
  }
}