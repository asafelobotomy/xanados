// ESLint configuration for xanadOS JavaScript/TypeScript files
// Excludes archive and non-active directories

module.exports = {
  env: {
    browser: true,
    es2021: true,
    node: true
  },
  extends: [
    'eslint:recommended'
  ],
  parserOptions: {
    ecmaVersion: 12,
    sourceType: 'module'
  },
  ignorePatterns: [
    'archive/**/*',
    'build/work/**/*',
    'build/cache/**/*',
    'build/out/**/*',
    'results/temp/**/*',
    '**/*.backup',
    '**/*.bak',
    '**/*.old',
    '**/*.orig',
    '**/*~',
    '**/*.tmp',
    '**/*.temp',
    'node_modules/**/*'
  ],
  rules: {
    'indent': ['error', 2],
    'linebreak-style': ['error', 'unix'],
    'quotes': ['error', 'single'],
    'semi': ['error', 'always']
  }
};
