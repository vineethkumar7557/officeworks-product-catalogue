import { Router } from 'express';
import { z } from 'zod';
import { CategoryService } from '../services/categoryService';
import { FeaturedService } from '../services/featuredService';
import { ProductService } from '../services/productService';
import { SearchService } from '../services/searchService';
import { validate } from './validate';

export interface CatalogueServices {
  featuredService: FeaturedService;
  categoryService: CategoryService;
  searchService: SearchService;
  productService: ProductService;
}

// A whole number from 1 up to 999,999,999, written with digits only.
const idSchema = z
  .string()
  .regex(/^[1-9]\d{0,8}$/, 'must be a positive whole number')
  .transform(Number);

const productParamsSchema = z.object({ id: idSchema });
const categoryParamsSchema = z.object({ name: z.string().min(1).max(100) });
const searchQuerySchema = z.object({
  q: z
    .string({ error: 'is required, for example ?q=jacket' })
    .trim()
    .min(1, 'is required, for example ?q=jacket')
    .max(100),
});

// Routes only check the input, call a service and send the answer. No shop rules live here.
export function createCatalogueRouter(services: CatalogueServices): Router {
  const router = Router();

  router.get('/featured', async (_req, res) => {
    const products = await services.featuredService.getFeatured();
    res.json({ products });
  });

  router.get('/categories', async (_req, res) => {
    const categories = await services.categoryService.getCategories();
    res.json({ categories });
  });

  router.get('/categories/:name/products', async (req, res) => {
    const { name } = validate(categoryParamsSchema, req.params);
    res.json(await services.categoryService.getCategoryProducts(name));
  });

  router.get('/products', async (req, res) => {
    const { q } = validate(searchQuerySchema, req.query);
    const products = await services.searchService.search(q);
    res.json({ query: q, products });
  });

  router.get('/products/:id', async (req, res) => {
    const { id } = validate(productParamsSchema, req.params);
    res.json(await services.productService.getProduct(id));
  });

  return router;
}
