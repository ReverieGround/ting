import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/StickyNoteModel.dart';

class GuestBookService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String targetUserId) =>
      _db.collection('users').doc(targetUserId).collection('guestbook');

  Stream<List<StickyNoteModel>> watchNotes(String targetUserId) {
    return _col(targetUserId)
        .orderBy('pinned', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(_fromDoc).toList());
  }

  Future<void> addNote(String targetUserId, StickyNoteModel note) async {
  final ref = _col(targetUserId).doc(note.id);
    await ref.set({
      'id': note.id,
      'authorId': note.authorId,
      'authorName': note.authorName,
      'authorAvatarUrl': note.authorAvatarUrl,
      'text': note.text,
      'color': note.color.value,
      'pinned': note.pinned,
      'rotationDeg': note.rotationDeg, // 여기는 그대로 note에서 받아서 저장
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateNote(String targetUserId, StickyNoteModel note) async {
    await _col(targetUserId).doc(note.id).update({
      'text': note.text,
      'color': note.color.value,
      'rotationDeg': note.rotationDeg,
      'pinned': note.pinned,
    });
  }

  Future<void> deleteNote(String targetUserId, String noteId) async {
    await _col(targetUserId).doc(noteId).delete();
  }

  StickyNoteModel _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return StickyNoteModel(
      id: m['id'] as String,
      authorId: m['authorId'] as String,
      authorName: (m['authorName'] ?? '') as String,
      authorAvatarUrl: (m['authorAvatarUrl'] ?? '') as String,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      text: (m['text'] ?? '') as String,
      color: Color(m['color'] as int),
      pinned: (m['pinned'] ?? false) as bool,
      rotationDeg: (m['rotationDeg'] ?? 0).toDouble(), // 저장된 값 그대로 사용
    );
  }

}
