// What a customer sends us about a product.
export interface Enquiry {
  name: string;
  email: string;
  phone?: string;
  message: string;
  productId: number;
}
