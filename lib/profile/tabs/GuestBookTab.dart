// GuestBookTab.dart
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../models/StickyNoteModel.dart';
import '../widgets/StickyNoteCard.dart';
import '../widgets/StickyNoteEditSheet.dart';
import '../widgets/GuestNoteRepository.dart';

class GuestBookTab extends StatefulWidget {
  final String heroNamespace;
  final String currentUserId;
  final String targetUserId;

  const GuestBookTab({
    super.key,
    this.heroNamespace = 'guestbook',
    required this.currentUserId,
    required this.targetUserId,
  });

  @override
  State<GuestBookTab> createState() => _GuestBookTabState();
}

class _GuestBookTabState extends State<GuestBookTab> {
  final _repo = GuestBookRepository();
  final List<StickyNoteModel> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _repo.fetchInitial();
    if (!mounted) return;
    setState(() {
      _notes
        ..clear()
        ..addAll(_sorted(data));
      _loading = false;
    });
  }

  List<StickyNoteModel> _sorted(List<StickyNoteModel> src) {
    final pinned = src.where((e) => e.pinned).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final normal = src.where((e) => !e.pinned).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return [...pinned, ...normal];
  }

  void _openComposer([StickyNoteModel? initial]) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StickyNoteEditSheet(
          initial: initial,
          currentUserId: widget.currentUserId,
          onSubmit: (note) {
            final idx = _notes.indexWhere((n) => n.id == note.id);
            setState(() {
              if (idx >= 0) {
                _notes[idx] = note;
              } else {
                _notes.insert(0, note);
              }
              _notes
                ..clear()
                ..addAll(_sorted(List.of(_notes)));
            });
          },
        ),
      ),
    );
  }

  void _togglePin(StickyNoteModel note) {
    setState(() {
      final idx = _notes.indexWhere((n) => n.id == note.id);
      if (idx >= 0) {
        _notes[idx] = note.copyWith(pinned: !note.pinned);
        final copy = List<StickyNoteModel>.from(_notes);
        _notes
          ..clear()
          ..addAll(_sorted(copy));
      }
    });
  }

  void _delete(StickyNoteModel note) {
    setState(() {
      _notes.removeWhere((n) => n.id == note.id);
    });
  }

  void _openDetail(StickyNoteModel note) {
    final isMine = note.authorId == widget.currentUserId;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(.15),
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => _NoteDetailOverlay(
          note: note,
          heroNamespace: widget.heroNamespace,
          isMine: isMine,
          onEdit: _openComposer,
        ),
      ),
    );
  }

  Future<void> _showNoteMenu(StickyNoteModel note) async {
    final isMine = note.authorId == widget.currentUserId;
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(note.pinned ? Icons.push_pin_outlined : Icons.push_pin),
              title: Text(note.pinned ? '핀 해제' : '핀 고정'),
              onTap: () => Navigator.pop(context, 'pin'),
            ),
            if (isMine)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('수정'),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('삭제'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    if (selected == 'pin') _togglePin(note);
    if (selected == 'edit' && isMine) _openComposer(note);
    if (selected == 'delete') _delete(note);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: MasonryGridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 520 ? 3 : 2,
                  mainAxisSpacing: 12.0,
                  crossAxisSpacing: 12.0,
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return GestureDetector(
                      onLongPress: () => _showNoteMenu(note),
                      child: StickyNoteCard(
                        note: note,
                        heroNamespace: widget.heroNamespace,
                        messy: true,
                        onTap: () => _openDetail(note),
                        onLongPress: () => _showNoteMenu(note),
                      ),
                    );
                  },
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openComposer(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _NoteDetailOverlay extends StatelessWidget {
  final StickyNoteModel note;
  final String heroNamespace;
  final bool isMine;
  final void Function(StickyNoteModel) onEdit;

  const _NoteDetailOverlay({
    required this.note,
    required this.heroNamespace,
    required this.isMine,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Stack(
          children: [
            // 바깥 터치로 닫기
            Positioned.fill(
              child: GestureDetector(onTap: () => Navigator.pop(context)),
            ),
            // 중앙 메모 (작게)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
                child: StickyNoteCard(
                  note: note,
                  heroNamespace: heroNamespace,
                  messy: false,
                  rotationOverrideDeg: 0.0, // double
                  onTap: () {},
                  onLongPress: () {},
                ),
              ),
            ),
            // // 하단 액션
            // Positioned(
            //   left: 16, right: 16, bottom: 16,
            //   child: Row(
            //     children: [
            //       if (isMine)
            //         Expanded(
            //           child: FilledButton.icon(
            //             style: FilledButton.styleFrom(
            //               backgroundColor: Colors.black,
            //               foregroundColor: Colors.white,
            //               disabledBackgroundColor: Colors.black26,
            //               disabledForegroundColor: Colors.white70,
            //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            //             ),
            //             onPressed: () => onEdit(note),
            //             icon: const Icon(Icons.edit),
            //             label: const Text('수정'),
            //           ),
            //         ),
            //       if (isMine) const SizedBox(width: 12),
            //       Expanded(
            //         child: FilledButton(
            //           style: FilledButton.styleFrom(
            //             backgroundColor: Colors.white,
            //             foregroundColor: Colors.black,
            //             disabledBackgroundColor: Colors.white70,
            //             disabledForegroundColor: Colors.black38,
            //             side: const BorderSide(color: Colors.black12),
            //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            //           ),
            //           onPressed: () => Navigator.pop(context),
            //           child: const Text('닫기'),
            //         ),
            //       ),
            //     ],
            //   ),
            // )

          ],
        ),
      ),
    );
  }
}