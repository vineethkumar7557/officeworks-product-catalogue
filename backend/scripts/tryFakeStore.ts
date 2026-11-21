// A quick manual check against the REAL Fake Store API: npm run try:fakestore
import { FakeStoreProductRepository } from '../src/adapters/fakeStoreProductRepository';
import { loadConfig } from '../src/config/config';

async function main(): Promise<void> {
  const config = loadConfig();
  const repository = new FakeStoreProductRepository(config.fakeStore);

  const products = await repository.getAll();
  const categories = await repository.getCategories();

  console.log(`Loaded ${products.length} products`);
  console.log('Categories:', categories);
  console.log('First product:', products[0]);
}

main().catch((error: Error) => {
  console.error('Failed:', error.message);
  process.exit(1);
});
