import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';

/// Represents parsed spreadsheet data with headers and rows.
class SpreadsheetData {
  final String fileName;
  final String sheetName;
  final List<String> headers;
  final List<List<dynamic>> rows;
  final String lastUpdated;

  SpreadsheetData({
    required this.fileName,
    required this.sheetName,
    required this.headers,
    required this.rows,
    required this.lastUpdated,
  });

  int get totalTasks => rows.length;

  int get completedTasks => rows.where((r) {
        final status = r.length > 7 ? r[7].toString().toLowerCase() : '';
        final progress = r.length > 6 ? r[6].toString() : '';
        return status.contains('completed') || progress.contains('100');
      }).length;

  int get inProgressTasks => rows.where((r) {
        final status = r.length > 7 ? r[7].toString().toLowerCase() : '';
        return status.contains('in progress') || status.contains('progress');
      }).length;

  int get criticalTasks => rows.where((r) {
        final status = r.length > 7 ? r[7].toString().toLowerCase() : '';
        return status.contains('critical') || status.contains('delayed');
      }).length;

  double get overallProgress {
    if (rows.isEmpty) return 0.0;
    double sum = 0.0;
    int count = 0;
    for (final r in rows) {
      if (r.length > 6) {
        final raw = r[6].toString().replaceAll('%', '').trim();
        final val = double.tryParse(raw);
        if (val != null) {
          sum += val;
          count++;
        }
      }
    }
    if (count == 0) return 0.0;
    return (sum / (count * 100)).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toMap() => {
        'fileName': fileName,
        'sheetName': sheetName,
        'headers': headers,
        'rows': rows,
        'lastUpdated': lastUpdated,
      };

  factory SpreadsheetData.fromMap(Map<String, dynamic> map) {
    return SpreadsheetData(
      fileName: (map['fileName'] as String?) ?? 'Project_Timeline.xlsx',
      sheetName: (map['sheetName'] as String?) ?? 'Master Timeline',
      headers: (map['headers'] as List?)?.map((h) => h.toString()).toList() ??
          <String>[],
      rows: (map['rows'] as List?)
              ?.map((r) => (r as List).toList())
              .toList() ??
          <List<dynamic>>[],
      lastUpdated: (map['lastUpdated'] as String?) ?? 'Just now',
    );
  }

  String toCsvString() {
    final buffer = StringBuffer();
    buffer.writeln(
      headers.map((h) => '"${h.replaceAll('"', '""')}"').join(','),
    );
    for (final row in rows) {
      buffer.writeln(
        row.map((c) => '"${c.toString().replaceAll('"', '""')}"').join(','),
      );
    }
    return buffer.toString();
  }
}

/// Service to parse, generate, and manage project timeline Excel/CSV spreadsheets.
class SpreadsheetService {
  SpreadsheetService._();

  /// Parse XLSX or CSV raw file bytes.
  static SpreadsheetData parseBytes(
    List<int> bytes, {
    String fileName = 'Project_Timeline.xlsx',
  }) {
    if (fileName.toLowerCase().endsWith('.csv') ||
        fileName.toLowerCase().endsWith('.tsv') ||
        fileName.toLowerCase().endsWith('.txt')) {
      return parseCsvString(
        utf8.decode(bytes, allowMalformed: true),
        fileName: fileName,
      );
    }

    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      // Extract shared strings if present
      final sharedStrings = <String>[];
      final sharedStringsFile = archive.findFile('xl/sharedStrings.xml');
      if (sharedStringsFile != null) {
        final xmlDoc = XmlDocument.parse(
          utf8.decode(
            sharedStringsFile.content as List<int>,
            allowMalformed: true,
          ),
        );
        for (final si in xmlDoc.findAllElements('si')) {
          final t = si.findAllElements('t').map((e) => e.innerText).join('');
          sharedStrings.add(t);
        }
      }

      // Extract worksheet (sheet1.xml)
      ArchiveFile? sheetFile = archive.findFile('xl/worksheets/sheet1.xml');
      sheetFile ??= archive.files.firstWhere(
        (f) =>
            f.name.startsWith('xl/worksheets/sheet') && f.name.endsWith('.xml'),
        orElse: () => throw Exception('No worksheet found in XLSX archive'),
      );

      final sheetXml = XmlDocument.parse(
        utf8.decode(sheetFile.content as List<int>, allowMalformed: true),
      );
      final rowsList = <List<String>>[];

      for (final rowElem in sheetXml.findAllElements('row')) {
        final rowData = <String>[];
        for (final c in rowElem.findElements('c')) {
          final cellRef = c.getAttribute('r') ?? '';
          final type = c.getAttribute('t');
          String val = '';

          if (type == 's') {
            final vElem = c.findElements('v').firstOrNull;
            if (vElem != null) {
              final sIdx = int.tryParse(vElem.innerText) ?? -1;
              if (sIdx >= 0 && sIdx < sharedStrings.length) {
                val = sharedStrings[sIdx];
              }
            }
          } else if (type == 'inlineStr') {
            val = c.findAllElements('t').map((e) => e.innerText).join('');
          } else {
            val = c.findElements('v').firstOrNull?.innerText ?? '';
          }

          // Calculate column index from A1 notation
          final colLetters = cellRef.replaceAll(RegExp(r'[0-9]'), '');
          int colIdx = 0;
          for (int i = 0; i < colLetters.length; i++) {
            colIdx = colIdx * 26 + (colLetters.codeUnitAt(i) - 64);
          }
          colIdx = (colIdx > 0 ? colIdx - 1 : rowData.length);

          while (rowData.length < colIdx) {
            rowData.add('');
          }
          rowData.add(val);
        }
        if (rowData.any((cell) => cell.trim().isNotEmpty)) {
          rowsList.add(rowData);
        }
      }

      if (rowsList.isEmpty) {
        throw Exception('Empty spreadsheet');
      }

      final maxCols =
          rowsList.map((r) => r.length).reduce((a, b) => a > b ? a : b);
      for (final r in rowsList) {
        while (r.length < maxCols) {
          r.add('');
        }
      }

      final headers = rowsList.first;
      final dataRows = rowsList.skip(1).toList();

      return SpreadsheetData(
        fileName: fileName,
        sheetName: 'Master Timeline',
        headers: headers,
        rows: dataRows,
        lastUpdated: DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
      );
    } catch (_) {
      // Fallback: try decoding as CSV/text
      return parseCsvString(
        utf8.decode(bytes, allowMalformed: true),
        fileName: fileName,
      );
    }
  }

  /// Parse plain CSV/TSV string.
  static SpreadsheetData parseCsvString(
    String content, {
    String fileName = 'Project_Timeline.csv',
  }) {
    final lines = LineSplitter.split(content)
        .where((l) => l.trim().isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return generateDefaultTimelineForProject('Project Site');
    }

    final rawRows = lines.map((line) {
      final result = <String>[];
      bool inQuote = false;
      final sb = StringBuffer();
      for (int i = 0; i < line.length; i++) {
        final ch = line[i];
        if (ch == '"') {
          inQuote = !inQuote;
        } else if ((ch == ',' || ch == '\t' || ch == ';') && !inQuote) {
          result.add(sb.toString().trim());
          sb.clear();
        } else {
          sb.write(ch);
        }
      }
      result.add(sb.toString().trim());
      return result;
    }).toList();

    final maxCols =
        rawRows.map((r) => r.length).reduce((a, b) => a > b ? a : b);
    for (final r in rawRows) {
      while (r.length < maxCols) {
        r.add('');
      }
    }

    final headers = rawRows.first;
    final dataRows = rawRows.skip(1).toList();

    return SpreadsheetData(
      fileName: fileName,
      sheetName: 'CSV Import',
      headers: headers,
      rows: dataRows,
      lastUpdated: DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
    );
  }

  /// Generates a realistic, turnkey interior execution timeline spreadsheet.
  static SpreadsheetData generateDefaultTimelineForProject(String projectName) {
    final now = DateTime.now();
    final dFormat = DateFormat('dd MMM yyyy');

    final headers = [
      'WBS',
      'Milestone & Site Activity',
      'Trade / Agency',
      'Start Date',
      'Target End',
      'Days',
      'Progress',
      'Status',
      'Site Dependencies & Notes',
    ];

    final rows = [
      [
        '1.1',
        'As-Built 3D Laser Scanning & Structural Grid Recce',
        'Studio Design Team',
        dFormat.format(now.subtract(const Duration(days: 28))),
        dFormat.format(now.subtract(const Duration(days: 21))),
        '7',
        '100%',
        'Completed',
        'Point cloud alignment verified against structural columns',
      ],
      [
        '1.2',
        'Civil Demolition, Core Cutting & Debris Evacuation',
        'Apex Demolition Works',
        dFormat.format(now.subtract(const Duration(days: 20))),
        dFormat.format(now.subtract(const Duration(days: 12))),
        '8',
        '100%',
        'Completed',
        'Load-bearing walls untouched; structural engineer sign-off',
      ],
      [
        '2.1',
        'Electrical Conduiting & Distribution Board Grooving',
        'Sharma MEP Contractors',
        dFormat.format(now.subtract(const Duration(days: 11))),
        dFormat.format(now.subtract(const Duration(days: 3))),
        '8',
        '100%',
        'Completed',
        'Fire-retardant FRLS copper cables pulled; circuit tested',
      ],
      [
        '2.2',
        'Bathroom Multi-layer Waterproofing & Pressure Test',
        'Apex Civil & Wet Works',
        dFormat.format(now.subtract(const Duration(days: 6))),
        dFormat.format(now.add(const Duration(days: 1))),
        '7',
        '90%',
        'In Progress',
        '48-hour standing water test successful; plumbing manifold live',
      ],
      [
        '3.1',
        'Perimeter False Ceiling GI Channels & Laser Framing',
        'Rathore Ceilings & Drywall',
        dFormat.format(now.subtract(const Duration(days: 2))),
        dFormat.format(now.add(const Duration(days: 7))),
        '9',
        '65%',
        'In Progress',
        'Laser-levelled for cove lighting recess and AC duct collars',
      ],
      [
        '3.2',
        'Italian Statuario Marble Dry Lay & Calibrated Epoxy',
        'Royal Marble Artisans',
        dFormat.format(now.add(const Duration(days: 3))),
        dFormat.format(now.add(const Duration(days: 16))),
        '13',
        '30%',
        'Critical Path',
        'Full dry layout approved by client; book-matched veins aligned',
      ],
      [
        '4.1',
        'Moisture-Resistant HDHMR Modular Carcass Installation',
        'Mehta Bespoke Joinery',
        dFormat.format(now.add(const Duration(days: 10))),
        dFormat.format(now.add(const Duration(days: 24))),
        '14',
        '15%',
        'In Progress',
        'German soft-close hardware fitted; carcass level verified',
      ],
      [
        '4.2',
        'Natural Smoked Oak & Fluted Veneer Hot Pressing',
        'Mehta Bespoke Joinery',
        dFormat.format(now.add(const Duration(days: 18))),
        dFormat.format(now.add(const Duration(days: 32))),
        '14',
        '0%',
        'Planned',
        'Veneer lots inspected; zero-bubble hydraulic vacuum pressing',
      ],
      [
        '5.1',
        'Polyurethane (PU) Matte Wall Primer & Leveling Putty',
        'Luxe Finishes & Paints',
        dFormat.format(now.add(const Duration(days: 26))),
        dFormat.format(now.add(const Duration(days: 38))),
        '12',
        '0%',
        'Planned',
        'Requires joinery masking and dust barrier installation',
      ],
      [
        '5.2',
        'Architectural Magnetic Track & DALI Lighting Fitting',
        'Sharma MEP Contractors',
        dFormat.format(now.add(const Duration(days: 34))),
        dFormat.format(now.add(const Duration(days: 44))),
        '10',
        '0%',
        'Planned',
        '3000K warm architectural lighting drivers in ceiling traps',
      ],
      [
        '6.1',
        'Snag Rectification, Glass Glazing & Deep Industrial Clean',
        'Assist Quality Control',
        dFormat.format(now.add(const Duration(days: 42))),
        dFormat.format(now.add(const Duration(days: 50))),
        '8',
        '0%',
        'Planned',
        'Multi-point snag checklist verification with site supervisor',
      ],
      [
        '6.2',
        'Formal Handover, Key Ceremony & Warranty Dossier',
        'Studio Proprietor & PM',
        dFormat.format(now.add(const Duration(days: 50))),
        dFormat.format(now.add(const Duration(days: 52))),
        '2',
        '0%',
        'Planned',
        'Turnkey handover to client with maintenance manuals & warranty',
      ],
    ];

    final sanitizedName =
        projectName.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

    return SpreadsheetData(
      fileName: '${sanitizedName}_Timeline_Schedule.xlsx',
      sheetName: 'Master Timeline',
      headers: headers,
      rows: rows,
      lastUpdated: dFormat.format(now),
    );
  }
}
