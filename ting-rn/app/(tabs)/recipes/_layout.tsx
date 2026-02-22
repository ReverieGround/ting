import { Stack } from 'expo-router';
import { colors } from '../../../src/theme/colors';

export default function RecipesLayout() {
  return (
    <Stack
      screenOptions={{
        headerShown: false,
        contentStyle: { backgroundColor: colors.bgLight },
      }}
    />
  );
}
