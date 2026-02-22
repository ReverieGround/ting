import { useCallback } from 'react';
import { postService } from '../services/postService';
import { useFirestoreQuery } from './useFirestoreStream';

export interface Comment {
  commentId: string;
  postId: string;
  userId: string;
  content: string;
  createdAt: Date;
  updatedAt: Date;
}

function transformComment(data: Record<string, unknown>, id: string): Comment {
  return {
    commentId: (data.comment_id as string) ?? id,
    postId: (data.post_id as string) ?? '',
    userId: (data.user_id as string) ?? '',
    content: (data.content as string) ?? '',
    createdAt: (data.created_at as any)?.toDate?.() ?? new Date(),
    updatedAt: (data.updated_at as any)?.toDate?.() ?? new Date(),
  };
}

export function useComments(postId: string, limit?: number) {
  const query = postService.commentsStream(postId, limit);
  const { data: comments, loading } = useFirestoreQuery(query, transformComment);

  const addComment = useCallback(
    (content: string) => postService.addComment({ postId, content }),
    [postId],
  );

  const editComment = useCallback(
    (commentId: string, content: string) =>
      postService.editComment({ postId, commentId, content }),
    [postId],
  );

  const deleteComment = useCallback(
    (commentId: string) => postService.deleteComment({ postId, commentId }),
    [postId],
  );

  return { comments, loading, addComment, editComment, deleteComment };
}
