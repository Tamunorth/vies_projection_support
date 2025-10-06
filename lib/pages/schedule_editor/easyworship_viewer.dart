import 'dart:developer' as developer;
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:untitled/utils/easyworship_handler.dart';

class EasyWorshipViewer extends StatefulWidget {
  const EasyWorshipViewer({super.key});

  @override
  State<EasyWorshipViewer> createState() => _EasyWorshipViewerState();
}

class _EasyWorshipViewerState extends State<EasyWorshipViewer> {
  final EasyWorshipHandler _handler = EasyWorshipHandler();
  bool _isLoading = false;
  String? _selectedFilePath;
  Map<String, dynamic> _content = {};
  String _status = 'No file selected';
  String? _error;
  String? _extractedDbPath;

  List<String> _availableTables = [];
  Map<String, List<Map<String, String>>> _tableStructures = {};

  Future<void> _pickAndProcessFile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _status = 'Selecting file...';
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ewsx', 'db'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _status = 'No file selected';
          _isLoading = false;
        });
        return;
      }

      _selectedFilePath = result.files.first.path!;
      final fileName = path.basename(_selectedFilePath!);
      setState(() => _status = 'Processing $fileName...');

      // Create temp directory for extraction
      final tempDir = await Directory.systemTemp.createTemp('easyworship_');
      _extractedDbPath = path.join(tempDir.path, 'database.db');

      // Extract the database
      await _handler.extractAndSaveDb(_selectedFilePath!, _extractedDbPath!);

      setState(() => _status = 'Analyzing database structure...');

      // Get available tables
      _availableTables = await _handler.getDatabaseTables(_extractedDbPath!);
      developer.log('Found tables: $_availableTables');

      // Get structure for each table
      _tableStructures = {};
      for (final table in _availableTables) {
        _tableStructures[table] =
            await _handler.getTableStructure(_extractedDbPath!, table);
        developer.log('Table $table structure: ${_tableStructures[table]}');
      }

      setState(() => _status = 'Reading database content...');

      // Read the content
      _content = await _handler.getEasyWorshipContent(_extractedDbPath!);

      setState(() {
        _isLoading = false;
        _status = 'Loaded ${_content.length} tables';
      });
    } catch (e, stack) {
      developer.log('Error processing file', error: e, stackTrace: stack);
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _status = 'Error occurred';
      });
    }
  }

  Widget _buildContentList(String tableName, List items) {
    if (items.isEmpty) {
      return const Center(child: Text('No items found'));
    }

    final columns = _tableStructures[tableName] ?? [];
    final displayColumns = columns.take(3).map((c) => c['name']!).toList();

    return Column(
      children: [
        // Column headers
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: displayColumns
                .map(
                  (column) => Expanded(
                    child: Text(
                      column,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        // Data rows
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index] as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Row(
                    children: displayColumns
                        .map(
                          (column) => Expanded(
                            child: Text(
                              item[column]?.toString() ?? 'null',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  onTap: () => _showItemDetails(context, tableName, item),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EasyWorship File Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _pickAndProcessFile,
            tooltip: 'Open EasyWorship File',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            padding: const EdgeInsets.all(8),
            color: _error != null ? Colors.red.shade100 : Colors.grey.shade100,
            child: Row(
              children: [
                if (_selectedFilePath != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      'File: ${path.basename(_selectedFilePath!)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                Expanded(
                  child: Text(
                    _error ?? _status,
                    style: TextStyle(
                      color: _error != null ? Colors.red : Colors.black,
                    ),
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: _content.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.upload_file,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.file_upload),
                          label: const Text('Select EasyWorship File'),
                          onPressed: _isLoading ? null : _pickAndProcessFile,
                        ),
                      ],
                    ),
                  )
                : DefaultTabController(
                    length: _content.length,
                    child: Column(
                      children: [
                        TabBar(
                          isScrollable: true,
                          tabs: _content.keys
                              .map((section) => Tab(
                                    text: section[0].toUpperCase() +
                                        section.substring(1),
                                  ))
                              .toList(),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: _content.entries.map((entry) {
                              final items = entry.value as List;
                              return _buildContentList(entry.key, items);
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemSubtitle(String section, Map<String, dynamic> item) {
    switch (section.toLowerCase()) {
      case 'songs':
        return Text('Author: ${item['author'] ?? 'Unknown'}');
      case 'presentations':
        return Text('Slides: ${item['slideCount'] ?? '0'}');
      case 'scriptures':
        return Text(
            '${item['book'] ?? ''} ${item['chapter'] ?? ''}:${item['verse'] ?? ''}');
      default:
        return const SizedBox.shrink();
    }
  }

  void _showItemDetails(
      BuildContext context, String section, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${section.toUpperCase()} Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: item.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              '${e.key}:',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              e.value?.toString() ?? 'null',
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up temporary files
    if (_extractedDbPath != null) {
      File(_extractedDbPath!).parent.delete(recursive: true);
    }
    super.dispose();
  }
}

// Causing statement: SELECT * FROM Presentations) sql 'SELECT * FROM Presentations' {details: {database: {path: C:\Users\CCI_LO~1\AppData\Local\Temp\easyworship_233efc6f\database.db, id: 1, readOnly: false, singleInstance: true}}})
