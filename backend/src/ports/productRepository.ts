import { Product } from '../domain/product';

// The port: what the services need from "a place that holds products".
// Fake Store, a database or anything else can sit behind it.
export interface ProductRepository {
  getAll(): Promise<Product[]>;
  getById(id: number): Promise<Product | null>;
  getByCategory(category: string): Promise<Product[]>;
  getCategories(): Promise<string[]>;
}
