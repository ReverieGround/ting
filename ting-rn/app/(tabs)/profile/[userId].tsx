import { View, Text, StyleSheet } from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import { colors } from '../../../src/theme/colors';

export default function UserProfilePage() {
  const { userId } = useLocalSearchParams<{ userId: string }>();

  return (
    <View style={styles.container}>
      <Text style={styles.text}>유저 프로필: {userId}</Text>
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
