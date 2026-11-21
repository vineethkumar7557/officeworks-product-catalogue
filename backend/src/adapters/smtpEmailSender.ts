import nodemailer from 'nodemailer';
import { UpstreamError } from '../domain/errors';
import { EmailMessage, EmailSender } from '../ports/emailSender';

export interface SmtpOptions {
  host: string;
  port: number;
  from: string;
}

// The one thing we need from nodemailer, so tests can replace it.
export interface MailTransport {
  sendMail(mail: { from: string; to: string; replyTo?: string; subject: string; text: string }): Promise<unknown>;
}

// Sends email over SMTP. In development the SMTP server is Mailpit (a local mail catcher).
// This is the ONLY file that knows about SMTP and nodemailer.
export class SmtpEmailSender implements EmailSender {
  private readonly from: string;
  private readonly transport: MailTransport;

  constructor(options: SmtpOptions, transport?: MailTransport) {
    this.from = options.from;
    this.transport =
      transport ??
      nodemailer.createTransport({
        host: options.host,
        port: options.port,
        secure: false,
        connectionTimeout: 5000,
        greetingTimeout: 5000,
        socketTimeout: 10000,
      });
  }

  async send(message: EmailMessage): Promise<void> {
    try {
      await this.transport.sendMail({
        from: this.from,
        to: message.to,
        replyTo: message.replyTo,
        subject: message.subject,
        text: message.text,
      });
    } catch {
      throw new UpstreamError('The email could not be sent. Please try again later.');
    }
  }
}
