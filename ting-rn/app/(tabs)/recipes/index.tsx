import { View, Text, StyleSheet } from 'react-native';
import { colors } from '../../../src/theme/colors';

export default function RecipeListPage() {
  return (
    <View style={styles.container}>
      <Text style={styles.text}>레시피 목록</Text>
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
