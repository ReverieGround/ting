// StickyNoteCard.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/StickyNoteModel.dart';

class StickyNoteCard extends StatelessWidget {
  final StickyNoteModel note;
  final String heroNamespace;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool messy;
  final double? rotationOverrideDeg;

  const StickyNoteCard({
    super.key,
    required this.note,
    this.heroNamespace = 'guestbook',
    this.onTap,
    this.onLongPress,
    this.messy = true,
    this.rotationOverrideDeg,
  });

  double _r(int salt) {
    final s = note.id.hashCode ^ salt;
    return Random(s).nextDouble();
  }

  @override
  Widget build(BuildContext context) {
    final r1 = _r(7), r2 = _r(11), r3 = _r(19), r4 = _r(23), r5 = _r(29);
    final double deg   = rotationOverrideDeg ?? (messy ? (-5 + r1 * 10) : 0.0);
    final double dx    = messy ? (-6 + r2 * 12) : 0.0;
    final double dy    = messy ? (-8 + r3 * 10) : 0.0;
    final double scale = messy ? (0.98 + r4 * 0.04) : 1.0;
    final double shadow= 8 + r5 * 6;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
      decoration: BoxDecoration(
        color: note.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: shadow,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // _PinTape(pinned: note.pinned),
              // const SizedBox(height: 6),
              Text(
                note.text,
                style: GoogleFonts.nanumPenScript(
                  fontSize: 20,
                  height: 1.2,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundImage: note.authorAvatarUrl.isEmpty
                        ? null
                        : NetworkImage(note.authorAvatarUrl),
                    child: note.authorAvatarUrl.isEmpty
                        ? const Icon(Icons.person, size: 14)
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      note.authorName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ),
                  Text(
                    _timeAgo(note.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black.withOpacity(0.45),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return Hero(
      tag: '$heroNamespace-note_${note.id}',
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.rotate(
          angle: deg * pi / 180,
          child: Transform.scale(
            scale: scale,
            child: card,
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }
}

class _PinTape extends StatelessWidget {
  final bool pinned;
  const _PinTape({required this.pinned});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Transform.rotate(
        angle: -0.06,
        child: Container(
          height: 16,
          width: 42,
          decoration: BoxDecoration(
            color: pinned ? Colors.amber.withOpacity(0.6) : Colors.white70,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}
