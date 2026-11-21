import { describe, expect, it } from 'vitest';
import { NotFoundError } from '../../src/domain/errors';
import { CategoryService } from '../../src/services/categoryService';
import { InMemoryProductRepository } from '../helpers/inMemoryProductRepository';
import { makeProduct } from '../helpers/makeProduct';

const products = [
  makeProduct({ id: 1, category: "men's clothing", rating: 4.0 }),
  makeProduct({ id: 2, category: "men's clothing", rating: 4.8, ratingCount: 10 }),
  makeProduct({ id: 3, category: "men's clothing", rating: 4.8, ratingCount: 50 }),
  makeProduct({ id: 4, category: "men's clothing", rating: 3.0 }),
  makeProduct({ id: 5, category: "men's clothing", rating: 4.5 }),
  makeProduct({ id: 6, category: 'jewelery', rating: 4.9 }),
];

function ids(result: { id: number }[]): number[] {
  return result.map((product) => product.id);
}

describe('CategoryService', () => {
  const service = new CategoryService(new InMemoryProductRepository(products));

  it('lists the categories', async () => {
    expect(await service.getCategories()).toEqual(["men's clothing", 'jewelery']);
  });

  it('puts the top 3 first, using the number of ratings to break a tie', async () => {
    const result = await service.getCategoryProducts("men's clothing");

    expect(result.category).toBe("men's clothing");
    expect(ids(result.topRated)).toEqual([3, 2, 5]);
  });

  it('lists the remaining products after the top 3, best first', async () => {
    const result = await service.getCategoryProducts("men's clothing");

    expect(ids(result.others)).toEqual([1, 4]);
  });

  it('has no other products when the category has 3 or fewer', async () => {
    const result = await service.getCategoryProducts('jewelery');

    expect(ids(result.topRated)).toEqual([6]);
    expect(result.others).toEqual([]);
  });

  it('gives a NotFoundError for a category that does not exist', async () => {
    await expect(service.getCategoryProducts('toys')).rejects.toThrow(NotFoundError);
  });
});
