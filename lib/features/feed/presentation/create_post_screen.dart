import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/feed_repository.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});
  @override State<CreatePostScreen> createState() => _CreatePostScreenState();
}
class _CreatePostScreenState extends State<CreatePostScreen> {
  final _text = TextEditingController();
  final _repo = FeedRepository();
  final _picker = ImagePicker();
  final List<File> _images = [];
  bool _saving = false;
  String _privacy = 'public';

  Future<void> _pick() async {
    final files = await _picker.pickMultiImage(imageQuality: 85);
    setState(() => _images..clear()..addAll(files.map((e) => File(e.path)).take(8)));
  }
  Future<void> _save() async {
    if (_text.text.trim().isEmpty && _images.isEmpty) return;
    setState(() => _saving = true);
    try {
      await _repo.createPost(text: _text.text, privacy: _privacy, imageFiles: _images);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر النشر: $e')));
    } finally { if (mounted) setState(() => _saving = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('إنشاء منشور'), actions: [
      TextButton(onPressed: _saving ? null : _save, child: const Text('نشر')),
    ]),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      TextField(controller: _text, maxLines: 7, decoration: const InputDecoration(hintText: 'ماذا تريد أن تشارك؟', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value: _privacy, decoration: const InputDecoration(labelText: 'الخصوصية', border: OutlineInputBorder()),
        items: const [DropdownMenuItem(value:'public',child:Text('عام')),DropdownMenuItem(value:'friends',child:Text('الأصدقاء')),DropdownMenuItem(value:'only_me',child:Text('أنا فقط'))],
        onChanged: (v) => setState(() => _privacy = v ?? 'public'),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: _pick, icon: const Icon(Icons.photo_library_outlined), label: const Text('إضافة صور')),
      if (_images.isNotEmpty) ...[
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: _images.map((f) => ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(f,width:90,height:90,fit:BoxFit.cover))).toList()),
      ],
      if (_saving) const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
    ]),
  );
  @override void dispose(){_text.dispose();super.dispose();}
}
