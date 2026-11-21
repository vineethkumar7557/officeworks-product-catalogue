import request from 'supertest';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { UpstreamError } from '../../src/domain/errors';
import { createTestApp, testSalesInbox } from '../helpers/createTestApp';
import { FakeEmailSender } from '../helpers/fakeEmailSender';

const validEnquiry = {
  name: 'Asha Rao',
  email: 'asha@example.com',
  phone: '+91 98765 43210',
  message: 'Is this in stock?',
  productId: 5,
};

beforeEach(() => {
  vi.spyOn(console, 'info').mockImplementation(() => {});
  vi.spyOn(console, 'error').mockImplementation(() => {});
});

afterEach(() => {
  vi.restoreAllMocks();
});

describe('POST /enquiries', () => {
  it('emails the sales inbox and answers with a thank you', async () => {
    const emailSender = new FakeEmailSender();
    const app = createTestApp({ emailSender });

    const response = await request(app).post('/enquiries').send(validEnquiry);

    expect(response.status).toBe(201);
    expect(response.body.message).toContain('Thank you');
    expect(emailSender.sent).toHaveLength(1);
    expect(emailSender.sent[0].to).toBe(testSalesInbox);
    expect(emailSender.sent[0].subject).toBe('New enquiry: Gold Bracelet');
  });

  it('accepts an enquiry without a phone number, or with an empty one', async () => {
    const emailSender = new FakeEmailSender();
    const app = createTestApp({ emailSender });
    const { phone: _unused, ...withoutPhone } = validEnquiry;

    const first = await request(app).post('/enquiries').send(withoutPhone);
    const second = await request(app).post('/enquiries').send({ ...validEnquiry, phone: '' });

    expect(first.status).toBe(201);
    expect(second.status).toBe(201);
    expect(emailSender.sent[1].text).toContain('Phone: not given');
  });

  it('trims spaces around the text fields', async () => {
    const emailSender = new FakeEmailSender();
    const app = createTestApp({ emailSender });

    await request(app)
      .post('/enquiries')
      .send({ ...validEnquiry, name: '  Asha Rao  ', email: '  asha@example.com ' });

    expect(emailSender.sent[0].replyTo).toBe('asha@example.com');
    expect(emailSender.sent[0].text).toContain('Name: Asha Rao\n');
  });

  it.each([
    ['name', { name: '   ' }],
    ['name', { name: undefined }],
    ['email', { email: 'not-an-email' }],
    ['email', { email: undefined }],
    ['phone', { phone: 'call me maybe' }],
    ['message', { message: '' }],
    ['message', { message: 'x'.repeat(2001) }],
    ['productId', { productId: '5' }],
    ['productId', { productId: 0 }],
    ['productId', { productId: 1.5 }],
    ['productId', { productId: undefined }],
  ])('answers 400 and names the field "%s" when it is invalid', async (field, change) => {
    const emailSender = new FakeEmailSender();
    const app = createTestApp({ emailSender });

    const response = await request(app)
      .post('/enquiries')
      .send({ ...validEnquiry, ...change });

    expect(response.status).toBe(400);
    expect(response.body.error.code).toBe('VALIDATION_ERROR');
    expect(response.body.error.details.map((detail: { field: string }) => detail.field)).toContain(field);
    expect(emailSender.sent).toHaveLength(0);
  });

  it('answers 400 when there is no body at all', async () => {
    const response = await request(createTestApp()).post('/enquiries');

    expect(response.status).toBe(400);
    expect(response.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('answers 400 for a body that is not valid JSON', async () => {
    const response = await request(createTestApp())
      .post('/enquiries')
      .set('Content-Type', 'application/json')
      .send('{bad json');

    expect(response.status).toBe(400);
    expect(response.body.error.code).toBe('INVALID_JSON');
  });

  it('answers 413 for a body that is too large', async () => {
    const response = await request(createTestApp())
      .post('/enquiries')
      .send({ ...validEnquiry, message: 'x'.repeat(20_000) });

    expect(response.status).toBe(413);
    expect(response.body.error.code).toBe('PAYLOAD_TOO_LARGE');
  });

  it('answers 404 and sends no email for a product that does not exist', async () => {
    const emailSender = new FakeEmailSender();
    const app = createTestApp({ emailSender });

    const response = await request(app)
      .post('/enquiries')
      .send({ ...validEnquiry, productId: 999 });

    expect(response.status).toBe(404);
    expect(emailSender.sent).toHaveLength(0);
  });

  it('answers 502, not a thank you, when the email cannot be sent', async () => {
    const app = createTestApp({ emailSender: new FakeEmailSender(new UpstreamError('mail server down')) });

    const response = await request(app).post('/enquiries').send(validEnquiry);

    expect(response.status).toBe(502);
    expect(response.body.error.code).toBe('UPSTREAM_ERROR');
  });

  it('answers 429 once a caller sends too many enquiries', async () => {
    const app = createTestApp({ rateLimit: { max: 2, windowMs: 60_000 } });

    const first = await request(app).post('/enquiries').send(validEnquiry);
    const second = await request(app).post('/enquiries').send(validEnquiry);
    const third = await request(app).post('/enquiries').send(validEnquiry);

    expect([first.status, second.status, third.status]).toEqual([201, 201, 429]);
    expect(third.body.error.code).toBe('TOO_MANY_REQUESTS');
  });
});
