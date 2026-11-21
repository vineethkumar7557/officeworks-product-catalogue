// Our own product shape. The app only ever sees this, never the Fake Store format.
export interface Product {
  id: number;
  title: string;
  description: string;
  price: number;
  category: string;
  imageUrl: string;
  rating: number;
  ratingCount: number;
}
