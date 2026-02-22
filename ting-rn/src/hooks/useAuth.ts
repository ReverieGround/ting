import { useEffect } from 'react';
import auth from '@react-native-firebase/auth';
import { useAuthStore } from '../stores/authStore';

/** Subscribe to Firebase auth state and trigger bootstrap */
export function useAuthListener() {
  const bootstrap = useAuthStore((s) => s.bootstrap);
  const setStatus = useAuthStore((s) => s.setStatus);

  useEffect(() => {
    const unsub = auth().onAuthStateChanged((user) => {
      if (user) {
        bootstrap();
      } else {
        setStatus('unauthenticated');
      }
    });
    return unsub;
  }, [bootstrap, setStatus]);
}
