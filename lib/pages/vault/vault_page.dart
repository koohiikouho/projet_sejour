import 'dart:io';
import 'package:flutter/material.dart';
import 'package:projet_sejour/services/vault_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

class VaultPage extends StatefulWidget {
  const VaultPage({super.key});

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final VaultService _vaultService = VaultService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showUploadModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DocumentUploadModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Document Vault', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'My Private Documents'),
            Tab(text: 'Program Materials'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDocumentList(_vaultService.streamMyDocuments(), true),
          _buildDocumentList(_vaultService.streamSharedDocuments(), false),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadModal,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
      ),
    );
  }

  Widget _buildDocumentList(Stream<List<VaultDocument>> stream, bool isPrivate) {
    return StreamBuilder<List<VaultDocument>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final documents = snapshot.data ?? [];

        if (documents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  isPrivate
                    ? 'No private documents yet.'
                    : 'No program materials shared yet.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 16, bottom: 80),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final doc = documents[index];
            return _buildDocumentCard(doc);
          },
        );
      },
    );
  }

  Widget _buildDocumentCard(VaultDocument doc) {
    final bool isPdf = doc.fileUrl.toLowerCase().contains('.pdf');
    final IconData fileIcon = isPdf ? Icons.picture_as_pdf : Icons.image;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(fileIcon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(doc.category, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            Text(
              'Uploaded on ${DateFormat('MMM d, yyyy').format(doc.uploadDate)}',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
            if (doc.isVerified)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.verified, color: Colors.green, size: 14),
                    SizedBox(width: 4),
                    Text('Verified by Admin', style: TextStyle(color: Colors.green, fontSize: 11)),
                  ],
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _confirmDelete(doc);
            } else if (value == 'open') {
              // TODO: Implement open or download logic
              // For images, we can show a cached network image
              // For PDFs, we might need url_launcher or a pdf viewer package
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'open',
              child: Text('Open File'),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(VaultDocument doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document?'),
        content: Text('Are you sure you want to delete "${doc.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show loading indicator in a robust app
      try {
        await _vaultService.deleteDocument(doc);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document deleted.')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }
}

class DocumentUploadModal extends StatefulWidget {
  const DocumentUploadModal({super.key});

  @override
  State<DocumentUploadModal> createState() => _DocumentUploadModalState();
}

class _DocumentUploadModalState extends State<DocumentUploadModal> {
  final VaultService _vaultService = VaultService();
  final _titleController = TextEditingController();
  String _selectedCategory = 'Personal IDs';
  File? _selectedFile;
  bool _isUploading = false;

  final List<String> _categories = [
    'Personal IDs',
    'Visas & Travel Docs',
    'Medical Information',
    'Consent Forms',
    'Other'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _upload() async {
    if (_titleController.text.trim().isEmpty || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a title and select a file.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      await _vaultService.uploadDocument(
        _selectedFile!,
        _titleController.text.trim(),
        _selectedCategory,
        isGlobal: false, // Default to private for now
      );
      if (mounted) {
        Navigator.pop(context); // Close the modal
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload complete!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Upload Document',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Document Title',
              border: OutlineInputBorder(),
              hintText: 'e.g. Passport Copy',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: _categories.map((String category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() => _selectedCategory = newValue);
              }
            },
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.attach_file),
            label: Text(_selectedFile != null ? 'File Selected: ${_selectedFile!.path.split('/').last}' : 'Choose File (PDF/Image)'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.centerLeft,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isUploading ? null : _upload,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isUploading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Upload to Vault', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
