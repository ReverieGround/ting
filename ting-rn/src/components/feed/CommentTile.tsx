import { useState, useEffect } from 'react';
import { View, Text, Pressable, Alert, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import firestore from '@react-native-firebase/firestore';
import auth from '@react-native-firebase/auth';
import { ProfileAvatar } from '../common/ProfileAvatar';
import { TimeAgoText } from '../common/TimeAgoText';
import { colors } from '../../theme/colors';
import { Comment } from '../../hooks/useComments';
import { UserData, userFromJson } from '../../types/user';

interface Props {
  comment: Comment;
  postId: string;
  onDelete: (commentId: string) => void;
}

export function CommentTile({ comment, postId, onDelete }: Props) {
  const [user, setUser] = useState<UserData | null>(null);
  const isMine = auth().currentUser?.uid === comment.userId;

  useEffect(() => {
    firestore()
      .collection('users')
      .doc(comment.userId)
      .get()
      .then((snap) => {
        if (snap.exists()) {
          setUser(userFromJson(snap.data() as Record<string, unknown>));
        }
      });
  }, [comment.userId]);

  const handleDelete = () => {
    Alert.alert('댓글 삭제', '이 댓글을 삭제하시겠습니까?', [
      { text: '취소', style: 'cancel' },
      {
        text: '삭제',
        style: 'destructive',
        onPress: () => onDelete(comment.commentId),
      },
    ]);
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <ProfileAvatar profileUrl={user?.profileImage} size={24} />
        <Text style={styles.userName} numberOfLines={1}>
          {user?.userName ?? '...'}
        </Text>
        <TimeAgoText createdAt={comment.createdAt} fontSize={11} />
        {isMine && (
          <Pressable onPress={handleDelete} hitSlop={8}>
            <Ionicons name="trash-outline" size={14} color="#999" />
          </Pressable>
        )}
      </View>
      <Text style={styles.content}>{comment.content}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 4,
  },
  userName: {
    fontSize: 13,
    fontWeight: '600',
    color: colors.primary,
    flex: 1,
  },
  content: {
    fontSize: 14,
    color: colors.primary,
    paddingLeft: 30, // align with text after avatar
    lineHeight: 20,
  },
});
