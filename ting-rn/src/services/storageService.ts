import storage from '@react-native-firebase/storage';
import auth from '@react-native-firebase/auth';

function ext(path: string): string {
  const i = path.lastIndexOf('.');
  return i >= 0 && i < path.length - 1 ? path.substring(i + 1).toLowerCase() : 'jpg';
}

function contentType(e: string): string {
  switch (e) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'gif':
      return 'image/gif';
    default:
      return 'application/octet-stream';
  }
}

export const storageService = {
  async uploadPostImage(fileUri: string): Promise<string | null> {
    const uid = auth().currentUser?.uid;
    if (!uid) return null;

    try {
      const fileExt = ext(fileUri);
      const path = `posts/${uid}/${Date.now()}_${Math.random().toString(36).slice(2)}.${fileExt}`;
      const ref = storage().ref().child(path);

      await ref.putFile(fileUri, { contentType: contentType(fileExt) });
      return ref.getDownloadURL();
    } catch {
      return null;
    }
  },

  async uploadPostImages(fileUris: string[]): Promise<string[]> {
    const results = await Promise.all(
      fileUris.map((uri) => this.uploadPostImage(uri)),
    );
    return results.filter((u): u is string => u !== null);
  },

  async deleteByUrl(url: string): Promise<void> {
    try {
      await storage().refFromURL(url).delete();
    } catch {
      // ignore
    }
  },
};
