import { readdirSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { describe, expect, it } from 'vitest';

const srcFolder = path.resolve(__dirname, '../src');

function listFiles(folder: string): string[] {
  return readdirSync(folder, { withFileTypes: true }).flatMap((entry) => {
    const fullPath = path.join(folder, entry.name);
    return entry.isDirectory() ? listFiles(fullPath) : [fullPath];
  });
}

function importsOf(file: string): string[] {
  const text = readFileSync(file, 'utf8');
  return [...text.matchAll(/from\s+['"]([^'"]+)['"]/g)].map((match) => match[1]);
}

// Files whose path (inside src) starts with the given folder name.
function filesIn(folderName: string): string[] {
  return listFiles(srcFolder).filter((file) => path.relative(srcFolder, file).startsWith(`${folderName}${path.sep}`));
}

function relative(file: string): string {
  return path.relative(srcFolder, file);
}

describe('architecture rules', () => {
  it('only composition.ts connects to the adapters', () => {
    const offenders = listFiles(srcFolder)
      .filter((file) => !relative(file).startsWith(`adapters${path.sep}`) && relative(file) !== 'composition.ts')
      .filter((file) => importsOf(file).some((name) => name.includes('/adapters/')))
      .map(relative);

    expect(offenders).toEqual([]);
  });

  it('services, domain and ports know nothing about the web framework', () => {
    const offenders = [...filesIn('services'), ...filesIn('domain'), ...filesIn('ports')]
      .filter((file) => importsOf(file).includes('express'))
      .map(relative);

    expect(offenders).toEqual([]);
  });

  it('only adapters talk to nodemailer', () => {
    const offenders = listFiles(srcFolder)
      .filter((file) => !relative(file).startsWith(`adapters${path.sep}`))
      .filter((file) => importsOf(file).includes('nodemailer'))
      .map(relative);

    expect(offenders).toEqual([]);
  });
});
