import { z } from 'zod';

// Turns "12,11,3" into [12, 11, 3] and rejects anything that is not a list of whole numbers.
const idListSchema = z
  .string()
  .default('12,11,3,18,5')
  .transform((text) => text.split(',').map((part) => Number(part.trim())))
  .refine(
    (ids) => ids.every((id) => Number.isInteger(id) && id > 0),
    'must be a comma-separated list of whole numbers, for example 12,11,3',
  );

// Every setting we read from environment variables, with a safe default for local use.
const environmentSchema = z.object({
  PORT: z.coerce.number().int().positive().default(3000),
  CORS_ORIGIN: z.string().default('http://localhost:3000'),
  FAKE_STORE_BASE_URL: z.string().url().default('https://fakestoreapi.com'),
  FAKE_STORE_TIMEOUT_MS: z.coerce.number().int().positive().default(5000),
  CACHE_TTL_SECONDS: z.coerce.number().int().nonnegative().default(300),
  FEATURED_PRODUCT_IDS: idListSchema,
  SMTP_HOST: z.string().default('localhost'),
  SMTP_PORT: z.coerce.number().int().positive().default(1025),
  EMAIL_FROM: z.string().email().default('catalogue@example.com'),
  SALES_INBOX_EMAIL: z.string().email().default('sales@example.com'),
  ENQUIRY_RATE_LIMIT_MAX: z.coerce.number().int().positive().default(5),
  ENQUIRY_RATE_LIMIT_WINDOW_MINUTES: z.coerce.number().int().positive().default(15),
});

export interface Config {
  port: number;
  corsOrigin: string;
  featuredProductIds: number[];
  fakeStore: { baseUrl: string; timeoutMs: number; cacheTtlMs: number };
  email: { smtpHost: string; smtpPort: number; from: string; salesInbox: string };
  enquiryRateLimit: { max: number; windowMs: number };
}

export function loadConfig(env: NodeJS.ProcessEnv = process.env): Config {
  const result = environmentSchema.safeParse(env);
  if (!result.success) {
    const problems = result.error.issues.map((issue) => `${issue.path.join('.')}: ${issue.message}`);
    throw new Error(`Invalid configuration. ${problems.join('; ')}`);
  }

  const values = result.data;
  return {
    port: values.PORT,
    corsOrigin: values.CORS_ORIGIN,
    featuredProductIds: values.FEATURED_PRODUCT_IDS,
    fakeStore: {
      baseUrl: values.FAKE_STORE_BASE_URL,
      timeoutMs: values.FAKE_STORE_TIMEOUT_MS,
      cacheTtlMs: values.CACHE_TTL_SECONDS * 1000,
    },
    email: {
      smtpHost: values.SMTP_HOST,
      smtpPort: values.SMTP_PORT,
      from: values.EMAIL_FROM,
      salesInbox: values.SALES_INBOX_EMAIL,
    },
    enquiryRateLimit: {
      max: values.ENQUIRY_RATE_LIMIT_MAX,
      windowMs: values.ENQUIRY_RATE_LIMIT_WINDOW_MINUTES * 60 * 1000,
    },
  };
}
