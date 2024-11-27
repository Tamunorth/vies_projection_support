// lib/widgets/easyworship_scripture_viewer.dart
import 'package:flutter/material.dart';

class EasyWorshipScriptureViewer extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> content;
  
  const EasyWorshipScriptureViewer({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final slides = content['slide'] ?? [];
    final properties = content['slide_property'] ?? [];
    final propertyGroups = content['slide_property_group'] ?? [];
    final resourceText = content['resource_text'] ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scripture Presentation',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            
            // Slides Section
            Text(
              'Slides (${slides.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: slides.length,
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  final slideProperties = properties.where(
                    (prop) => _getSlidePropertyGroup(propertyGroups, prop) == slide['rowid']
                  ).toList();
                  
                  return ExpansionTile(
                    title: Text('Slide ${index + 1}: ${slide['title'] ?? 'Untitled'}'),
                    subtitle: Text('UID: ${slide['slide_uid']}'),
                    children: [
                      // Properties for this slide
                      ...slideProperties.map((prop) => ListTile(
                        dense: true,
                        title: Text(prop['key'] ?? ''),
                        subtitle: Text(prop['value'] ?? ''),
                      )),
                      
                      // Resource text if available
                      if (resourceText.isNotEmpty)
                        ListTile(
                          title: const Text('Content'),
                          subtitle: Text(resourceText.first['rtf'] ?? ''),
                        ),
                    ],
                  );
                },
              ),
            ),
            
            // Stats
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Slides: ${slides.length}'),
                  Text('Properties: ${properties.length}'),
                  Text('Property Groups: ${propertyGroups.length}'),
                  Text('Resource Shapes: ${content['resource_shape']?.length ?? 0}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  dynamic _getSlidePropertyGroup(List<Map<String, dynamic>> groups, Map<String, dynamic> property) {
    final groupId = property['group_id'];
    final group = groups.firstWhere(
      (g) => g['rowid'] == groupId,
      orElse: () => {'link_id': null},
    );
    return group['link_id'];
  }
}

// // Add this to your handler class
// class EasyWorshipData {
//   final List<Map<String, dynamic>> slides;
//   final List<Map<String, dynamic>> properties;
//   final List<Map<String, dynamic>> propertyGroups;
//   final List<Map<String, dynamic>> resourceText;
//   final List<Map<String, dynamic>> resourceShapes;

//   EasyWorshipData({
//     required this.slides,
//     required this.properties,
//     required this.propertyGroups,
//     required this.resourceText,
//     required this.resourceShapes,
//   });

//   factory EasyWorshipData.fromContent(Map<String, dynamic> content) {
//     return EasyWorshipData(
//       slides: List<Map<String, dynamic>>.from(content['slide'] ?? []),
//       properties: List<Map<String, dynamic>>.from(content['slide_property'] ?? []),
//       propertyGroups: List<Map<String, dynamic>>.from(content['slide_property_group'] ?? []),
//       resourceText: List<Map<String, dynamic>>.from(content['resource_text'] ?? []),
//       resourceShapes: List<Map<String, dynamic>>.from(content['resource_shape'] ?? []),
//     );
//   }
// }