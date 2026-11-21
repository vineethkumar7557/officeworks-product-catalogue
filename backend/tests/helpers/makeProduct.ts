import { Product } from '../../src/domain/product';

// Builds a test product. Only write the fields the test cares about.
export function makeProduct(overrides: Partial<Product> = {}): Product {
  return {
    id: 1,
    title: 'Test product',
    description: 'A test product',
    price: 10,
    category: 'electronics',
    imageUrl: 'https://example.com/product.jpg',
    rating: 4,
    ratingCount: 10,
    ...overrides,
  };
}
