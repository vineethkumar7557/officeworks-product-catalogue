# Rules for AI assistants working in this repo

## What this is
A small product catalogue for Officeworks: browse, search, view a product, send an enquiry.
It must be a foundation that can grow, not a throwaway. Product data comes from the Fake Store API,
but ONLY through our backend.

## Stack (decided, do not change)
- iOS: Swift, UIKit, UI built in code with Auto Layout. NO SwiftUI, NO storyboards, NO Combine, NO third-party libraries.
  MVVM: each screen has a ViewController and a ViewModel. Plain async/await.
- Backend: Node.js, TypeScript, Express, zod for validation.
- Tests: XCTest (iOS), Vitest + Supertest (backend).
- Infra: docker-compose, Mailpit for local email. No paid services.

## Architecture
- Backend: routes -> services -> ports (interfaces) -> adapters.
  - ProductRepository (port) / FakeStoreProductRepository (adapter)
  - EmailSender (port) / SmtpEmailSender (adapter)
  - Services and routes never import an adapter directly. Adapters are wired in one place (server.ts); app.ts only receives ready-made services.
  - The backend returns its own clean Product shape. The app never sees the Fake Store format.
- iOS: View -> ViewModel -> APIClient (a protocol, so tests use a mock).
  Colours, fonts and spacing live in one Theme file.

## Code style
- Readable by a developer with 2.5 years of experience: small files, clear names, short functions.
- Comments only where the "why" is not obvious.
- No force unwraps (`!`). Handle loading, empty and error states on every screen.
- One consistent error format from the backend.

## Working rules
- One step at a time. Write tests in the same step as the feature.
- Config comes from environment variables. Never commit secrets (only .env.example).
- One feature branch, small commits with clear messages, push after every step.
- Record every assumption and every cut in DECISIONS.md.
