import { describe, expect, it } from 'vitest';
import { NotFoundError } from '../../src/domain/errors';
import { ProductService } from '../../src/services/productService';
import { InMemoryProductRepository } from '../helpers/inMemoryProductRepository';
import { makeProduct } from '../helpers/makeProduct';

describe('ProductService', () => {
  const service = new ProductService(
    new InMemoryProductRepository([makeProduct({ id: 7, title: 'Seven' })]),
  );

  it('returns the product with that id', async () => {
    expect((await service.getProduct(7)).title).toBe('Seven');
  });

  it('gives a NotFoundError when the product does not exist', async () => {
    await expect(service.getProduct(8)).rejects.toThrow(NotFoundError);
  });
});
