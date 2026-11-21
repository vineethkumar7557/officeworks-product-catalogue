// The id or name the caller asked for does not exist.
export class NotFoundError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'NotFoundError';
  }
}

// The place we get data from (Fake Store today) failed or sent something we cannot use.
export class UpstreamError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'UpstreamError';
  }
}

export interface FieldProblem {
  field: string;
  message: string;
}

// The caller sent input we cannot accept. "details" says which field and why.
export class ValidationError extends Error {
  readonly details: FieldProblem[];

  constructor(details: FieldProblem[]) {
    super('The request is not valid.');
    this.name = 'ValidationError';
    this.details = details;
  }
}

// Too many requests from one caller in a short time.
export class TooManyRequestsError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'TooManyRequestsError';
  }
}
