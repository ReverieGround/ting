// widgets/LinkInputRow.dart
import 'package:flutter/material.dart';

class LinkInputRow extends StatefulWidget {
  final String initialText;
  final String hint;
  final String trailingAsset;
  final ValueChanged<String> onSubmitted;
  final VoidCallback? onTrailingTap;

  const LinkInputRow({
    super.key,
    required this.initialText,
    required this.hint,
    required this.trailingAsset,
    required this.onSubmitted,
    this.onTrailingTap,
  });

  @override
  State<LinkInputRow> createState() => _LinkInputRowState();
}

class _LinkInputRowState extends State<LinkInputRow> {
  late final TextEditingController _c;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initialText);
  }

  @override
  void didUpdateWidget(covariant LinkInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialText != widget.initialText) {
      _c.text = widget.initialText;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _c,
              onSubmitted: (v) {
                widget.onSubmitted(v);
                FocusScope.of(context).unfocus();
              },
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                fillColor: Colors.transparent,
              ),
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: widget.onTrailingTap,
            child: Image.asset(widget.trailingAsset, width: 20, height: 20),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}
