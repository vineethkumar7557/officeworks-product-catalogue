import { z } from 'zod';
import { ValidationError } from '../domain/errors';

// Checks input against a zod schema. Gives back clean data, or throws a ValidationError.
export function validate<T>(schema: z.ZodType<T>, input: unknown): T {
  const result = schema.safeParse(input);
  if (!result.success) {
    throw new ValidationError(
      result.error.issues.map((issue) => ({
        field: issue.path.join('.'),
        message: issue.message,
      })),
    );
  }
  return result.data;
}
