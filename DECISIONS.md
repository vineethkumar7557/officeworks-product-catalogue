# Decisions and assumptions

## Assumptions (where the acceptance criteria were unclear)
- **Featured products:** 5 product IDs chosen in config (`FEATURED_PRODUCT_IDS`). Default is 12, 11, 3, 18, 5,
  the top 5 by rating (ties broken by rating count). If a configured ID is missing from the data,
  we fill the gap with the highest rated product not already shown.
- **Category page:** top rated = the top 3 by rating (tie-break: higher rating count), then all other products in that category.
- **Search:** case-insensitive match over title, description and category. Results appear only after the user taps Search.
  An empty search term returns a 400 error, not "all products".
- **Enquiry fields:** name, email, optional phone, message, product ID. The enquiry is emailed to the sales inbox and logged.
  There is no database yet (deliberate cut, see below).
- **Category names:** used exactly as Fake Store gives them (note the "jewelery" spelling). Names with spaces or
  apostrophes (for example "men's clothing") are URL-encoded by the app and decoded by the backend.
- **Repo:** private GitHub repo, with access given to the reviewers.

## Requirements dropped or simplified, and why
- No database for enquiries: the brief only asks for an email. Storing enquiries is the first thing to add next.
- No UI tests: time-box.
- (more are added as we go)

## How the design supports growing beyond the PoC
- Product data source: only `FakeStoreProductRepository` knows about Fake Store. Swap it for a real database
  by writing a new class that follows `ProductRepository`. Services and routes do not change.
- Email provider: only `SmtpEmailSender` knows about SMTP. Swap it for SES or SendGrid by writing a new class
  that follows `EmailSender`.
- The app only knows our own clean Product shape, so a backend data change never breaks the app.
- Look and feel lives in one Theme file, so a new design is a small change.

## What I would do next with another day
- (filled in at the end)
