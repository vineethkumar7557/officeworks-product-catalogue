import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      include: ['src/**/*.ts'],
      // Type-only files and the 3-line file that just starts the server
      exclude: ['src/server.ts', 'src/ports/**', 'src/domain/product.ts', 'src/domain/enquiry.ts'],
      reporter: ['text'],
      thresholds: { statements: 95, branches: 90, functions: 95, lines: 95 },
    },
  },
});
