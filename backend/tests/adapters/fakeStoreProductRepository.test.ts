import { describe, expect, it, vi } from 'vitest';
import { FakeStoreProductRepository } from '../../src/adapters/fakeStoreProductRepository';
import { UpstreamError } from '../../src/domain/errors';
import { rawFakeStoreProducts } from '../helpers/rawFakeStoreProducts';

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status });
}

function createRepository(fetchFunction: typeof fetch, now: () => number = () => 0) {
  const options = { baseUrl: 'https://fake.test', timeoutMs: 1000, cacheTtlMs: 60_000 };
  return new FakeStoreProductRepository(options, fetchFunction, now);
}

function fetchReturningProducts() {
  return vi.fn(async (_url: string | URL | Request) => jsonResponse(rawFakeStoreProducts));
}

describe('FakeStoreProductRepository', () => {
  it('turns Fake Store products into our own Product shape', async () => {
    const repository = createRepository(fetchReturningProducts());

    const products = await repository.getAll();

    expect(products[0]).toEqual({
      id: 1,
      title: 'Backpack',
      description: 'Fits 15 inch laptops',
      price: 109.95,
      category: "men's clothing",
      imageUrl: 'https://example.com/1.jpg',
      rating: 3.9,
      ratingCount: 120,
    });
  });

  it('asks the /products address of the configured base url', async () => {
    const fetchMock = fetchReturningProducts();

    await createRepository(fetchMock).getAll();

    expect(fetchMock.mock.calls[0][0]).toBe('https://fake.test/products');
  });

  it('finds a product by id, or gives null when it does not exist', async () => {
    const repository = createRepository(fetchReturningProducts());

    expect((await repository.getById(5))?.title).toBe('Bracelet');
    expect(await repository.getById(999)).toBeNull();
  });

  it('returns only the products of one category', async () => {
    const repository = createRepository(fetchReturningProducts());

    const electronics = await repository.getByCategory('electronics');

    expect(electronics.map((product) => product.id)).toEqual([11, 12]);
    expect(await repository.getByCategory('toys')).toEqual([]);
  });

  it('lists each category once, keeping names exactly as given', async () => {
    const repository = createRepository(fetchReturningProducts());

    expect(await repository.getCategories()).toEqual(["men's clothing", 'jewelery', 'electronics']);
  });

  it('asks Fake Store only once while the cache is fresh', async () => {
    const fetchMock = fetchReturningProducts();
    const repository = createRepository(fetchMock);

    await repository.getAll();
    await repository.getById(1);
    await repository.getCategories();

    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('asks Fake Store again after the cache has expired', async () => {
    const fetchMock = fetchReturningProducts();
    let currentTime = 0;
    const repository = createRepository(fetchMock, () => currentTime);

    await repository.getAll();
    currentTime = 60_001;
    await repository.getAll();

    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it('does not let a caller change the cached list', async () => {
    const repository = createRepository(fetchReturningProducts());

    const first = await repository.getAll();
    first.pop();

    expect(await repository.getAll()).toHaveLength(4);
  });

  it('gives an UpstreamError when Fake Store answers with an error status', async () => {
    const repository = createRepository(vi.fn(async () => jsonResponse({}, 500)));

    await expect(repository.getAll()).rejects.toThrow(UpstreamError);
  });

  it('gives an UpstreamError when the network fails', async () => {
    const repository = createRepository(vi.fn(async () => Promise.reject(new TypeError('network down'))));

    await expect(repository.getAll()).rejects.toThrow('could not be reached');
  });

  it('gives an UpstreamError when the answer is not valid JSON', async () => {
    const repository = createRepository(vi.fn(async () => new Response('<html>oops</html>')));

    await expect(repository.getAll()).rejects.toThrow('valid JSON');
  });

  it('gives an UpstreamError when the data has an unexpected format', async () => {
    const repository = createRepository(vi.fn(async () => jsonResponse([{ id: 'not-a-number' }])));

    await expect(repository.getAll()).rejects.toThrow('unexpected format');
  });

  it('gives an UpstreamError when Fake Store is too slow', async () => {
    // This fake never answers, it only waits until the timeout cancels it.
    const hangingFetch = ((_url: string, init?: RequestInit) =>
      new Promise((_resolve, reject) => {
        init?.signal?.addEventListener('abort', () => reject(init.signal?.reason));
      })) as unknown as typeof fetch;
    const options = { baseUrl: 'https://fake.test', timeoutMs: 20, cacheTtlMs: 60_000 };
    const repository = new FakeStoreProductRepository(options, hangingFetch);

    await expect(repository.getAll()).rejects.toThrow('took too long');
  });
});
