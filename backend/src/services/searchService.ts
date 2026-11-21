import { Product } from '../domain/product';
import { ProductRepository } from '../ports/productRepository';
import { sortByTopRated } from './ranking';

// Splits text into lowercase words: "Men's Cotton-Jacket" becomes ["men", "s", "cotton", "jacket"].
function toWords(text: string): string[] {
  return text
    .toLowerCase()
    .split(/[^\p{L}\p{N}]+/u)
    .filter((word) => word.length > 0);
}

// Every word the customer typed must be the START of a word in the product text.
// So "jack" finds "jacket", but "men" does not wrongly find "women".
function matchesAllWords(product: Product, searchWords: string[]): boolean {
  const productWords = toWords(`${product.title} ${product.description} ${product.category}`);
  return searchWords.every((searchWord) =>
    productWords.some((productWord) => productWord.startsWith(searchWord)),
  );
}

export class SearchService {
  private readonly repository: ProductRepository;

  constructor(repository: ProductRepository) {
    this.repository = repository;
  }

  async search(term: string): Promise<Product[]> {
    const searchWords = toWords(term);
    // An empty search must find nothing, not everything.
    if (searchWords.length === 0) {
      return [];
    }

    const products = await this.repository.getAll();
    const matches = products.filter((product) => matchesAllWords(product, searchWords));
    return sortByTopRated(matches);
  }
}
