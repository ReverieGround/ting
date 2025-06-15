import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ImageEditPage extends StatefulWidget {
  final File originalFile;

  const ImageEditPage({super.key, required this.originalFile});

  @override
  State<ImageEditPage> createState() => _ImageEditPageState();
}

class _ImageEditPageState extends State<ImageEditPage> {
  img.Image? _decodedImage;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.originalFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded != null) {
      setState(() => _decodedImage = decoded);
    }
  }

  void _rotateRight() {
    if (_decodedImage != null) {
      setState(() => _decodedImage = img.copyRotate(_decodedImage!, angle: 90));
    }
  }

  void _rotateLeft() {
    if (_decodedImage != null) {
      setState(() => _decodedImage = img.copyRotate(_decodedImage!, angle: -90));
    }
  }

  Future<void> _saveAndReturn() async {
    if (_decodedImage == null) return;
    final newPath = widget.originalFile.path.replaceFirst('.jpg', '_edited.jpg');
    final newFile = await File(newPath).writeAsBytes(img.encodeJpg(_decodedImage!));
    Navigator.pop(context, newFile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("이미지 회전"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _decodedImage != null
                ? Center(
                    child: Image.memory(
                      Uint8List.fromList(img.encodeJpg(_decodedImage!)),
                      fit: BoxFit.contain,
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _rotateLeft,
                  icon: const Icon(Icons.rotate_left),
                  label: const Text("왼쪽으로 회전"),
                ),
                ElevatedButton.icon(
                  onPressed: _rotateRight,
                  icon: const Icon(Icons.rotate_right),
                  label: const Text("오른쪽으로 회전"),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: ElevatedButton(
              onPressed: _saveAndReturn,
              child: const Text("저장하고 돌아가기"),
            ),
          ),
        ],
      ),
    );
  }
}