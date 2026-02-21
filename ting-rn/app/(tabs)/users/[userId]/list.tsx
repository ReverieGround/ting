import { View, Text, StyleSheet } from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import { colors } from '../../../../src/theme/colors';

export default function UserListPage() {
  const { userId } = useLocalSearchParams<{ userId: string }>();

  return (
    <View style={styles.container}>
      <Text style={styles.text}>팔로워/팔로잉 목록: {userId}</Text>
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
