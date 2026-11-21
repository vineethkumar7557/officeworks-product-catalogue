import { Express } from 'express';
import { createApp } from '../../src/app';
import { Product } from '../../src/domain/product';
import { ProductRepository } from '../../src/ports/productRepository';
import { CategoryService } from '../../src/services/categoryService';
import { FeaturedService } from '../../src/services/featuredService';
import { ProductService } from '../../src/services/productService';
import { SearchService } from '../../src/services/searchService';
import { InMemoryProductRepository } from './inMemoryProductRepository';
import { makeProduct } from './makeProduct';

export const sampleProducts: Product[] = [
  makeProduct({ id: 1, title: 'Mens Cotton Jacket', category: "men's clothing", rating: 4.7 }),
  makeProduct({ id: 2, title: 'Mens Slim Shirt', category: "men's clothing", rating: 4.1 }),
  makeProduct({ id: 3, title: 'Mens Backpack', category: "men's clothing", rating: 3.9 }),
  makeProduct({ id: 4, title: 'Mens Casual Slim Fit', category: "men's clothing", rating: 2.1 }),
  makeProduct({ id: 5, title: 'Gold Bracelet', category: 'jewelery', rating: 4.6 }),
  makeProduct({ id: 6, title: 'Solid state drive', category: 'electronics', rating: 4.8 }),
];

export const testCorsOrigin = 'http://localhost:3000';

// Builds the real app with a fake data source, so API tests are fast and need no internet.
export function createTestApp(repository: ProductRepository = new InMemoryProductRepository(sampleProducts)): Express {
  return createApp({
    corsOrigin: testCorsOrigin,
    featuredService: new FeaturedService(repository, [6, 1, 5]),
    categoryService: new CategoryService(repository),
    searchService: new SearchService(repository),
    productService: new ProductService(repository),
  });
}
