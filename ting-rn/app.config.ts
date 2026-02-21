import { ExpoConfig, ConfigContext } from 'expo/config';

export default ({ config }: ConfigContext): ExpoConfig => ({
  ...config,
  name: 'T!ng',
  slug: 'ting-rn',
  version: '1.0.0',
  orientation: 'portrait',
  icon: './assets/icon.png',
  userInterfaceStyle: 'dark',
  newArchEnabled: true,
  scheme: 'ting',

  splash: {
    image: './assets/splash-icon.png',
    resizeMode: 'contain',
    backgroundColor: '#0F1115',
  },

  ios: {
    supportsTablet: false,
    bundleIdentifier: 'com.example.vibeyum',
    googleServicesFile: './GoogleService-Info.plist',
    infoPlist: {
      CFBundleURLTypes: [
        {
          CFBundleURLSchemes: [
            // Google Sign-In reversed client ID
            'com.googleusercontent.apps.1088275016090-ilhbipi5g51hg7aklkguhfe7gv7vb1af',
          ],
        },
      ],
    },
  },

  android: {
    adaptiveIcon: {
      foregroundImage: './assets/adaptive-icon.png',
      backgroundColor: '#0F1115',
    },
    package: 'com.example.vibeyum',
  },

  plugins: [
    'expo-router',
    '@react-native-firebase/app',
    '@react-native-firebase/auth',
    'expo-secure-store',
    [
      'expo-font',
      {
        fonts: [],
      },
    ],
    'expo-build-properties',
    './plugins/withModularHeaders',
  ],

  experiments: {
    typedRoutes: true,
  },

  extra: {
    eas: {
      projectId: 'a6e0ac13-6d69-488e-8521-a013f5017d02',
    },
  },
});
