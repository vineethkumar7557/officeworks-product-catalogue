import { Product } from '../domain/product';

// Best first. A higher rating wins. If equal, more ratings wins.
// If still equal, the lower id wins, so the order never jumps around between calls.
export function sortByTopRated(products: Product[]): Product[] {
  return [...products].sort(
    (a, b) => b.rating - a.rating || b.ratingCount - a.ratingCount || a.id - b.id,
  );
}
