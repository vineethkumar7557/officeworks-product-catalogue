# Decisions and assumptions

## Assumptions (where the acceptance criteria were unclear)
- **Featured products:** 5 product IDs chosen in config (`FEATURED_PRODUCT_IDS`). Default is 12, 11, 3, 18, 5,
  the top 5 by rating (ties broken by rating count). If a configured ID is missing from the data,
  we fill the gap with the highest rated product not already shown.
- **Category page:** top rated = the top 3 by rating (tie-break: higher rating count, then lower id), then all other products
  in that category, also best first. An unknown category gives a 404.
- **Search:** case-insensitive, over title, description and category. Results appear only after the user taps Search.
  Every typed word must be the START of a word in the product text, in any order. So "jack" finds "jacket",
  but "men" does not wrongly find "women's clothing" (plain "contains" matching would). Results are best rated first.
  An empty search finds nothing (the API will answer 400 for a missing or empty `q`, see Step 5).
- **Enquiry fields:** name, email, optional phone, message, product ID. The enquiry is emailed to the sales inbox and logged.
  There is no database yet (deliberate cut, see below).
- **Category names:** used exactly as Fake Store gives them (note the "jewelery" spelling). Names with spaces or
  apostrophes (for example "men's clothing") are URL-encoded by the app and decoded by the backend.
- **Repo:** private GitHub repo, with access given to the reviewers.

## Design choices (backend foundation)
- **One cached call to Fake Store.** Fake Store has only 20 products, so the adapter loads `/products` once, keeps it
  in memory for `CACHE_TTL_SECONDS`, and answers by-id, by-category and category-list questions from that list.
  Fewer calls, and it avoids Fake Store's odd empty answer for a missing id. With a real database these become real queries.
- **Strict checking of Fake Store data (zod).** If their data changes shape we fail with a clear 502-style error
  instead of showing broken products.
- **Timeout on every Fake Store call** (`FAKE_STORE_TIMEOUT_MS`). Slow or failing source = `UpstreamError`.
- **The port returns `null` for a missing product.** The service decides that this means "not found" for the API.
- **Plain CommonJS TypeScript.** No import-extension rules to explain; works the same in tests, dev and Docker.

## API contract (all errors use one format)
- `GET /health` -> `{ "status": "ok" }`
- `GET /featured` -> `{ "products": [Product] }`
- `GET /categories` -> `{ "categories": [String] }`
- `GET /categories/:name/products` -> `{ "category", "topRated": [Product], "others": [Product] }` (unknown name: 404)
- `GET /products?q=` -> `{ "query", "products": [Product] }` (missing or blank `q`: 400)
- `GET /products/:id` -> `Product` (bad id: 400, unknown id: 404)
- `POST /enquiries` with `{ name, email, phone?, message, productId }` -> 201 `{ "message": "Thank you ..." }`.
  Bad input: 400 (field named). Unknown product: 404. Email failed: 502 (the customer is NOT told "thank you").
  Too many from one IP address: 429.
- Errors: `{ "error": { "code", "message", "details?" } }` with codes VALIDATION_ERROR (400), INVALID_JSON (400),
  NOT_FOUND (404), PAYLOAD_TOO_LARGE (413), TOO_MANY_REQUESTS (429), UPSTREAM_ERROR (502),
  INTERNAL_ERROR (500, never shows internal details).
- Product ids must be digits only (1 to 999,999,999). Input like `1e3`, `1.5`, `-1` or `abc` is rejected with 400.
- Request bodies are limited to 10 KB. `/health` is an extra endpoint for Docker and quick checks.
- Express 5, so errors thrown inside async routes reach the error handler without extra wrapper code.

## Design choices (enquiry and email)
- **Enquiry checks:** name 1-100 characters, email valid (max 254), phone optional (6-20 characters: digits, spaces, `+ ( ) -`;
  empty counts as not given), message 1-2000 characters, `productId` a whole number. Spaces around text are trimmed.
- **The product must exist.** An enquiry about an unknown product is rejected (404), so sales never gets an email about nothing.
- **Email is sent before we answer.** If sending fails the customer gets an error and can retry. They never see a false "thank you".
- **Reply-To is the customer's email,** so sales can answer straight from their inbox. The subject only uses the product title
  (never customer text), so customers cannot inject email headers.
- **Logging without personal data.** The log says "an enquiry was emailed for product N" but never includes name, email, phone or message.
  The brief asks only for the email, so there is no database yet (deliberate cut).
- **Rate limit:** `ENQUIRY_RATE_LIMIT_MAX` enquiries per `ENQUIRY_RATE_LIMIT_WINDOW_MINUTES` per IP address (default 5 per 15 minutes),
  kept in memory. Limits: it resets when the server restarts and is per server instance. Behind a load balancer (AWS) we must also
  set Express "trust proxy" so the real caller IP is used. Next step would be a shared store such as Redis.
- **SMTP without login.** Mailpit needs none. A real provider (SES, SendGrid) would need a user, password and TLS: a new adapter
  or extra settings, and no change to the service.
- **Docker:** two-stage backend image (build, then a small run image as a non-root user). `docker compose up --build` starts the
  backend and Mailpit; `backend/.env` is optional because every setting has a default. Inside Docker the backend reaches Mailpit as `mailpit`.

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
