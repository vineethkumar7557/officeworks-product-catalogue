import { describe, expect, it } from 'vitest';
import { sortByTopRated } from '../../src/services/ranking';
import { makeProduct } from '../helpers/makeProduct';

describe('sortByTopRated', () => {
  it('puts the higher rating first', () => {
    const products = [makeProduct({ id: 1, rating: 3 }), makeProduct({ id: 2, rating: 5 })];

    expect(sortByTopRated(products).map((product) => product.id)).toEqual([2, 1]);
  });

  it('uses the number of ratings when ratings are equal', () => {
    const products = [
      makeProduct({ id: 1, rating: 4.8, ratingCount: 10 }),
      makeProduct({ id: 2, rating: 4.8, ratingCount: 50 }),
    ];

    expect(sortByTopRated(products).map((product) => product.id)).toEqual([2, 1]);
  });

  it('uses the lower id when everything else is equal', () => {
    const products = [makeProduct({ id: 7 }), makeProduct({ id: 3 })];

    expect(sortByTopRated(products).map((product) => product.id)).toEqual([3, 7]);
  });

  it('does not change the list it was given', () => {
    const products = [makeProduct({ id: 1, rating: 1 }), makeProduct({ id: 2, rating: 5 })];

    sortByTopRated(products);

    expect(products.map((product) => product.id)).toEqual([1, 2]);
  });
});
