import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../../AppHeader.dart'; 

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
      backgroundColor: Color.fromRGBO(20, 20, 20, 1),
      appBar: AppHeader(
        leadingColor: Colors.white,
        backgroundColor: Color.fromRGBO(20, 20, 20, 1),
        centerTitle: true,
        titleWidget: Text("이미지 편집",
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
      
      // AppBar(
          
      //     title: const Text("이미지 편집",
      //     style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      //   ),
      //   backgroundColor: Color.fromRGBO(20, 20, 20, 1),
      //   foregroundColor: Colors.white,
      //   elevation: 0,
      // ),
      body: Column(
        children: [
          Expanded(
            child: _decodedImage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.memory(
                        Uint8List.fromList(img.encodeJpg(_decodedImage!)),
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Left Rotate Button
                ElevatedButton.icon(
                  onPressed: _rotateLeft,
                  icon: const Icon(
                    Icons.rotate_left,
                    color: const Color.fromRGBO(255, 110, 199, 1), 
                  ),
                  label: const Text(
                    "왼쪽으로 회전",
                    style: TextStyle(
                      color: Colors.white, 
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, // White background
                    foregroundColor: const Color.fromRGBO(255, 110, 199, 1), 
                    elevation: 4,                  // Keep the noticeable shadow
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // More rounded corners
                      side: BorderSide(
                        color: const Color.fromRGBO(255, 110, 199, 1), // Pink border color
                        width: 1, // Border thickness
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Spacious padding
                  ),
                ),
                // Right Rotate Button
                ElevatedButton.icon(
                  onPressed: _rotateRight,
                  icon: const Icon(
                    Icons.rotate_right,
                    color: const Color.fromRGBO(255, 110, 199, 1), 
                  ),
                  label: const Text(
                    "오른쪽으로 회전",
                    style: TextStyle(
                      color: Colors.white, 
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, // White background
                    foregroundColor: const Color.fromRGBO(255, 110, 199, 1), 
                    elevation: 4,                  // Keep the noticeable shadow
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // More rounded corners
                      side: BorderSide(
                        color: const Color.fromRGBO(255, 110, 199, 1), // Pink border color
                        width: 1, // Border thickness
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Spacious padding
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 10, 30, 20),
            child: ElevatedButton(
              onPressed: _saveAndReturn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: const Color.fromRGBO(255, 110, 199, 1), // Setting text color for better contrast
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // More rounded corners
                  side: BorderSide(
                    color: const Color.fromRGBO(255, 110, 199, 1), // Pink border color
                    width: 1, // Border thickness
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12), // Increased horizontal padding
                minimumSize: const Size(double.infinity, 40), // Makes the button full width (or nearly)
              ),
              child: const Text(
                "저장하고 돌아가기",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  ), // Slightly larger text for better readability
              ),
            ),
          ),
        ],
      ),
    );
  }
}