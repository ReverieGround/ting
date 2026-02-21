import { View, Text, StyleSheet } from 'react-native';
import { colors } from '../../../src/theme/colors';

export default function ConfirmPostPage() {
  return (
    <View style={styles.container}>
      <Text style={styles.text}>업로드 확인</Text>
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
