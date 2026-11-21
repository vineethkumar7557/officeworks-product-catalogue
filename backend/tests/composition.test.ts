import request from 'supertest';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { buildApp } from '../src/composition';
import { loadConfig } from '../src/config/config';
import { rawFakeStoreProducts } from './helpers/rawFakeStoreProducts';

// Checks that the settings really reach the parts they are meant for.
describe('buildApp (the wiring)', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  function pretendFakeStore() {
    const fetchMock = vi.fn(async (_url: string | URL | Request) => new Response(JSON.stringify(rawFakeStoreProducts)));
    vi.stubGlobal('fetch', fetchMock);
    return fetchMock;
  }

  it('starts and answers the health check', async () => {
    const response = await request(buildApp(loadConfig({}))).get('/health');

    expect(response.status).toBe(200);
  });

  it('uses the featured product ids from the settings', async () => {
    pretendFakeStore();
    const app = buildApp(loadConfig({ FEATURED_PRODUCT_IDS: '5,1' }));

    const response = await request(app).get('/featured');

    expect(response.body.products.map((product: { id: number }) => product.id)).toEqual([5, 1]);
  });

  it('uses the Fake Store address from the settings', async () => {
    const fetchMock = pretendFakeStore();
    const app = buildApp(loadConfig({ FAKE_STORE_BASE_URL: 'https://store.test' }));

    await request(app).get('/categories');

    expect(fetchMock.mock.calls[0][0]).toBe('https://store.test/products');
  });

  it('uses the enquiry rate limit from the settings', async () => {
    const app = buildApp(loadConfig({ ENQUIRY_RATE_LIMIT_MAX: '1' }));

    // Empty enquiries are refused (400) before any email is tried, but they still count towards the limit.
    const first = await request(app).post('/enquiries').send({});
    const second = await request(app).post('/enquiries').send({});

    expect([first.status, second.status]).toEqual([400, 429]);
  });

  it('uses the CORS origin from the settings', async () => {
    const app = buildApp(loadConfig({ CORS_ORIGIN: 'https://shop.test' }));

    const response = await request(app).get('/health').set('Origin', 'https://shop.test');

    expect(response.headers['access-control-allow-origin']).toBe('https://shop.test');
  });
});
