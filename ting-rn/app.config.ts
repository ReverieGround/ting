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
    bundleIdentifier: 'com.reverieground.ting',
    googleServicesFile: './GoogleService-Info.plist',
    infoPlist: {
      CFBundleURLTypes: [
        {
          CFBundleURLSchemes: [
            // Google Sign-In reversed client ID
            'com.googleusercontent.apps.1088275016090-re9fu4ssqd2iti97kfmqjgti3k0hm2qm',
          ],
        },
      ],
      NSSpeechRecognitionUsageDescription:
        '음성으로 레시피를 수정하기 위해 음성 인식 권한이 필요합니다.',
      NSMicrophoneUsageDescription:
        '음성 입력을 위해 마이크 권한이 필요합니다.',
    },
  },

  android: {
    adaptiveIcon: {
      foregroundImage: './assets/adaptive-icon.png',
      backgroundColor: '#0F1115',
    },
    package: 'com.reverieground.ting',
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
    '@react-native-google-signin/google-signin',
    'expo-build-properties',
    'expo-image-picker',
    '@react-native-community/datetimepicker',
    './plugins/withFirebaseFixes',
    'expo-speech-recognition',
  ],

  experiments: {
    typedRoutes: true,
  },

  extra: {
    openaiApiKey: process.env.EXPO_PUBLIC_OPENAI_API_KEY,
    eas: {
      projectId: 'a6e0ac13-6d69-488e-8521-a013f5017d02',
    },
  },
});
