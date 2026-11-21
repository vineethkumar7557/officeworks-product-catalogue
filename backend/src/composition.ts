import { Express } from 'express';
import { FakeStoreProductRepository } from './adapters/fakeStoreProductRepository';
import { SmtpEmailSender } from './adapters/smtpEmailSender';
import { createApp } from './app';
import { Config } from './config/config';
import { CategoryService } from './services/categoryService';
import { EnquiryService } from './services/enquiryService';
import { FeaturedService } from './services/featuredService';
import { ProductService } from './services/productService';
import { SearchService } from './services/searchService';

// The only place that picks real adapters and plugs them into the services.
export function buildApp(config: Config): Express {
  const productRepository = new FakeStoreProductRepository(config.fakeStore);
  const emailSender = new SmtpEmailSender({
    host: config.email.smtpHost,
    port: config.email.smtpPort,
    from: config.email.from,
  });
  const productService = new ProductService(productRepository);

  return createApp({
    corsOrigin: config.corsOrigin,
    featuredService: new FeaturedService(productRepository, config.featuredProductIds),
    categoryService: new CategoryService(productRepository),
    searchService: new SearchService(productRepository),
    productService,
    enquiryService: new EnquiryService(productService, emailSender, config.email.salesInbox),
    enquiryRateLimit: config.enquiryRateLimit,
  });
}
