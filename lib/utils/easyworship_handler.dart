// lib/handlers/easyworship_handler.dart
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;
import 'dart:developer' as developer;

class EasyWorshipHandler {
  Future<void> extractAndSaveDb(String eswxPath, String outputPath) async {
    try {
      final bytes = await File(eswxPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      for (final file in archive) {
        if (file.isFile && file.name.endsWith('.db')) {
          final data = file.content as List<int>;
          await File(outputPath).writeAsBytes(data);
          developer.log('Database extracted to: $outputPath');
          break;
        }
      }
    } catch (e, stack) {
      developer.log('Error extracting database', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getEasyWorshipContent(String filePath) async {
    final content = <String, dynamic>{};
    
    try {
      // Initialize SQLite
      sqfliteFfiInit();
      final databaseFactory = databaseFactoryFfi;
      
      final db = await databaseFactory.openDatabase(filePath);
      
      // First, get all tables
      final tables = await db.query('sqlite_master',
          where: 'type = ?',
          whereArgs: ['table']);
      
      developer.log('Available tables: ${tables.map((t) => t['name']).join(', ')}');

      // For each table, get its structure
      for (final table in tables) {
        final tableName = table['name'] as String;
        if (!tableName.startsWith('sqlite_')) {
          try {
            // Get table info
            final tableInfo = await db.query('pragma_table_info(?)', 
                whereArgs: [tableName]);
            developer.log('Table $tableName columns: ${tableInfo.map((c) => c['name']).join(', ')}');

            // Get the data
            final rows = await db.query(tableName);
            content[tableName] = rows;
            developer.log('Found ${rows.length} rows in $tableName');
          } catch (e) {
            developer.log('Error reading table $tableName: $e');
          }
        }
      }

      await db.close();
      
    } catch (e, stack) {
      developer.log('Error reading EasyWorship content', error: e, stackTrace: stack);
      rethrow;
    }
    
    return content;
  }

  Future<List<String>> getDatabaseTables(String filePath) async {
    try {
      sqfliteFfiInit();
      final databaseFactory = databaseFactoryFfi;
      final db = await databaseFactory.openDatabase(filePath);

      final tables = await db.query('sqlite_master',
          where: 'type = ?',
          whereArgs: ['table']);

      await db.close();

      return tables
          .where((t) => !t['name'].toString().startsWith('sqlite_'))
          .map((t) => t['name'].toString())
          .toList();
    } catch (e, stack) {
      developer.log('Error getting database tables', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<List<Map<String, String>>> getTableStructure(String filePath, String tableName) async {
    try {
      sqfliteFfiInit();
      final databaseFactory = databaseFactoryFfi;
      final db = await databaseFactory.openDatabase(filePath);

      final columns = await db.query('pragma_table_info(?)', 
          whereArgs: [tableName]);

      await db.close();

      return columns.map((c) => {
        'name': c['name'].toString(),
        'type': c['type'].toString(),
      }).toList();
    } catch (e, stack) {
      developer.log('Error getting table structure', error: e, stackTrace: stack);
      rethrow;
    }
  }

   Future<Map<String, dynamic>> getScriptureContent(String filePath) async {
    final content = await getEasyWorshipContent(filePath);
    final data = EasyWorshipData.fromContent(content);
    
    // Extract scripture-specific information
    final scriptureContent = <String, dynamic>{
      'verses': <Map<String, dynamic>>[],
    };

    for (final slide in data.slides) {
      final slideId = slide['rowid'];
      final properties = data.properties.where((prop) {
        final group = data.propertyGroups.firstWhere(
          (g) => g['rowid'] == prop['group_id'],
          orElse: () => {'link_id': null},
        );
        return group['link_id'] == slideId;
      }).toList();

      final verse = {
        'title': slide['title'],
        'content': _getVerseContent(properties),
        'order': slide['order_index'],
      };

      scriptureContent['verses'].add(verse);
    }

    return scriptureContent;
  }

  Map<String, String> _getVerseContent(List<Map<String, dynamic>> properties) {
    final content = <String, String>{};
    
    for (final prop in properties) {
      final key = prop['key']?.toString() ?? '';
      final value = prop['value']?.toString() ?? '';
      
      if (key.isNotEmpty) {
        content[key] = value;
      }
    }

    return content;
  }
}


class EasyWorshipData {
  final List<Map<String, dynamic>> slides;
  final List<Map<String, dynamic>> properties;
  final List<Map<String, dynamic>> propertyGroups;
  final List<Map<String, dynamic>> resourceText;
  final List<Map<String, dynamic>> resourceShapes;

  EasyWorshipData({
    required this.slides,
    required this.properties,
    required this.propertyGroups,
    required this.resourceText,
    required this.resourceShapes,
  });

  factory EasyWorshipData.fromContent(Map<String, dynamic> content) {
    return EasyWorshipData(
      slides: List<Map<String, dynamic>>.from(content['slide'] ?? []),
      properties: List<Map<String, dynamic>>.from(content['slide_property'] ?? []),
      propertyGroups: List<Map<String, dynamic>>.from(content['slide_property_group'] ?? []),
      resourceText: List<Map<String, dynamic>>.from(content['resource_text'] ?? []),
      resourceShapes: List<Map<String, dynamic>>.from(content['resource_shape'] ?? []),
    );
  }
}