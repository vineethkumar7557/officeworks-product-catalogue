import { FakeStoreProductRepository } from './adapters/fakeStoreProductRepository';
import { SmtpEmailSender } from './adapters/smtpEmailSender';
import { createApp } from './app';
import { loadConfig } from './config/config';
import { CategoryService } from './services/categoryService';
import { EnquiryService } from './services/enquiryService';
import { FeaturedService } from './services/featuredService';
import { ProductService } from './services/productService';
import { SearchService } from './services/searchService';

// The only place that picks real adapters and plugs them into the services.
function main(): void {
  const config = loadConfig();
  const productRepository = new FakeStoreProductRepository(config.fakeStore);
  const emailSender = new SmtpEmailSender({
    host: config.email.smtpHost,
    port: config.email.smtpPort,
    from: config.email.from,
  });
  const productService = new ProductService(productRepository);

  const app = createApp({
    corsOrigin: config.corsOrigin,
    featuredService: new FeaturedService(productRepository, config.featuredProductIds),
    categoryService: new CategoryService(productRepository),
    searchService: new SearchService(productRepository),
    productService,
    enquiryService: new EnquiryService(productService, emailSender, config.email.salesInbox),
    enquiryRateLimit: config.enquiryRateLimit,
  });

  app.listen(config.port, () => {
    console.log(`Catalogue API listening on http://localhost:${config.port}`);
  });
}

try {
  main();
} catch (error) {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
}
