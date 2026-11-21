import request from 'supertest';
import { describe, expect, it, vi } from 'vitest';
import { UpstreamError } from '../../src/domain/errors';
import { ProductRepository } from '../../src/ports/productRepository';
import { createTestApp, testCorsOrigin } from '../helpers/createTestApp';

const app = createTestApp();

// A data source that always fails in the way we tell it to.
function failingRepository(error: Error): ProductRepository {
  const fail = async (): Promise<never> => {
    throw error;
  };
  return { getAll: fail, getById: fail, getByCategory: fail, getCategories: fail };
}

describe('GET /health', () => {
  it('says ok', async () => {
    const response = await request(app).get('/health');

    expect(response.status).toBe(200);
    expect(response.body).toEqual({ status: 'ok' });
  });
});

describe('GET /featured', () => {
  it('returns the featured products in the chosen order', async () => {
    const response = await request(app).get('/featured');

    expect(response.status).toBe(200);
    expect(response.body.products.map((product: { id: number }) => product.id)).toEqual([6, 1, 5]);
  });
});

describe('GET /categories', () => {
  it('returns the category names', async () => {
    const response = await request(app).get('/categories');

    expect(response.status).toBe(200);
    expect(response.body).toEqual({ categories: ["men's clothing", 'jewelery', 'electronics'] });
  });
});

describe('GET /categories/:name/products', () => {
  it('returns the top rated products first, then the others', async () => {
    const response = await request(app).get(`/categories/${encodeURIComponent("men's clothing")}/products`);

    expect(response.status).toBe(200);
    expect(response.body.category).toBe("men's clothing");
    expect(response.body.topRated.map((product: { id: number }) => product.id)).toEqual([1, 2, 3]);
    expect(response.body.others.map((product: { id: number }) => product.id)).toEqual([4]);
  });

  it('answers 404 in the standard error format for an unknown category', async () => {
    const response = await request(app).get('/categories/toys/products');

    expect(response.status).toBe(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
    expect(response.body.error.message).toContain('toys');
  });
});

describe('GET /products?q=', () => {
  it('returns only the products that match the search', async () => {
    const response = await request(app).get('/products').query({ q: 'jacket' });

    expect(response.status).toBe(200);
    expect(response.body.query).toBe('jacket');
    expect(response.body.products.map((product: { id: number }) => product.id)).toEqual([1]);
  });

  it('returns an empty list when nothing matches', async () => {
    const response = await request(app).get('/products').query({ q: 'banana' });

    expect(response.status).toBe(200);
    expect(response.body.products).toEqual([]);
  });

  it('answers 400 when q is missing', async () => {
    const response = await request(app).get('/products');

    expect(response.status).toBe(400);
    expect(response.body.error.code).toBe('VALIDATION_ERROR');
    expect(response.body.error.details[0].field).toBe('q');
    expect(response.body.error.details[0].message).toContain('is required');
  });

  it('answers 400 when q is only spaces', async () => {
    const response = await request(app).get('/products').query({ q: '   ' });

    expect(response.status).toBe(400);
    expect(response.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('answers 400 when q is given twice', async () => {
    const response = await request(app).get('/products?q=a&q=b');

    expect(response.status).toBe(400);
  });
});

describe('GET /products/:id', () => {
  it('returns the product', async () => {
    const response = await request(app).get('/products/5');

    expect(response.status).toBe(200);
    expect(response.body.title).toBe('Gold Bracelet');
  });

  it('answers 404 for a product that does not exist', async () => {
    const response = await request(app).get('/products/999');

    expect(response.status).toBe(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });

  it.each(['abc', '0', '-1', '1.5', '1e3'])('answers 400 for the bad id "%s"', async (badId) => {
    const response = await request(app).get(`/products/${badId}`);

    expect(response.status).toBe(400);
    expect(response.body.error.code).toBe('VALIDATION_ERROR');
    expect(response.body.error.details[0].field).toBe('id');
  });
});

describe('errors and safety', () => {
  it('answers 404 in the standard format for an unknown route', async () => {
    const response = await request(app).get('/nothing-here');

    expect(response.status).toBe(404);
    expect(response.body.error.code).toBe('NOT_FOUND');
  });

  it('answers 502 when the product source fails', async () => {
    vi.spyOn(console, 'error').mockImplementation(() => {});
    const brokenApp = createTestApp({ repository: failingRepository(new UpstreamError('The product source is down.')) });

    const response = await request(brokenApp).get('/featured');

    expect(response.status).toBe(502);
    expect(response.body.error.code).toBe('UPSTREAM_ERROR');
    vi.restoreAllMocks();
  });

  it('answers 500 for an unexpected error without leaking its details', async () => {
    vi.spyOn(console, 'error').mockImplementation(() => {});
    const brokenApp = createTestApp({ repository: failingRepository(new Error('secret database password')) });

    const response = await request(brokenApp).get('/featured');

    expect(response.status).toBe(500);
    expect(response.body.error.code).toBe('INTERNAL_ERROR');
    expect(JSON.stringify(response.body)).not.toContain('secret');
    vi.restoreAllMocks();
  });

  it('sends security headers and hides that we use Express', async () => {
    const response = await request(app).get('/health');

    expect(response.headers['x-content-type-options']).toBe('nosniff');
    expect(response.headers['x-powered-by']).toBeUndefined();
  });

  it('allows the configured origin (CORS)', async () => {
    const response = await request(app).get('/health').set('Origin', testCorsOrigin);

    expect(response.headers['access-control-allow-origin']).toBe(testCorsOrigin);
  });
});

describe('input limits', () => {
  it('answers 400 for a category name that is too long', async () => {
    const response = await request(app).get(`/categories/${'a'.repeat(101)}/products`);

    expect(response.status).toBe(400);
    expect(response.body.error.details[0].field).toBe('name');
  });

  it('answers 400 for a search that is too long', async () => {
    const response = await request(app).get('/products').query({ q: 'a'.repeat(101) });

    expect(response.status).toBe(400);
    expect(response.body.error.details[0].field).toBe('q');
  });
});
