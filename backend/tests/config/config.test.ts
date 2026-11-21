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

  it('reads the email, rate limit, CORS and Fake Store settings', () => {
    const config = loadConfig({
      SMTP_HOST: 'mail.test',
      SMTP_PORT: '2525',
      EMAIL_FROM: 'shop@test.example',
      ENQUIRY_RATE_LIMIT_MAX: '3',
      ENQUIRY_RATE_LIMIT_WINDOW_MINUTES: '1',
      CORS_ORIGIN: 'https://shop.test',
      FAKE_STORE_BASE_URL: 'https://store.test',
      FAKE_STORE_TIMEOUT_MS: '100',
    });

    expect(config.email).toEqual({
      smtpHost: 'mail.test',
      smtpPort: 2525,
      from: 'shop@test.example',
      salesInbox: 'sales@example.com',
    });
    expect(config.enquiryRateLimit).toEqual({ max: 3, windowMs: 60_000 });
    expect(config.corsOrigin).toBe('https://shop.test');
    expect(config.fakeStore.baseUrl).toBe('https://store.test');
    expect(config.fakeStore.timeoutMs).toBe(100);
  });
});
