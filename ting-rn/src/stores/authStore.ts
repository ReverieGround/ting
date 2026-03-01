import { create } from 'zustand';
import auth, { FirebaseAuthTypes } from '@react-native-firebase/auth';
import firestore from '@react-native-firebase/firestore';
import { authService } from '../services/authService';

export type AppStatus =
  | 'initializing'
  | 'unauthenticated'
  | 'needsOnboarding'
  | 'authenticated';

interface AuthState {
  status: AppStatus;
  user: FirebaseAuthTypes.User | null;
  userId: string | null;

  bootstrap: () => Promise<void>;
  setStatus: (status: AppStatus) => void;
  signOut: () => Promise<void>;
}

export const useAuthStore = create<AuthState>((set, get) => ({
  status: 'initializing',
  user: null,
  userId: null,

  bootstrap: async () => {
    try {
      const user = auth().currentUser;
      if (!user) {
        set({ status: 'unauthenticated', user: null, userId: null });
        return;
      }

      set({ user, userId: user.uid });

      const doc = await firestore().collection('users').doc(user.uid).get();
      const data = doc.data();
      const needsOnboarding =
        !doc.exists() ||
        !data?.user_name ||
        !data?.country_code;

      set({
        status: needsOnboarding ? 'needsOnboarding' : 'authenticated',
      });
    } catch {
      set({ status: 'unauthenticated', user: null, userId: null });
    }
  },

  setStatus: (status) => set({ status }),

  signOut: async () => {
    await authService.signOut();
    set({ status: 'unauthenticated', user: null, userId: null });
  },
}));
