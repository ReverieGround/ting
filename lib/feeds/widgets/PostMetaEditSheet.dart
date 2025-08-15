// feeds/widgets/PostMetaEditSheet.dart
import 'package:flutter/material.dart';

class PostMetaEditSheet extends StatefulWidget {
  final String initialVisibility; // 'PUBLIC' | 'FOLLOWERS' | 'PRIVATE'
  final String? initialCategory;
  final String? initialValue;

  const PostMetaEditSheet({
    super.key,
    required this.initialVisibility,
    this.initialCategory,
    this.initialValue,
  });

  @override
  State<PostMetaEditSheet> createState() => _PostMetaEditSheetState();
}

class _PostMetaEditSheetState extends State<PostMetaEditSheet> {
  late String _visibility;
  String? _category;
  String? _value;
  
  final List<String> categories = ['요리', '밀키트', '식당', '배달'];
  final List<Map<String, String>> reviewValues = [
    {'label': 'Fire', 'image': 'assets/fire.png'},
    {'label': 'Tasty', 'image': 'assets/tasty.png'},
    {'label': 'Soso', 'image': 'assets/soso.png'},
    {'label': 'Woops', 'image': 'assets/woops.png'},
    {'label': 'Wack', 'image': 'assets/wack.png'},
  ];

  @override
  void initState() {
    super.initState();
    _visibility = widget.initialVisibility;
    _category = widget.initialCategory;
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Row(
              children: const [
                Text('게시물 설정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),

            // 공개 범위
            DropdownButtonFormField<String>(
              value: _visibility,
              items: const [
                DropdownMenuItem(value: 'PUBLIC', child: Text('전체 공개')),
                DropdownMenuItem(value: 'FOLLOWERS', child: Text('팔로워만')),
                DropdownMenuItem(value: 'PRIVATE', child: Text('비공개')),
              ],
              onChanged: (v) => setState(() => _visibility = v ?? _visibility),
              decoration: const InputDecoration(labelText: '공개 범위', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),

            // 카테고리
            DropdownButtonFormField<String>(
              value: _category,
              items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v),
              decoration: const InputDecoration(labelText: '카테고리', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),

            // value (라벨 선택)
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: reviewValues.map((v) {
                  final selected = _value == v;
                  return ChoiceChip(
                    label: Text(v['label']!),
                    selected: selected,
                    onSelected: (_) => setState(() => _value = v['label']),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'visibility': _visibility,
                    'category': _category,
                    'value': _value,
                  });
                },
                child: const Text('저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
