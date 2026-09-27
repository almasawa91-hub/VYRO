import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/feed_repository.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});
  @override State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  final FeedRepository _repository = FeedRepository();
  final ImagePicker _picker = ImagePicker();
  final List<File> _images = [];
  bool _saving = false;
  String _privacy = 'public';

  Future<void> _pickImages() async {
    try {
      final files = await _picker.pickMultiImage(imageQuality: 85);
      if (!mounted) return;
      setState(() {
        _images..clear()..addAll(files.map((file) => File(file.path)).take(8));
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر اختيار الصور: ' + error.toString())));
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final text = _textController.text.trim();
    if (text.isEmpty && _images.isEmpty) return;
    setState(() => _saving = true);
    try {
      await _repository.createPost(text: text, privacy: _privacy, imageFiles: _images);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر النشر: ' + error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء منشور'),
        actions: [TextButton(onPressed: _saving ? null : _save, child: const Text('نشر'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _textController,
            maxLines: 7,
            decoration: const InputDecoration(hintText: 'ماذا تريد أن تشارك؟', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _privacy,
            decoration: const InputDecoration(labelText: 'الخصوصية', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'public', child: Text('عام')),
              DropdownMenuItem(value: 'friends', child: Text('الأصدقاء')),
              DropdownMenuItem(value: 'only_me', child: Text('أنا فقط')),
            ],
            onChanged: (value) => setState(() => _privacy = value ?? 'public'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _saving ? null : _pickImages,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('إضافة صور'),
          ),
          if (_images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _images.map((file) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(file, width: 90, height: 90, fit: BoxFit.cover),
                )).toList(),
              ),
            ),
          if (_saving) const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }
}