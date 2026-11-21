import { Router } from 'express';
import { rateLimit } from 'express-rate-limit';
import { z } from 'zod';
import { TooManyRequestsError } from '../domain/errors';
import { EnquiryService } from '../services/enquiryService';
import { validate } from './validate';

const required = { error: 'is required' };

const enquirySchema = z.object({
  name: z.string(required).trim().min(1, 'is required').max(100),
  email: z.string(required).trim().max(254).email('must be a valid email address'),
  // Optional. An empty text counts as "not given".
  phone: z
    .string()
    .trim()
    .regex(/^([0-9+()\-\s]{6,20})?$/, 'must be 6 to 20 characters: digits, spaces and + ( ) -')
    .optional()
    .transform((phone) => phone || undefined),
  message: z.string(required).trim().min(1, 'is required').max(2000),
  productId: z.number(required).int().positive(),
});

export interface RateLimitOptions {
  max: number;
  windowMs: number;
}

export function createEnquiryRouter(enquiryService: EnquiryService, rateLimitOptions: RateLimitOptions): Router {
  const router = Router();

  // Stops one caller from flooding the sales inbox. Each caller is told apart by IP address.
  const limiter = rateLimit({
    windowMs: rateLimitOptions.windowMs,
    limit: rateLimitOptions.max,
    standardHeaders: true,
    legacyHeaders: false,
    handler: (_req, _res, next) => {
      next(new TooManyRequestsError('Too many enquiries. Please try again later.'));
    },
  });

  router.post('/enquiries', limiter, async (req, res) => {
    const enquiry = validate(enquirySchema, req.body);
    await enquiryService.submit(enquiry);
    res.status(201).json({ message: 'Thank you for your enquiry. Our sales team will be in touch soon.' });
  });

  return router;
}
