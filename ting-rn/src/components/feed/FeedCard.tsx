import { Pressable, View, StyleSheet } from 'react-native';
import { useRouter } from 'expo-router';
import { FeedData } from '../../types/feed';
import { Head } from './Head';
import { FeedImages } from './FeedImages';
import { Content } from './Content';
import { StatIcons } from './StatIcons';
import { colors } from '../../theme/colors';
import auth from '@react-native-firebase/auth';

interface Props {
  feed: FeedData;
  fontColor?: string;
  showTopWriter?: boolean;
  overlayTopWriter?: boolean;
  showTags?: boolean;
  showContent?: boolean;
  showIcons?: boolean;
  imageHeight?: number | null;
  blockNavPost?: boolean;
}

export function FeedCard({
  feed,
  fontColor = colors.primary,
  showTopWriter = true,
  overlayTopWriter = false,
  showTags = true,
  showContent = true,
  showIcons = true,
  imageHeight = 350,
  blockNavPost = false,
}: Props) {
  const router = useRouter();
  const { user, post } = feed;
  const isMine = auth().currentUser?.uid === post.userId;

  const handlePress = () => {
    if (blockNavPost) return;
    router.push(`/(tabs)/feed/${post.postId}`);
  };

  const images = post.imageUrls ?? [];

  return (
    <Pressable onPress={handlePress} style={styles.card}>
      {/* Header — overlay on image or separate */}
      {showTopWriter && overlayTopWriter && images.length > 0 ? (
        <View>
          <FeedImages
            imageUrls={images}
            category={post.category}
            value={post.value}
            showTags={showTags}
            height={imageHeight ?? undefined}
          />
          <Head
            profileImageUrl={user.profileImage}
            userName={user.userName}
            userId={user.userId}
            userTitle={user.title}
            createdAt={post.createdAt}
            fontColor="#fff"
            isMine={isMine}
            overlay
          />
        </View>
      ) : (
        <>
          {showTopWriter && (
            <Head
              profileImageUrl={user.profileImage}
              userName={user.userName}
              userId={user.userId}
              userTitle={user.title}
              createdAt={post.createdAt}
              fontColor={fontColor}
              isMine={isMine}
            />
          )}
          {images.length > 0 && (
            <FeedImages
              imageUrls={images}
              category={post.category}
              value={post.value}
              showTags={showTags}
              height={imageHeight ?? undefined}
            />
          )}
        </>
      )}

      {/* Stat icons */}
      {showIcons && (
        <StatIcons
          postId={post.postId}
          postOwnerId={post.userId}
          likesCount={feed.numLikes}
          commentsCount={feed.numComments}
          fontColor={fontColor}
        />
      )}

      {/* Content */}
      {showContent && <Content content={post.content} fontColor={fontColor} />}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: colors.bgLight,
  },
});
