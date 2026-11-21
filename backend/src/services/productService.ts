import { NotFoundError } from '../domain/errors';
import { Product } from '../domain/product';
import { ProductRepository } from '../ports/productRepository';

export class ProductService {
  private readonly repository: ProductRepository;

  constructor(repository: ProductRepository) {
    this.repository = repository;
  }

  async getProduct(id: number): Promise<Product> {
    const product = await this.repository.getById(id);
    if (!product) {
      throw new NotFoundError(`Product ${id} was not found.`);
    }
    return product;
  }
}
