import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/StickyNoteModel.dart';
import 'NoteColorPalette.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class StickyNoteEditSheet extends StatefulWidget {
  final StickyNoteModel? initial;
  final String currentUserId;         
  
  final void Function(StickyNoteModel note) onSubmit;

  const StickyNoteEditSheet({
    super.key, 
    this.initial, 
    required this.onSubmit,
    required this.currentUserId,          
  });

  @override
  State<StickyNoteEditSheet> createState() => _StickyNoteEditSheetState();
}

class _StickyNoteEditSheetState extends State<StickyNoteEditSheet> {
  late TextEditingController _controller;
  late Color _color;
  bool _pinned = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial?.text ?? '');
    _color = widget.initial?.color ?? NoteColorPalette.pastel.first;
    _pinned = widget.initial?.pinned ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: ConstrainedBox( // 작게
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: 6, width: 44, decoration: BoxDecoration(
                color: Colors.black12, borderRadius: BorderRadius.circular(3),
              )),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                maxLines: 3, // 작게
                inputFormatters: [LengthLimitingTextInputFormatter(20)],
                maxLength: 20,
                buildCounter: (_, {required currentLength, maxLength, required isFocused}) => const SizedBox.shrink(),
                style: GoogleFonts.nanumPenScript(fontSize: 20, height: 1.2),
                decoration: InputDecoration(
                  hintText: '최대 20자',
                  filled: true,
                  fillColor: _color,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 10),
              // 색/핀/회전 UI는 그대로 두고, 공간 절약 위해 슬라이더만 유지
              Row(
                children: [
                  Wrap(
                    spacing: 6,
                    children: NoteColorPalette.pastel.map((c) {
                      final selected = _color == c;
                      return GestureDetector(
                        onTap: () => setState(() => _color = c),
                        child: Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: c, shape: BoxShape.circle,
                            border: Border.all(color: selected ? Colors.black87 : Colors.black12, width: selected ? 2 : 1),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const Spacer(),
                  FilterChip(
                    selected: _pinned,
                    onSelected: (v) => setState(() => _pinned = v),
                    label: const Text('핀'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final text = _controller.text.trim();
                    if (text.isEmpty) return;
                    final clipped = text.characters.take(20).toString(); // 최종 방어
                    final now = DateTime.now();
                    final base = widget.initial ??
                        StickyNoteModel(
                          id: now.microsecondsSinceEpoch.toString(),
                          authorId: widget.currentUserId,
                          authorName: "",
                          authorAvatarUrl: "",
                          createdAt: now,
                          text: '',
                          color: _color,
                        );
                    widget.onSubmit(
                      base.copyWith(
                        text: clipped,
                        color: _color,
                        pinned: _pinned,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('저장'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
