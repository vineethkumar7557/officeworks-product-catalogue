import { Product } from '../../src/domain/product';
import { ProductRepository } from '../../src/ports/productRepository';

// A fake data source for service tests. It follows the same port as the real one,
// which shows the services do not care where products come from.
export class InMemoryProductRepository implements ProductRepository {
  private readonly products: Product[];

  constructor(products: Product[]) {
    this.products = products;
  }

  async getAll(): Promise<Product[]> {
    return [...this.products];
  }

  async getById(id: number): Promise<Product | null> {
    return this.products.find((product) => product.id === id) ?? null;
  }

  async getByCategory(category: string): Promise<Product[]> {
    return this.products.filter((product) => product.category === category);
  }

  async getCategories(): Promise<string[]> {
    return [...new Set(this.products.map((product) => product.category))];
  }
}
