import { useState, useEffect } from 'react';

/**
 * Generic hook that subscribes to a Firestore document ref
 * and returns { exists, data, loading }.
 * Replaces Flutter StreamBuilder for single-doc listeners.
 */
export function useFirestoreDoc<T = Record<string, unknown>>(
  ref: { onSnapshot: (...args: any[]) => () => void } | null,
  transform?: (data: Record<string, unknown>) => T,
) {
  const [state, setState] = useState<{
    data: T | null;
    exists: boolean;
    loading: boolean;
  }>({
    data: null,
    exists: false,
    loading: true,
  });

  useEffect(() => {
    if (!ref) {
      setState({ data: null, exists: false, loading: false });
      return;
    }

    const unsub = ref.onSnapshot(
      (snap: any) => {
        if (snap.exists()) {
          const raw = snap.data() as Record<string, unknown>;
          setState({
            data: transform ? transform(raw) : (raw as unknown as T),
            exists: true,
            loading: false,
          });
        } else {
          setState({ data: null, exists: false, loading: false });
        }
      },
      () => {
        setState({ data: null, exists: false, loading: false });
      },
    );

    return unsub;
  }, [ref]); // eslint-disable-line react-hooks/exhaustive-deps

  return state;
}

/**
 * Subscribe to a Firestore collection query and return docs.
 */
export function useFirestoreQuery<T>(
  query: { onSnapshot: (...args: any[]) => () => void } | null,
  transform: (data: Record<string, unknown>, id: string) => T,
) {
  const [state, setState] = useState<{
    data: T[];
    loading: boolean;
  }>({
    data: [],
    loading: true,
  });

  useEffect(() => {
    if (!query) {
      setState({ data: [], loading: false });
      return;
    }

    const unsub = query.onSnapshot(
      (snap: any) => {
        const items = snap.docs.map((d: any) =>
          transform(d.data() as Record<string, unknown>, d.id),
        );
        setState({ data: items, loading: false });
      },
      () => {
        setState({ data: [], loading: false });
      },
    );

    return unsub;
  }, [query]); // eslint-disable-line react-hooks/exhaustive-deps

  return state;
}
