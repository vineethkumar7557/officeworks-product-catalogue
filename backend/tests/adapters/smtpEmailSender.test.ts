import { describe, expect, it, vi } from 'vitest';
import { SmtpEmailSender } from '../../src/adapters/smtpEmailSender';
import { UpstreamError } from '../../src/domain/errors';

const options = { host: 'mail.test', port: 1025, from: 'catalogue@test.example' };
const message = {
  to: 'sales@test.example',
  replyTo: 'customer@test.example',
  subject: 'New enquiry: Jacket',
  text: 'Hello',
};

describe('SmtpEmailSender', () => {
  it('hands the message to the mail transport with our from address', async () => {
    const sendMail = vi.fn(async () => ({}));
    const sender = new SmtpEmailSender(options, { sendMail });

    await sender.send(message);

    expect(sendMail).toHaveBeenCalledWith({
      from: 'catalogue@test.example',
      to: 'sales@test.example',
      replyTo: 'customer@test.example',
      subject: 'New enquiry: Jacket',
      text: 'Hello',
    });
  });

  it('gives an UpstreamError when the mail server fails', async () => {
    const sendMail = vi.fn(async () => Promise.reject(new Error('connection refused')));
    const sender = new SmtpEmailSender(options, { sendMail });

    await expect(sender.send(message)).rejects.toThrow(UpstreamError);
  });
});
