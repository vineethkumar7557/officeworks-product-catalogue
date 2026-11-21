import { NotFoundError } from '../domain/errors';
import { Product } from '../domain/product';
import { ProductRepository } from '../ports/productRepository';
import { sortByTopRated } from './ranking';

const TOP_RATED_COUNT = 3;

export interface CategoryProducts {
  category: string;
  topRated: Product[];
  others: Product[];
}

export class CategoryService {
  private readonly repository: ProductRepository;

  constructor(repository: ProductRepository) {
    this.repository = repository;
  }

  async getCategories(): Promise<string[]> {
    return this.repository.getCategories();
  }

  // The category page: the top rated products first, then the rest (also best first).
  async getCategoryProducts(category: string): Promise<CategoryProducts> {
    const categories = await this.repository.getCategories();
    if (!categories.includes(category)) {
      throw new NotFoundError(`Category "${category}" was not found.`);
    }

    const products = await this.repository.getByCategory(category);
    const ranked = sortByTopRated(products);

    return {
      category,
      topRated: ranked.slice(0, TOP_RATED_COUNT),
      others: ranked.slice(TOP_RATED_COUNT),
    };
  }
}
