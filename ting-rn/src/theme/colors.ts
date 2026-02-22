/**
 * T!ng color palette — ported from Flutter AppTheme.dart
 */

export const colors = {
  // Backgrounds
  bgLight: '#0F1115',
  bgDark: '#0B0D10',

  // Primary / text
  primary: '#EAECEF',
  fontLight: '#EAECEF',
  fontDark: '#EAECEF',

  // Semantic
  onPrimary: '#000000',
  white: '#FFFFFF',
  black: '#000000',

  // Opacity helpers (use with rgba)
  hintOpacity: 0.6,
  borderOpacity: 0.15,
  dividerOpacity: 0.12,

  // Derived
  get hint() {
    return `rgba(234,236,239,${this.hintOpacity})`;
  },
  get border() {
    return `rgba(234,236,239,${this.borderOpacity})`;
  },
  get divider() {
    return `rgba(234,236,239,${this.dividerOpacity})`;
  },

  // Surface overlay (for semi-transparent nav bar)
  get surfaceOverlay() {
    return 'rgba(15,17,21,0.5)';
  },

  // Tab bar
  tabActive: '#EAECEF',
  tabInactive: 'rgba(255,255,255,0.78)',
} as const;

export const spacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
} as const;

export const radius = {
  sm: 8,
  md: 14,
  lg: 20,
  full: 9999,
} as const;
