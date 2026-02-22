/** Format numbers: 1000+ → "1k", 1000000+ → "1m" */
export function formatNumber(n: number): string {
  if (n >= 1_000_000) {
    const v = n / 1_000_000;
    return v % 1 === 0 ? `${v}m` : `${v.toFixed(1)}m`;
  }
  if (n >= 1_000) {
    const v = n / 1_000;
    return v % 1 === 0 ? `${v}k` : `${v.toFixed(1)}k`;
  }
  return String(n);
}
