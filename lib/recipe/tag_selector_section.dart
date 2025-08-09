import 'package:flutter/material.dart';

class TagSelectorSection extends StatefulWidget {
  const TagSelectorSection({super.key});

  @override
  State<TagSelectorSection> createState() => _TagSelectorSectionState();
}

class _TagSelectorSectionState extends State<TagSelectorSection> {
  final TextEditingController _tagController = TextEditingController();
  final List<String> _tags = [];

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty || _tags.contains(trimmed)) return;

    setState(() {
      _tags.add(trimmed);
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("태그", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                onSubmitted: _addTag,
                decoration: const InputDecoration(
                  hintText: "태그 입력 (예: 매운맛, 초보자용)",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _addTag(_tagController.text),
              child: const Text("추가"),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _tags.map((tag) {
            return Chip(
              label: Text("#$tag"),
              deleteIcon: const Icon(Icons.close),
              onDeleted: () => _removeTag(tag),
            );
          }).toList(),
        ),
      ],
    );
  }
}
