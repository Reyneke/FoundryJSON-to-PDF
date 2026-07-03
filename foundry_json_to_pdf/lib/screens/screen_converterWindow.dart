import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:foundry_json_to_pdf/widgets/theme_selector.dart';
import 'package:foundry_json_to_pdf/services/json_parser.dart';
import 'package:foundry_json_to_pdf/services/pdf_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

/// Enumeration of supported RPG systems for JSON-to-PDF conversion.
enum SupportedSystem { shadowrun6, dud2014, dud2024, dsa }

/// Screen that allows users to convert Foundry VTT JSON character data into PDF character sheets.
///
/// The screen provides four core elements:
/// 1. A drag-and-drop / file picker container for selecting a Foundry JSON file
/// 2. A dropdown menu to select the target RPG system
/// 3. A button to start the conversion process
/// 4. An output area showing the converted PDF with a download/share button
class ScreenConverterwindow extends StatefulWidget {
  const ScreenConverterwindow({super.key});

  @override
  State<ScreenConverterwindow> createState() => _ScreenConverterwindowState();
}

class _ScreenConverterwindowState extends State<ScreenConverterwindow> {
  /// Path to the selected JSON file, or null if none selected.
  String? _jsonFilePath;

  /// Name of the selected JSON file for display.
  String? _jsonFileName;

  /// Currently selected target system.
  SupportedSystem _selectedSystem = SupportedSystem.shadowrun6;

  /// Whether a conversion is currently in progress.
  bool _isConverting = false;

  /// Path to the generated PDF file, or null if not yet generated.
  String? _pdfFilePath;

  /// Cached PDF bytes to avoid file-reading race conditions in PdfPreview.
  Uint8List? _pdfBytes;

  /// Whether the selected file is being dragged over the input container.
  bool _isDragging = false;

  /// Opens a file picker dialog to select a Foundry JSON file.
  Future<void> _pickJsonFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _jsonFilePath = result.files.single.path;
        _jsonFileName = result.files.single.name;
        _pdfFilePath = null; // Reset any previous PDF output
      });
    }
  }

  /// Converts the loaded JSON file to a PDF using the selected system.
  Future<void> _convertToPdf() async {
    if (_jsonFilePath == null) {
      _showSnackBar('Bitte wählen Sie zuerst eine JSON-Datei aus.');
      return;
    }

    setState(() => _isConverting = true);

    try {
      // Parse the JSON file
      final file = File(_jsonFilePath!);
      final character = await JsonParser.parseFile(file);

      // Generate the PDF
      final pdfBytes = await PdfGenerator.generate(
        character: character,
        system: _selectedSystem,
      );

      // Cache PDF bytes in memory for immediate display
      _pdfBytes = pdfBytes;

      // Save the PDF to the app's temporary directory
      final directory = await getTemporaryDirectory();
      final pdfFileName = _jsonFileName?.replaceAll('.json', '.pdf') ?? 'character.pdf';
      final pdfPath = '${directory.path}/$pdfFileName';
      final pdfFile = File(pdfPath);
      await pdfFile.writeAsBytes(pdfBytes);

      setState(() {
        _pdfFilePath = pdfPath;
        _isConverting = false;
      });

      _showSnackBar('PDF erfolgreich erstellt!');
    } catch (e) {
      setState(() => _isConverting = false);
      _showSnackBar('Fehler bei der Konvertierung: $e');
    }
  }

  /// Shares the generated PDF file.
  Future<void> _sharePdf() async {
    if (_pdfFilePath == null) return;

    final file = XFile(_pdfFilePath!);
    await Share.shareXFiles([file], text: 'Foundry Character Sheet');
  }

  /// Saves the generated PDF file to a user-chosen location using save-file dialog.
  Future<void> _downloadPdf() async {
    if (_pdfFilePath == null) return;

    final pdfFile = File(_pdfFilePath!);
    final pdfBytes = await pdfFile.readAsBytes();

    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'PDF speichern unter',
      fileName: _jsonFileName?.replaceAll('.json', '.pdf') ?? 'character.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (outputPath != null) {
      await File(outputPath).writeAsBytes(pdfBytes);
      _showSnackBar('PDF gespeichert unter: $outputPath');
    }
  }

  /// Shows a brief snackbar message to the user.
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FoundryJSON to PDF'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: ThemeSelector(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. JSON Input Container (Drag & Drop / File Picker)
            _buildJsonInputContainer(theme),

            const SizedBox(height: 16),

            // 2. System Dropdown
            _buildSystemDropdown(theme),

            const SizedBox(height: 16),

            // 3. Convert Button
            _buildConvertButton(theme),

            const SizedBox(height: 16),

            // 4. PDF Output Container
            _buildPdfOutputContainer(theme),
          ],
        ),
      ),
    );
  }

  /// Builds the drag-and-drop / file picker container for JSON input.
  Widget _buildJsonInputContainer(ThemeData theme) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) {
        setState(() => _isDragging = false);
        // Accept only the first dropped file if it's a JSON
        final file = details.files.firstOrNull;
        if (file != null && file.name.endsWith('.json')) {
          setState(() {
            _jsonFilePath = file.path;
            _jsonFileName = file.name;
            _pdfFilePath = null;
          });
        } else {
          _showSnackBar('Bitte nur JSON-Dateien ablegen.');
        }
      },
      child: GestureDetector(
        onTap: _pickJsonFile,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 200,
          decoration: BoxDecoration(
            color: _isDragging
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isDragging
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.5),
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _jsonFilePath != null
                      ? Icons.check_circle
                      : Icons.upload_file,
                  size: 48,
                  color: _jsonFilePath != null
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 12),
                Text(
                  _jsonFileName ?? 'JSON-Datei hier ablegen oder klicken',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: _jsonFileName != null
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the dropdown menu for selecting the target RPG system.
  Widget _buildSystemDropdown(ThemeData theme) {
    return DropdownButtonFormField<SupportedSystem>(
      initialValue: _selectedSystem,
      decoration: InputDecoration(
        labelText: 'Zielsystem',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: const Icon(Icons.settings),
      ),
      items: const [
        DropdownMenuItem(
          value: SupportedSystem.shadowrun6,
          child: Text('Shadowrun 6'),
        ),
        DropdownMenuItem(
          value: SupportedSystem.dud2014,
          child: Text('D&D 2014'),
        ),
        DropdownMenuItem(
          value: SupportedSystem.dud2024,
          child: Text('D&D 2024'),
        ),
        DropdownMenuItem(
          value: SupportedSystem.dsa,
          child: Text('Das Schwarze Auge'),
        ),
      ],
      onChanged: (value) {
        if (value != null) setState(() => _selectedSystem = value);
      },
    );
  }

  /// Builds the button that triggers the JSON-to-PDF conversion.
  Widget _buildConvertButton(ThemeData theme) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isConverting ? null : _convertToPdf,
        icon: _isConverting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.transform),
        label: Text(_isConverting ? 'Konvertiere...' : 'Konvertieren'),
      ),
    );
  }

  /// Builds the output container that displays the converted PDF with share/download buttons.
  Widget _buildPdfOutputContainer(ThemeData theme) {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        color: _pdfFilePath != null
            ? theme.colorScheme.surfaceContainerHighest
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: _pdfFilePath != null
          ? Column(
              children: [
                // PDF preview area
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: PdfPreview(
                      build: _buildPdf,
                      allowPrinting: true,
                      allowSharing: false,
                      maxPageWidth: 700,
                      canChangePageFormat: false,
                      canChangeOrientation: false,
                      canDebug: false,
                      onError: (context, error) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Unable to display the document',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Action buttons
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _sharePdf,
                        icon: const Icon(Icons.share),
                        label: const Text('Teilen'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _downloadPdf,
                        icon: const Icon(Icons.download),
                        label: const Text('Herunterladen'),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    size: 48,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Konvertiertes PDF erscheint hier',
                  ),
                ],
              ),
            ),
    );
  }

  /// Provides PDF bytes for the PdfPreview widget.
  Future<Uint8List> _buildPdf(PdfPageFormat format) async {
    if (_pdfBytes != null) return _pdfBytes!;
    if (_pdfFilePath != null) return await File(_pdfFilePath!).readAsBytes();
    return Uint8List(0);
  }
}
