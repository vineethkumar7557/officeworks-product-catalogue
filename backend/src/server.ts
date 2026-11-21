import { FakeStoreProductRepository } from './adapters/fakeStoreProductRepository';
import { createApp } from './app';
import { loadConfig } from './config/config';
import { CategoryService } from './services/categoryService';
import { FeaturedService } from './services/featuredService';
import { ProductService } from './services/productService';
import { SearchService } from './services/searchService';

// The only place that picks real adapters and plugs them into the services.
function main(): void {
  const config = loadConfig();
  const productRepository = new FakeStoreProductRepository(config.fakeStore);

  const app = createApp({
    corsOrigin: config.corsOrigin,
    featuredService: new FeaturedService(productRepository, config.featuredProductIds),
    categoryService: new CategoryService(productRepository),
    searchService: new SearchService(productRepository),
    productService: new ProductService(productRepository),
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
