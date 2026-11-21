export interface EmailMessage {
  to: string;
  replyTo?: string;
  subject: string;
  text: string;
}

// The port: what the services need from "something that sends email".
// Mailpit, SES, SendGrid or anything else can sit behind it.
export interface EmailSender {
  send(message: EmailMessage): Promise<void>;
}
