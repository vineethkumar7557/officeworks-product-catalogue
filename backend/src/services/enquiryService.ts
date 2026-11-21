import { Enquiry } from '../domain/enquiry';
import { Product } from '../domain/product';
import { EmailSender } from '../ports/emailSender';
import { ProductService } from './productService';

function buildEmailText(product: Product, enquiry: Enquiry): string {
  return [
    `Product: ${product.title} (id ${product.id}, price ${product.price})`,
    '',
    `Name: ${enquiry.name}`,
    `Email: ${enquiry.email}`,
    `Phone: ${enquiry.phone ?? 'not given'}`,
    '',
    'Message:',
    enquiry.message,
  ].join('\n');
}

// Sends a customer's enquiry to the sales inbox.
export class EnquiryService {
  private readonly productService: ProductService;
  private readonly emailSender: EmailSender;
  private readonly salesInbox: string;

  constructor(productService: ProductService, emailSender: EmailSender, salesInbox: string) {
    this.productService = productService;
    this.emailSender = emailSender;
    this.salesInbox = salesInbox;
  }

  async submit(enquiry: Enquiry): Promise<void> {
    // Throws NotFoundError if the product does not exist, so we never email about a ghost product.
    const product = await this.productService.getProduct(enquiry.productId);

    await this.emailSender.send({
      to: this.salesInbox,
      replyTo: enquiry.email,
      subject: `New enquiry: ${product.title}`,
      text: buildEmailText(product, enquiry),
    });

    // The log says an enquiry happened, but never contains the customer's personal details.
    console.info(`Enquiry emailed to sales for product ${product.id}`);
  }
}
