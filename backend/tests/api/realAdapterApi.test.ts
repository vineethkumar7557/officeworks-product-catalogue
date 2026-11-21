import request from 'supertest';
import { describe, expect, it, vi } from 'vitest';
import { FakeStoreProductRepository } from '../../src/adapters/fakeStoreProductRepository';
import { createTestApp } from '../helpers/createTestApp';
import { rawFakeStoreProducts } from '../helpers/rawFakeStoreProducts';

// These tests use the REAL Fake Store adapter with a pretend internet, so the whole chain
// (route -> service -> adapter -> Fake Store format) is checked together.
function createApiWithPretendFakeStore() {
  const fetchMock = vi.fn(async (_url: string | URL | Request) => new Response(JSON.stringify(rawFakeStoreProducts)));
  const repository = new FakeStoreProductRepository(
    { baseUrl: 'https://fake.test', timeoutMs: 1000, cacheTtlMs: 60_000 },
    fetchMock,
  );
  return { app: createTestApp({ repository }), fetchMock };
}

const cleanProductKeys = ['category', 'description', 'id', 'imageUrl', 'price', 'rating', 'ratingCount', 'title'];

describe('API with the real Fake Store adapter', () => {
  it('never shows the Fake Store format to the app', async () => {
    const { app } = createApiWithPretendFakeStore();

    const single = await request(app).get('/products/1');
    const featured = await request(app).get('/featured');

    expect(Object.keys(single.body).sort()).toEqual(cleanProductKeys);
    expect(typeof single.body.rating).toBe('number');
    for (const product of featured.body.products) {
      expect(Object.keys(product).sort()).toEqual(cleanProductKeys);
    }
  });

  it('shows the chosen featured products, filling a missing one with the best rated', async () => {
    const { app } = createApiWithPretendFakeStore();

    const response = await request(app).get('/featured');

    // The test app features 6, 1 and 5. Product 6 does not exist in the pretend data.
    expect(response.body.products.map((product: { id: number }) => product.id)).toEqual([1, 5, 12]);
  });

  it('finds products by search through the whole chain', async () => {
    const { app } = createApiWithPretendFakeStore();

    const response = await request(app).get('/products').query({ q: 'bracelet' });

    expect(response.body.products.map((product: { id: number }) => product.id)).toEqual([5]);
  });

  it('builds a category page through the whole chain', async () => {
    const { app } = createApiWithPretendFakeStore();

    const response = await request(app).get(`/categories/${encodeURIComponent("men's clothing")}/products`);

    expect(response.body.topRated.map((product: { id: number }) => product.id)).toEqual([1]);
    expect(response.body.others).toEqual([]);
  });

  it('asks Fake Store only once for many requests', async () => {
    const { app, fetchMock } = createApiWithPretendFakeStore();

    await request(app).get('/featured');
    await request(app).get('/categories');
    await request(app).get('/products/5');
    await request(app).get('/products').query({ q: 'drive' });

    expect(fetchMock).toHaveBeenCalledTimes(1);
  });
});
