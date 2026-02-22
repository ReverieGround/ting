import { Tabs } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { StyleSheet, Platform } from 'react-native';
import { colors } from '../../src/theme/colors';

type TabIconName = 'chatbubbles' | 'book' | 'create' | 'person';
type IoniconsName = React.ComponentProps<typeof Ionicons>['name'];

const TAB_CONFIG: {
  name: string;
  title: string;
  icon: TabIconName;
  label: string;
}[] = [
  { name: 'feed', title: '커뮤니티', icon: 'chatbubbles', label: '커뮤니티' },
  { name: 'recipes', title: '요리하기', icon: 'book', label: '요리하기' },
  { name: 'create', title: '기록', icon: 'create', label: '기록' },
  { name: 'profile', title: '프로필', icon: 'person', label: '프로필' },
];

export default function TabLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: colors.tabActive,
        tabBarInactiveTintColor: colors.tabInactive,
        tabBarStyle: styles.tabBar,
        tabBarLabelStyle: styles.tabBarLabel,
      }}
    >
      {TAB_CONFIG.map((tab) => (
        <Tabs.Screen
          key={tab.name}
          name={tab.name}
          options={{
            title: tab.label,
            tabBarIcon: ({ color, size }) => (
              <Ionicons
                name={`${tab.icon}-outline` as IoniconsName}
                size={size}
                color={color}
              />
            ),
          }}
        />
      ))}
      {/* Hide non-tab routes from tab bar */}
      <Tabs.Screen name="users" options={{ href: null }} />
    </Tabs>
  );
}

const styles = StyleSheet.create({
  tabBar: {
    backgroundColor: 'rgba(15,17,21,0.85)',
    borderTopColor: colors.divider,
    borderTopWidth: StyleSheet.hairlineWidth,
    position: 'absolute',
    elevation: 0,
    height: Platform.OS === 'ios' ? 88 : 60,
    paddingBottom: Platform.OS === 'ios' ? 28 : 8,
  },
  tabBarLabel: {
    fontSize: 10,
    fontWeight: '600',
  },
});
