import { Product } from '../domain/product';
import { ProductRepository } from '../ports/productRepository';
import { sortByTopRated } from './ranking';

// The home page: the products we chose (ids from config), in the order we chose them.
export class FeaturedService {
  private readonly repository: ProductRepository;
  private readonly featuredIds: number[];

  constructor(repository: ProductRepository, featuredIds: number[]) {
    this.repository = repository;
    this.featuredIds = featuredIds;
  }

  async getFeatured(): Promise<Product[]> {
    const allProducts = await this.repository.getAll();

    const featured: Product[] = [];
    for (const id of this.featuredIds) {
      const product = allProducts.find((candidate) => candidate.id === id);
      if (product && !featured.includes(product)) {
        featured.push(product);
      }
    }

    // A chosen id may not exist any more. Fill the gaps with the highest rated products.
    for (const product of sortByTopRated(allProducts)) {
      if (featured.length >= this.featuredIds.length) {
        break;
      }
      if (!featured.includes(product)) {
        featured.push(product);
      }
    }

    return featured;
  }
}
