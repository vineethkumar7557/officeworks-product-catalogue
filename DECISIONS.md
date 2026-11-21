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

## Testing approach (backend)
- **Three layers of tests:** services are tested alone with a fake in-memory data source; the adapters are tested with a pretend
  internet and a pretend mail server; the API is tested through the real routes with Supertest, for every endpoint and every error code.
- **Whole-chain tests:** `realAdapterApi.test.ts` runs route -> service -> real Fake Store adapter with a pretend internet, and checks the app
  never sees the Fake Store format. `composition.test.ts` checks that each setting reaches the part it is meant for.
- **The architecture is enforced by a test** (`architecture.test.ts`): only `composition.ts` may import adapters, services/domain/ports never import
  Express, and only adapters import nodemailer. Swapping the data source or email provider therefore cannot quietly leak into services or routes.
- **Coverage is measured** (`npm run test:coverage`) with a safety net: the check fails if coverage drops under 95% (90% for branches).
  It is 100% today. Type-only files and the 3-line `server.ts` are left out of the count.
- **What tests prove vs. what they do not.** Unit tests prove our logic. The real Fake Store and a real SMTP server are checked by hand
  (`npm run try:fakestore` and `docker compose up`) because tests must not depend on the internet.

## Design choices (iOS app foundation)
- **Code-only UIKit, MVVM, plain async/await.** No storyboards (template storyboards deleted, generated launch screen), no SwiftUI, no Combine,
  no third-party libraries. Each screen has a ViewController and a ViewModel; view models only know the `APIClient` protocol.
- **iPhone only, portrait only, iOS 17 and up.** A deliberate scope cut: one layout to build and check. The Xcode default minimum (iOS 27.2)
  was lowered so a reviewer's simulator can run it.
- **Project settings kept plain.** I removed the template's default main-actor isolation and "approachable concurrency" flags, so concurrency
  behaves the standard way and is easy to explain. I removed my personal signing team ID so a reviewer can build without my account,
  and removed the unused UI-tests target (no UI tests, see below).
- **Requires Xcode 27.** The project was created with Xcode 27.2 and uses its newer project file format, so older Xcode versions cannot open it.
- **The backend address lives in Info.plist** (`API_BASE_URL`, default `http://localhost:3000`). `NSAllowsLocalNetworking` lets the simulator use plain
  http to a local server only. A real release would use https and remove that exception.
- **Product images** are loaded from the `imageUrl` our backend returns (today a Fake Store picture link). The app never calls the Fake Store API
  and never contains a Fake Store address. A real catalogue would return images from its own storage, which is a change inside the backend adapter.
- **Errors:** one `APIError` type with customer-readable text. A cancelled request (the user went back) is not shown as an error.
- **Unit tests start the app without building any screen or making network calls** (the scene delegate skips setup when XCTest is running).

## Design choices (iOS screens)
- **Navigation:** screens never open other screens. They report taps through closures, and `AppRouter` decides what opens next. Fewer links between screens, and easy to follow.
- **Product tiles:** a two-column `UICollectionView` (standard flow layout). The tile height is worked out from the fonts, so text follows the user's text size. Category and Search have the same grid.
- **Search:** typing searches nothing. Only the Search key on the keyboard sends the search (blank text is ignored), and the results open on their own screen. This matches "after tapping Search".
- **State handling:** every screen is one of loading, loaded, empty or failed. Failed and empty home/category screens offer "Try again".
- **View models** are `@MainActor`, so state changes always happen on the main thread. They tell the screen about changes with one closure (`onStateChange`), no Combine.
- **Pictures** load with a small in-memory cache (`NSCache`). A tile that scrolls away cancels its download. A missing picture shows a placeholder.
- **Prices** show a plain `$`, because the catalogue has no currency field. A real catalogue would send a currency code.
- **Home loads featured products and categories one after the other** (two small requests). Loading them in parallel would be a possible next step.
- **No pull-to-refresh and no pagination** (20 products in total). Recorded as a cut.

## Design choices (iOS details and enquiry)
- **Details page uses the product the customer tapped.** It is already loaded, so there is no second request and no loading state.
  The backend's `GET /products/:id` stays available (a link or notification would need it), but the app does not use it yet.
- **The enquiry form opens as a sheet on top of the catalogue**, with its own Cancel button. After a successful send, the same sheet shows "Thank you!"
  and a Done button that closes everything. The customer lands back on the details page.
- **The form checks itself first** (name, valid email, optional phone, message) with the same rules and limits as the backend, so mistakes show next to
  the field straight away. The backend still validates everything, because the app is not trusted.
- **Sending:** the button shows a spinner and the fields lock, so a double tap cannot send two emails. The view model also ignores a second submit
  while one is running. A backend error (for example "too many enquiries") shows its message above the button, and the typed text is kept.
- **The Thank you screen is static**, so it has no view model. Every screen with logic has a ViewController and a ViewModel.
- **Not kept:** a half-written enquiry is lost if the customer cancels (no draft saving).
- **The Thank you text is written in the app.** The backend also sends a message, but the app ignores it so the wording and language stay in one place.

## Testing approach (iOS)
- **Three layers of unit tests, all fast and offline:** (1) networking against a pretend network (`MockURLProtocol`), (2) view models against a pretend backend
  (`MockAPIClient`), (3) screen wiring: each screen is created with a pretend backend and the tests check what it shows and what a tap reports
  (for example, typing in the search bar sends nothing, and only the Search key does).
- **`AppRouterTests`** check which screen opens after each tap, and that a sent enquiry ends on the Thank you screen.
- **No UI tests and no screenshot tests.** They are slow and fragile, and the screens have no logic of their own. The full flow was also checked by hand
  on a simulator against the real backend and Mailpit (see the PR description).
- **Coverage is measured but not enforced** on iOS. Layout and pixel details are checked by eye, not by tests.

## Requirements dropped or simplified, and why
- No database for enquiries: the brief only asks for an email. Storing enquiries is the first thing to add next.
- No UI tests (XCUITest) and no screenshot tests for the iOS app: time-box. Screen behaviour is covered by unit tests with a fake backend
  and the whole flow was checked by hand (screenshots in `docs/screenshots`).
- No automatic CI pipeline (for example GitHub Actions): the same commands run locally; adding CI is the first "next step".
- No shared test for "any ProductRepository behaves the same" (a contract test). It would prove an adapter swap even more strongly.
- iPhone only and portrait only. No iPad layout, no landscape.
- No pull-to-refresh, no pagination, no offline cache (20 products in total).
- No saved draft of an unsent enquiry.

## Known gaps (honest list)
- **Some iOS view code is not unit tested.** The coverage report (78.6% for the app) shows `CategoryCell` and `SectionHeaderView` at 0% and `ProductCell` at
  11%, because the tests never lay out the real collection view. These are checked by eye (screenshots), not by tests. Logic (view models, validation,
  networking, router, screen wiring) is at or near 100%.
- **The project needs Xcode 27 to open.** It was created with Xcode 27.2 (new project file format). Recreating it with an older Xcode would remove this limit.
- **Real services are checked by hand, not by tests:** the real Fake Store API (`npm run try:fakestore`) and a real SMTP server (Mailpit via `docker compose up`).
- **The rate limit is in memory** (resets on restart, per server).
- **Search reads title, description and category.** Fake Store descriptions are long, so a common word can match many products.

## How the design supports growing beyond the PoC
- Product data source: only `FakeStoreProductRepository` knows about Fake Store. Swap it for a real database
  by writing a new class that follows `ProductRepository`. Services and routes do not change.
- Email provider: only `SmtpEmailSender` knows about SMTP. Swap it for SES or SendGrid by writing a new class
  that follows `EmailSender`.
- The app only knows our own clean Product shape, so a backend data change never breaks the app.
- Look and feel lives in one Theme file, so a new design is a small change.

## What I would do next with another day
In this order, because each one makes the next safer:
1. **CI** (GitHub Actions): backend tests and coverage, `typecheck`, and `xcodebuild test` on every pull request.
2. **Store enquiries** in a database (for example Postgres) before emailing, and send the email from a retry queue. Then a failed email never loses an enquiry.
3. **A real email provider** (SES) as a second `EmailSender` adapter. No service or route changes.
4. **Close the iOS test gaps:** dequeue cells in tests (cells and header at 0%) and add a few snapshot tests for the main screens.
5. **A shared contract test** for `ProductRepository`, run against the Fake Store adapter and any future database adapter.
6. **Deploy:** the same Docker image on AWS (ECS Fargate behind a load balancer), secrets in SSM or Secrets Manager. Set Express `trust proxy`
   and move the rate limit to Redis at the same time.
7. **Product images from our own storage** and a currency field in the backend Product, instead of Fake Store links and a fixed `$`.
8. **App polish:** load Home requests in parallel, pull-to-refresh, iPad layout, a Dynamic Type and VoiceOver audit, localisation.
9. **An OpenAPI description of the API**, so the Swift models can be checked against it automatically.
