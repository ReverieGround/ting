import { useState, useCallback } from 'react';
import {
  View,
  Text,
  TextInput,
  Pressable,
  KeyboardAvoidingView,
  Platform,
  FlatList,
  ActivityIndicator,
  StyleSheet,
} from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useQuery } from '@tanstack/react-query';
import firestore from '@react-native-firebase/firestore';
import { colors, spacing } from '../../../src/theme/colors';
import { FeedCard } from '../../../src/components/feed/FeedCard';
import { CommentTile } from '../../../src/components/feed/CommentTile';
import { useComments, Comment } from '../../../src/hooks/useComments';
import { postFromMap } from '../../../src/types/post';
import { userFromJson } from '../../../src/types/user';
import { FeedData } from '../../../src/types/feed';
import auth from '@react-native-firebase/auth';

async function fetchSingleFeed(postId: string): Promise<FeedData | null> {
  const postSnap = await firestore().collection('posts').doc(postId).get();
  if (!postSnap.exists()) return null;

  const postData = postFromMap({
    ...postSnap.data(),
    post_id: postSnap.id,
  } as Record<string, unknown>);

  const uid = auth().currentUser?.uid;
  const postRef = firestore().collection('posts').doc(postId);

  const [userSnap, likesAgg, commentsAgg, likeDoc] = await Promise.all([
    firestore().collection('users').doc(postData.userId).get(),
    postRef.collection('likes').count().get(),
    postRef.collection('comments').count().get(),
    uid ? postRef.collection('likes').doc(uid).get() : Promise.resolve(null),
  ]);

  if (!userSnap.exists()) return null;

  return {
    user: userFromJson(userSnap.data() as Record<string, unknown>),
    post: postData,
    isPinned: false,
    isLikedByUser: likeDoc != null ? likeDoc.exists() : false,
    numLikes: (likesAgg as any).data().count ?? 0,
    numComments: (commentsAgg as any).data().count ?? 0,
  };
}

export default function PostDetailPage() {
  const { postId } = useLocalSearchParams<{ postId: string }>();
  const insets = useSafeAreaInsets();
  const [text, setText] = useState('');
  const [posting, setPosting] = useState(false);

  const {
    data: feed,
    isLoading: feedLoading,
  } = useQuery({
    queryKey: ['post', postId],
    queryFn: () => fetchSingleFeed(postId!),
    enabled: !!postId,
  });

  const { comments, loading: commentsLoading, addComment, deleteComment } =
    useComments(postId!, 100);

  const handleSend = useCallback(async () => {
    if (!text.trim() || posting) return;
    setPosting(true);
    try {
      await addComment(text.trim());
      setText('');
    } finally {
      setPosting(false);
    }
  }, [text, posting, addComment]);

  const renderComment = useCallback(
    ({ item }: { item: Comment }) => (
      <CommentTile comment={item} postId={postId!} onDelete={deleteComment} />
    ),
    [postId, deleteComment],
  );

  if (feedLoading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  }

  if (!feed) {
    return (
      <View style={styles.center}>
        <Text style={styles.emptyText}>포스트를 찾을 수 없습니다</Text>
      </View>
    );
  }

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      keyboardVerticalOffset={insets.top}
    >
      <FlatList
        data={comments}
        renderItem={renderComment}
        keyExtractor={(c) => c.commentId}
        contentContainerStyle={{ paddingBottom: 80 }}
        ListHeaderComponent={
          <View>
            <FeedCard
              feed={feed}
              blockNavPost
              showContent
              showIcons
              showTags
              imageHeight={null}
            />
            <View style={styles.divider} />
            {commentsLoading && (
              <ActivityIndicator
                size="small"
                color={colors.primary}
                style={{ marginVertical: 12 }}
              />
            )}
          </View>
        }
        ListEmptyComponent={
          !commentsLoading ? (
            <Text style={styles.noComments}>아직 댓글이 없어요</Text>
          ) : null
        }
      />

      {/* Comment input bar */}
      <View
        style={[styles.inputBar, { paddingBottom: Math.max(insets.bottom, 8) }]}
      >
        <TextInput
          style={styles.input}
          placeholder="댓글을 입력하세요..."
          placeholderTextColor="#666"
          value={text}
          onChangeText={setText}
          onSubmitEditing={handleSend}
          returnKeyType="send"
          editable={!posting}
        />
        <Pressable onPress={handleSend} disabled={posting || !text.trim()}>
          {posting ? (
            <ActivityIndicator size="small" color={colors.primary} />
          ) : (
            <Ionicons
              name="send"
              size={22}
              color={text.trim() ? colors.primary : '#555'}
            />
          )}
        </Pressable>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.bgLight,
  },
  center: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.bgLight,
  },
  emptyText: {
    color: colors.hint,
    fontSize: 16,
  },
  divider: {
    height: StyleSheet.hairlineWidth,
    backgroundColor: colors.divider,
    marginVertical: spacing.sm,
  },
  noComments: {
    color: '#666',
    textAlign: 'center',
    paddingVertical: 24,
    fontSize: 14,
  },
  inputBar: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingTop: 8,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: colors.divider,
    backgroundColor: colors.bgDark,
    gap: 8,
  },
  input: {
    flex: 1,
    height: 40,
    borderRadius: 20,
    backgroundColor: 'rgba(255,255,255,0.08)',
    paddingHorizontal: 16,
    color: colors.primary,
    fontSize: 14,
  },
});
