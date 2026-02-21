const HANGUL_BASE = 0xac00;
const HANGUL_END = 0xd7a3;

/**
 * Attach the correct Korean object particle ('을' or '를')
 * based on whether the final character has a jongseong (종성).
 */
export function attachObjectParticle(word: string): string {
  if (word.length === 0) return word;

  const code = word.charCodeAt(word.length - 1);

  if (code < HANGUL_BASE || code > HANGUL_END) {
    return `${word}를`;
  }

  const hasJong = (code - HANGUL_BASE) % 28 !== 0;
  return `${word}${hasJong ? '을' : '를'}`;
}
