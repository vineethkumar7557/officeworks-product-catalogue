import { describe, expect, it } from 'vitest';
import { FeaturedService } from '../../src/services/featuredService';
import { InMemoryProductRepository } from '../helpers/inMemoryProductRepository';
import { makeProduct } from '../helpers/makeProduct';

const products = [
  makeProduct({ id: 1, rating: 4.0 }),
  makeProduct({ id: 2, rating: 4.9 }),
  makeProduct({ id: 3, rating: 3.0 }),
  makeProduct({ id: 4, rating: 4.5 }),
  makeProduct({ id: 5, rating: 4.8 }),
];

function ids(result: { id: number }[]): number[] {
  return result.map((product) => product.id);
}

describe('FeaturedService', () => {
  it('returns the chosen products in the chosen order', async () => {
    const service = new FeaturedService(new InMemoryProductRepository(products), [3, 1, 5]);

    expect(ids(await service.getFeatured())).toEqual([3, 1, 5]);
  });

  it('fills a missing product with the highest rated one not already shown', async () => {
    const service = new FeaturedService(new InMemoryProductRepository(products), [3, 99, 1]);

    expect(ids(await service.getFeatured())).toEqual([3, 1, 2]);
  });

  it('shows a product only once even if the config lists it twice', async () => {
    const service = new FeaturedService(new InMemoryProductRepository(products), [3, 3, 1]);

    expect(ids(await service.getFeatured())).toEqual([3, 1, 2]);
  });

  it('returns fewer products when there are not enough in total', async () => {
    const twoProducts = products.slice(0, 2);
    const service = new FeaturedService(new InMemoryProductRepository(twoProducts), [1, 2, 3, 4, 5]);

    expect(ids(await service.getFeatured())).toEqual([1, 2]);
  });
});
