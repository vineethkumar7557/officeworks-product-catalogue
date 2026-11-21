import { UpstreamError } from '../domain/errors';
import { Product } from '../domain/product';
import { ProductRepository } from '../ports/productRepository';
import { fakeStoreProductListSchema, toProduct } from './fakeStoreMapper';

export interface FakeStoreOptions {
  baseUrl: string;
  timeoutMs: number;
  cacheTtlMs: number;
}

// Gets products from the Fake Store API. This is the ONLY file that knows about Fake Store.
// Fake Store has just 20 products, so we load the whole list once, keep it in memory for a while,
// and answer every other question from that list.
export class FakeStoreProductRepository implements ProductRepository {
  private readonly options: FakeStoreOptions;
  private readonly fetchFunction: typeof fetch;
  private readonly now: () => number;
  private cachedProducts: Product[] | null = null;
  private cacheExpiresAt = 0;

  // fetchFunction and now can be replaced in tests (no real internet, no real clock).
  constructor(
    options: FakeStoreOptions,
    fetchFunction: typeof fetch = fetch,
    now: () => number = Date.now,
  ) {
    this.options = options;
    this.fetchFunction = fetchFunction;
    this.now = now;
  }

  async getAll(): Promise<Product[]> {
    if (this.cachedProducts && this.now() < this.cacheExpiresAt) {
      return [...this.cachedProducts];
    }

    const products = await this.fetchProducts();
    this.cachedProducts = products;
    this.cacheExpiresAt = this.now() + this.options.cacheTtlMs;
    return [...products];
  }

  async getById(id: number): Promise<Product | null> {
    const products = await this.getAll();
    return products.find((product) => product.id === id) ?? null;
  }

  async getByCategory(category: string): Promise<Product[]> {
    const products = await this.getAll();
    return products.filter((product) => product.category === category);
  }

  async getCategories(): Promise<string[]> {
    const products = await this.getAll();
    return [...new Set(products.map((product) => product.category))];
  }

  private async fetchProducts(): Promise<Product[]> {
    const body = await this.fetchJson(`${this.options.baseUrl}/products`);

    const parsed = fakeStoreProductListSchema.safeParse(body);
    if (!parsed.success) {
      throw new UpstreamError('The product source sent data in an unexpected format.');
    }
    return parsed.data.map(toProduct);
  }

  private async fetchJson(url: string): Promise<unknown> {
    let response: Response;
    try {
      response = await this.fetchFunction(url, {
        signal: AbortSignal.timeout(this.options.timeoutMs),
        headers: { Accept: 'application/json' },
      });
    } catch (error) {
      const timedOut = error instanceof Error && error.name === 'TimeoutError';
      throw new UpstreamError(
        timedOut ? 'The product source took too long to answer.' : 'The product source could not be reached.',
      );
    }

    if (!response.ok) {
      throw new UpstreamError(`The product source answered with status ${response.status}.`);
    }

    try {
      return await response.json();
    } catch {
      throw new UpstreamError('The product source did not send valid JSON.');
    }
  }
}
