/** Split an array into chunks (needed for Firestore whereIn 10-item limit) */
export function chunk<T>(list: T[], size: number): T[][] {
  if (list.length === 0) return [];
  const result: T[][] = [];
  for (let i = 0; i < list.length; i += size) {
    result.push(list.slice(i, i + size));
  }
  return result;
}
