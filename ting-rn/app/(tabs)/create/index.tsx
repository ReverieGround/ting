import { View, Text, StyleSheet } from 'react-native';
import { colors } from '../../../src/theme/colors';

export default function CreatePostPage() {
  return (
    <View style={styles.container}>
      <Text style={styles.text}>포스트 작성</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.bgLight,
  },
  text: {
    color: colors.primary,
    fontSize: 18,
  },
});
