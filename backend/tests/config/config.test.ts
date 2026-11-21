import { describe, expect, it } from 'vitest';
import { loadConfig } from '../../src/config/config';

describe('loadConfig', () => {
  it('uses safe defaults when nothing is set', () => {
    const config = loadConfig({});

    expect(config.port).toBe(3000);
    expect(config.featuredProductIds).toEqual([12, 11, 3, 18, 5]);
    expect(config.fakeStore).toEqual({
      baseUrl: 'https://fakestoreapi.com',
      timeoutMs: 5000,
      cacheTtlMs: 300_000,
    });
    expect(config.enquiryRateLimit).toEqual({ max: 5, windowMs: 900_000 });
  });

  it('reads values from the environment', () => {
    const config = loadConfig({
      PORT: '4000',
      FEATURED_PRODUCT_IDS: '1, 2,3',
      CACHE_TTL_SECONDS: '10',
      SALES_INBOX_EMAIL: 'team@example.com',
    });

    expect(config.port).toBe(4000);
    expect(config.featuredProductIds).toEqual([1, 2, 3]);
    expect(config.fakeStore.cacheTtlMs).toBe(10_000);
    expect(config.email.salesInbox).toBe('team@example.com');
  });

  it('refuses a featured list that is not whole numbers', () => {
    expect(() => loadConfig({ FEATURED_PRODUCT_IDS: 'a,b' })).toThrow('FEATURED_PRODUCT_IDS');
    expect(() => loadConfig({ FEATURED_PRODUCT_IDS: '' })).toThrow('FEATURED_PRODUCT_IDS');
  });

  it('refuses a port that is not a number', () => {
    expect(() => loadConfig({ PORT: 'abc' })).toThrow('PORT');
  });

  it('refuses a sales inbox that is not an email address', () => {
    expect(() => loadConfig({ SALES_INBOX_EMAIL: 'nope' })).toThrow('SALES_INBOX_EMAIL');
  });
});
