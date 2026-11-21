import { z } from 'zod';
import { Product } from '../domain/product';

// What Fake Store sends us. We check it, so a surprise in their data cannot crash us later.
const fakeStoreProductSchema = z.object({
  id: z.number(),
  title: z.string(),
  price: z.number(),
  description: z.string(),
  category: z.string(),
  image: z.string(),
  rating: z.object({ rate: z.number(), count: z.number() }),
});

export const fakeStoreProductListSchema = z.array(fakeStoreProductSchema);

type FakeStoreProduct = z.infer<typeof fakeStoreProductSchema>;

// Converts their shape into our own clean Product shape.
export function toProduct(raw: FakeStoreProduct): Product {
  return {
    id: raw.id,
    title: raw.title,
    description: raw.description,
    price: raw.price,
    category: raw.category,
    imageUrl: raw.image,
    rating: raw.rating.rate,
    ratingCount: raw.rating.count,
  };
}
