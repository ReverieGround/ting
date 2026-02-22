import { StyleSheet, View } from 'react-native';
import { Image } from 'expo-image';
import { colors } from '../../theme/colors';

interface Props {
  profileUrl?: string | null;
  size?: number;
}

export function ProfileAvatar({ profileUrl, size = 40 }: Props) {
  const r = size / 2;

  return (
    <View style={[styles.container, { width: size, height: size, borderRadius: r }]}>
      <Image
        source={
          profileUrl
            ? { uri: profileUrl }
            : require('../../../assets/icon.png')
        }
        style={{ width: size, height: size, borderRadius: r }}
        contentFit="cover"
        transition={200}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    borderWidth: 0.5,
    borderColor: '#000000',
    backgroundColor: '#FFFFFF',
    overflow: 'hidden',
  },
});
