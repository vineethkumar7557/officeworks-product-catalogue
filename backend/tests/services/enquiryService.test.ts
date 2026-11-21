import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { NotFoundError, UpstreamError } from '../../src/domain/errors';
import { EnquiryService } from '../../src/services/enquiryService';
import { ProductService } from '../../src/services/productService';
import { FakeEmailSender } from '../helpers/fakeEmailSender';
import { InMemoryProductRepository } from '../helpers/inMemoryProductRepository';
import { makeProduct } from '../helpers/makeProduct';

const productService = new ProductService(
  new InMemoryProductRepository([makeProduct({ id: 7, title: 'Gaming drive', price: 114 })]),
);

const enquiry = {
  name: 'Asha Rao',
  email: 'asha@example.com',
  phone: '+91 98765 43210',
  message: 'Is this in stock?',
  productId: 7,
};

describe('EnquiryService', () => {
  let logSpy: ReturnType<typeof vi.spyOn>;

  beforeEach(() => {
    logSpy = vi.spyOn(console, 'info').mockImplementation(() => {});
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('emails the sales inbox with the product and the customer details', async () => {
    const emailSender = new FakeEmailSender();
    const service = new EnquiryService(productService, emailSender, 'sales@test.example');

    await service.submit(enquiry);

    expect(emailSender.sent).toHaveLength(1);
    const email = emailSender.sent[0];
    expect(email.to).toBe('sales@test.example');
    expect(email.subject).toBe('New enquiry: Gaming drive');
    expect(email.text).toContain('Gaming drive (id 7');
    expect(email.text).toContain('Asha Rao');
    expect(email.text).toContain('asha@example.com');
    expect(email.text).toContain('+91 98765 43210');
    expect(email.text).toContain('Is this in stock?');
  });

  it('lets sales reply straight to the customer', async () => {
    const emailSender = new FakeEmailSender();
    const service = new EnquiryService(productService, emailSender, 'sales@test.example');

    await service.submit(enquiry);

    expect(emailSender.sent[0].replyTo).toBe('asha@example.com');
  });

  it('says "not given" when there is no phone number', async () => {
    const emailSender = new FakeEmailSender();
    const service = new EnquiryService(productService, emailSender, 'sales@test.example');

    await service.submit({ ...enquiry, phone: undefined });

    expect(emailSender.sent[0].text).toContain('Phone: not given');
  });

  it('gives a NotFoundError and sends no email for an unknown product', async () => {
    const emailSender = new FakeEmailSender();
    const service = new EnquiryService(productService, emailSender, 'sales@test.example');

    await expect(service.submit({ ...enquiry, productId: 999 })).rejects.toThrow(NotFoundError);
    expect(emailSender.sent).toHaveLength(0);
  });

  it('passes on the error when the email cannot be sent', async () => {
    const emailSender = new FakeEmailSender(new UpstreamError('mail server down'));
    const service = new EnquiryService(productService, emailSender, 'sales@test.example');

    await expect(service.submit(enquiry)).rejects.toThrow(UpstreamError);
  });

  it('logs that an enquiry happened without any personal details', async () => {
    const service = new EnquiryService(productService, new FakeEmailSender(), 'sales@test.example');

    await service.submit(enquiry);

    const logged = JSON.stringify(logSpy.mock.calls);
    expect(logged).toContain('product 7');
    expect(logged).not.toContain('Asha');
    expect(logged).not.toContain('asha@example.com');
    expect(logged).not.toContain('98765');
  });
});
