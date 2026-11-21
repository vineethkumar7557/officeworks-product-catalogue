import { EmailMessage, EmailSender } from '../../src/ports/emailSender';

// Remembers the emails it was asked to send. Pass an error to make sending fail.
export class FakeEmailSender implements EmailSender {
  readonly sent: EmailMessage[] = [];
  private readonly failure: Error | null;

  constructor(failure: Error | null = null) {
    this.failure = failure;
  }

  async send(message: EmailMessage): Promise<void> {
    if (this.failure) {
      throw this.failure;
    }
    this.sent.push(message);
  }
}
