import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import '../../resources/models/resource_model.dart';
import '../../resources/services/resource_service.dart';

class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});

  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen> {
  final ResourceService _resourceService = ResourceService();
  late Future<List<ResourceModel>> _resourcesFuture;
  
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      _resourcesFuture = _resourceService.getResources(showFree: true, showPremium: true);
    });
  }

  Future<void> _handleUpload() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'mp4', 'png', 'jpg'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isUploading = true;
        });
        
        final filePath = result.files.single.path!;
        final file = File(filePath);
        final sizeMB = (file.lengthSync() / (1024 * 1024)).toStringAsFixed(1);
        final extension = result.files.single.extension?.toUpperCase() ?? 'FILE';
        final title = result.files.single.name;
        
        // Show dialog to gather more info before upload
        if (!mounted) return;
        
        String category = 'Notes';
        bool isPremium = false;
        String targetExam = 'Both';
        
        final bool? proceed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: const Text('Resource Details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: targetExam,
                    decoration: const InputDecoration(labelText: 'Target Exam', border: OutlineInputBorder()),
                    items: ['Both', 'JEE', 'NEET'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) => setDialogState(() => targetExam = value!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: ['Notes', 'Formulas', 'PYQs'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) => setDialogState(() => category = value!),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Premium Resource'),
                    value: isPremium,
                    onChanged: (value) => setDialogState(() => isPremium = value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => context.pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => context.pop(true),
                  child: const Text('Upload'),
                ),
              ],
            ),
          ),
        );
        
        if (proceed != true) {
          setState(() {
            _isUploading = false;
          });
          return;
        }

        await _resourceService.addResource(
          file: file,
          title: title,
          category: category,
          type: extension,
          fileSize: '$sizeMB MB',
          isPremium: isPremium,
          targetExam: targetExam,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchData(); // refresh list
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _confirmDelete(ResourceModel resource) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Resource'),
        content: Text('Are you sure you want to delete "${resource.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              dialogContext.pop(); // Close dialog
              try {
                await _resourceService.deleteResource(resource.id, resource.fileUrl);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resource deleted successfully')));
                  _fetchData(); // Refresh list
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Content'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _handleUpload,
        icon: _isUploading 
            ? const SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              )
            : const Icon(LucideIcons.upload),
        label: Text(_isUploading ? 'Uploading...' : 'Upload Material'),
      ),
      body: FutureBuilder<List<ResourceModel>>(
        future: _resourcesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading resources: ${snapshot.error}'));
          }

          final resources = snapshot.data ?? [];

          if (resources.isEmpty) {
            return const Center(child: Text('No materials uploaded yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: resources.length,
            itemBuilder: (context, index) {
              final file = resources[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(LucideIcons.fileText, color: colorScheme.primary),
                  ),
                  title: Text(file.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${file.category} • ${file.type} • ${file.fileSizeOrDuration}'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete', 
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        onTap: () {
                          // Add small delay to let popup menu close before showing dialog
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (context.mounted) {
                              _confirmDelete(file);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      ),
    );
  }
}
