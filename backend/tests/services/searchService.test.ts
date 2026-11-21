import { describe, expect, it } from 'vitest';
import { SearchService } from '../../src/services/searchService';
import { InMemoryProductRepository } from '../helpers/inMemoryProductRepository';
import { makeProduct } from '../helpers/makeProduct';

const products = [
  makeProduct({
    id: 1,
    title: 'Mens Cotton Jacket',
    description: 'Great for spring',
    category: "men's clothing",
    rating: 4.7,
  }),
  makeProduct({
    id: 2,
    title: 'Women Rain Jacket',
    description: 'Keeps you dry',
    category: "women's clothing",
    rating: 3.8,
  }),
  makeProduct({
    id: 3,
    title: 'Solid state drive',
    description: 'Fast storage for your laptop',
    category: 'electronics',
    rating: 4.8,
  }),
  makeProduct({
    id: 4,
    title: 'Gold bracelet',
    description: 'Shiny',
    category: 'jewelery',
    rating: 4.6,
  }),
];

function ids(result: { id: number }[]): number[] {
  return result.map((product) => product.id);
}

describe('SearchService', () => {
  const service = new SearchService(new InMemoryProductRepository(products));

  it('ignores upper and lower case, and lists the best rated first', async () => {
    expect(ids(await service.search('JACKET'))).toEqual([1, 2]);
  });

  it('looks in the description', async () => {
    expect(ids(await service.search('laptop'))).toEqual([3]);
  });

  it('looks in the category', async () => {
    expect(ids(await service.search('jewelery'))).toEqual([4]);
  });

  it('finds a word from its first letters', async () => {
    expect(ids(await service.search('jack'))).toEqual([1, 2]);
  });

  it('does not find "women" when searching for "men"', async () => {
    expect(ids(await service.search('men'))).toEqual([1]);
  });

  it('copes with an apostrophe in the search', async () => {
    expect(ids(await service.search("men's"))).toEqual([1]);
  });

  it('needs every typed word, in any order', async () => {
    expect(ids(await service.search('jacket cotton'))).toEqual([1]);
  });

  it('finds nothing for an empty or blank search', async () => {
    expect(await service.search('')).toEqual([]);
    expect(await service.search('   ')).toEqual([]);
  });

  it('finds nothing when no product matches', async () => {
    expect(await service.search('banana')).toEqual([]);
  });
});
