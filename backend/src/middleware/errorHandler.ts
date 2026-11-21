import { NextFunction, Request, Response } from 'express';
import { FieldProblem, NotFoundError, UpstreamError, ValidationError } from '../domain/errors';

// Every error the API sends has this one shape.
interface ErrorBody {
  error: { code: string; message: string; details?: FieldProblem[] };
}

interface ErrorResponse {
  status: number;
  body: ErrorBody;
}

function build(status: number, code: string, message: string, details?: FieldProblem[]): ErrorResponse {
  return { status, body: { error: { code, message, details } } };
}

// Errors from the JSON reader (bad JSON, body too big) carry a "type" text.
function bodyParserErrorType(error: unknown): string | null {
  if (typeof error === 'object' && error !== null && 'type' in error && typeof error.type === 'string') {
    return error.type;
  }
  return null;
}

function toErrorResponse(error: unknown): ErrorResponse {
  if (error instanceof ValidationError) {
    return build(400, 'VALIDATION_ERROR', error.message, error.details);
  }
  if (error instanceof NotFoundError) {
    return build(404, 'NOT_FOUND', error.message);
  }
  if (error instanceof UpstreamError) {
    return build(502, 'UPSTREAM_ERROR', error.message);
  }
  if (bodyParserErrorType(error) === 'entity.parse.failed') {
    return build(400, 'INVALID_JSON', 'The request body is not valid JSON.');
  }
  if (bodyParserErrorType(error) === 'entity.too.large') {
    return build(413, 'PAYLOAD_TOO_LARGE', 'The request body is too large.');
  }
  // Anything else is our bug. Never show its details to the caller.
  return build(500, 'INTERNAL_ERROR', 'Something went wrong.');
}

export function notFoundHandler(_req: Request, res: Response): void {
  const { status, body } = build(404, 'NOT_FOUND', 'Route not found.');
  res.status(status).json(body);
}

// Express knows this is an error handler because it has exactly 4 parameters.
export function errorHandler(error: unknown, _req: Request, res: Response, _next: NextFunction): void {
  const { status, body } = toErrorResponse(error);
  if (status >= 500) {
    console.error('Request failed:', error);
  }
  res.status(status).json(body);
}
