import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../data/video_repository.dart';

class UploadVideoScreen extends StatefulWidget {
  const UploadVideoScreen({super.key});
  @override State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final VideoRepository _repository = VideoRepository();
  File? _videoFile;
  double _progress = 0;
  bool _uploading = false;

  Future<void> _pickVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.video);
      if (!mounted || result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null || path.isEmpty) return;
      setState(() {
        _videoFile = File(path);
        _progress = 0;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر اختيار الفيديو: $error')));
    }
  }

  Future<void> _upload() async {
    final file = _videoFile;
    if (_uploading || file == null) return;
    setState(() {
      _uploading = true;
      _progress = 0;
    });

    try {
      await _repository.uploadVideo(
        videoFile: file,
        description: _descriptionController.text.trim(),
        hashtags: const [],
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress.clamp(0.0, 1.0));
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفع الفيديو بنجاح')));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل رفع الفيديو: $error')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileName = _videoFile?.path.split(Platform.pathSeparator).last;
    return Scaffold(
      appBar: AppBar(title: const Text('رفع فيديو')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          OutlinedButton.icon(
            onPressed: _uploading ? null : _pickVideo,
            icon: const Icon(Icons.video_library_outlined),
            label: Text(fileName ?? 'اختيار فيديو'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'الوصف', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          if (_uploading) ...[
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 8),
            Text('${(_progress * 100).toStringAsFixed(0)}%'),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _uploading || _videoFile == null ? null : _upload,
            icon: const Icon(Icons.cloud_upload_outlined),
            label: Text(_uploading ? 'جارٍ الرفع...' : 'رفع الفيديو'),
          ),
        ],
      ),
    );
  }
}