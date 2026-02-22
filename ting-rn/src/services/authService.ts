import auth from '@react-native-firebase/auth';
import firestore from '@react-native-firebase/firestore';
import * as SecureStore from 'expo-secure-store';
import { GoogleSignin } from '@react-native-google-signin/google-signin';

const TOKEN_KEY = 'auth_token';
const HAS_LOGGED_IN_KEY = 'has_logged_in_before';

export const authService = {
  get currentUser() {
    return auth().currentUser;
  },

  get currentUserId() {
    return auth().currentUser?.uid ?? null;
  },

  onAuthStateChanged(cb: (user: ReturnType<typeof auth>['currentUser']) => void) {
    return auth().onAuthStateChanged(cb);
  },

  async getIdToken(forceRefresh = false): Promise<string | null> {
    const u = auth().currentUser;
    if (!u) return null;
    return u.getIdToken(forceRefresh);
  },

  async saveIdToken(): Promise<void> {
    const token = await this.getIdToken(true);
    if (token) {
      await SecureStore.setItemAsync(TOKEN_KEY, token);
    }
  },

  async verifyStoredIdToken(): Promise<boolean> {
    const stored = await SecureStore.getItemAsync(TOKEN_KEY);
    if (!stored || !auth().currentUser) return false;
    try {
      const now = await this.getIdToken();
      return stored === now;
    } catch {
      return false;
    }
  },

  async registerUser(params: {
    userName: string;
    countryCode: string;
    countryName: string;
    profileImageUrl?: string;
    bio?: string;
  }): Promise<void> {
    const uid = this.currentUserId;
    if (!uid) return;

    const ref = firestore().collection('users').doc(uid);
    const snap = await ref.get();
    if (snap.exists()) return;

    const providerData = auth().currentUser?.providerData;
    const providerId =
      providerData && providerData.length > 0
        ? providerData[0].providerId
        : 'password';

    await ref.set({
      user_id: uid,
      email: auth().currentUser?.email ?? '',
      user_name: params.userName,
      profile_image: params.profileImageUrl ?? '',
      bio: params.bio ?? '',
      country_code: params.countryCode,
      country_name: params.countryName,
      provider: providerId,
      created_at: firestore.FieldValue.serverTimestamp(),
    });
  },

  async signOut(): Promise<void> {
    try {
      await GoogleSignin.signOut();
    } catch {
      // ignore if Google sign-out fails
    }
    await auth().signOut();
    await SecureStore.deleteItemAsync(TOKEN_KEY);
  },

  // --- Social providers (stubs — wire up in Phase 1) ---

  async signInWithGoogle(): Promise<boolean> {
    try {
      GoogleSignin.configure({
        webClientId:
          '1088275016090-h5uuerbcan6kmskqe0rudflke5c5a95h.apps.googleusercontent.com',
        iosClientId:
          '1088275016090-re9fu4ssqd2iti97kfmqjgti3k0hm2qm.apps.googleusercontent.com',
      });
      await GoogleSignin.hasPlayServices();
      const response = await GoogleSignin.signIn();
      const idToken = response.data?.idToken;
      if (!idToken) return false;

      const credential = auth.GoogleAuthProvider.credential(idToken);
      await auth().signInWithCredential(credential);
      await this.saveIdToken();
      await this.markHasLoggedInBefore();
      return true;
    } catch (e) {
      console.error('Google sign-in error:', e);
      return false;
    }
  },

  async signInWithFacebook(): Promise<boolean> {
    // TODO: implement with react-native-fbsdk-next
    return false;
  },

  async hasLoggedInBefore(): Promise<boolean> {
    return (await SecureStore.getItemAsync(HAS_LOGGED_IN_KEY)) === 'true';
  },

  async markHasLoggedInBefore(): Promise<void> {
    await SecureStore.setItemAsync(HAS_LOGGED_IN_KEY, 'true');
  },
};
