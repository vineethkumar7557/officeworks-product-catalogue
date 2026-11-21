import { Express } from 'express';
import { createApp } from '../../src/app';
import { Product } from '../../src/domain/product';
import { EmailSender } from '../../src/ports/emailSender';
import { ProductRepository } from '../../src/ports/productRepository';
import { CategoryService } from '../../src/services/categoryService';
import { EnquiryService } from '../../src/services/enquiryService';
import { FeaturedService } from '../../src/services/featuredService';
import { ProductService } from '../../src/services/productService';
import { SearchService } from '../../src/services/searchService';
import { FakeEmailSender } from './fakeEmailSender';
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
export const testSalesInbox = 'sales@test.example';

interface TestAppOptions {
  repository?: ProductRepository;
  emailSender?: EmailSender;
  rateLimit?: { max: number; windowMs: number };
}

// Builds the real app with fake pieces, so API tests are fast and need no internet or mail server.
export function createTestApp(options: TestAppOptions = {}): Express {
  const repository = options.repository ?? new InMemoryProductRepository(sampleProducts);
  const emailSender = options.emailSender ?? new FakeEmailSender();
  const productService = new ProductService(repository);

  return createApp({
    corsOrigin: testCorsOrigin,
    featuredService: new FeaturedService(repository, [6, 1, 5]),
    categoryService: new CategoryService(repository),
    searchService: new SearchService(repository),
    productService,
    enquiryService: new EnquiryService(productService, emailSender, testSalesInbox),
    enquiryRateLimit: options.rateLimit ?? { max: 1000, windowMs: 60_000 },
  });
}
