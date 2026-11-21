# Plan

## Folder structure
```
backend/   src/{config,domain,ports,adapters,services,routes,middleware}, app.ts, server.ts, tests/, Dockerfile, .env.example
ios/       CatalogueApp/{App,Networking,Models,Features,Shared}, CatalogueAppTests/
root       docker-compose.yml, README.md, DECISIONS.md, AI_USAGE.md, CLAUDE.md, PLAN.md
```

## API
GET /featured | GET /categories | GET /categories/:name/products | GET /products?q= | GET /products/:id | POST /enquiries

## Steps
1. Confirm structure and assumptions
2. Repo, branch, CLAUDE.md, docker-compose, .env.example
3. Backend: domain, ports, Fake Store adapter
4. Backend: services (featured, category, search, product)
5. Backend: routes, validation, errors
6. Backend: enquiry, email adapter, Mailpit
7. Backend tests
8. iOS: project, Theme, Networking
9. iOS: Home, Category, Search
10. iOS: Product detail, Enquiry, Thank you
11. iOS tests (XCTest)
12. README, DECISIONS.md, AI_USAGE.md, time log
13. Final review pass, then open the PR

## If time runs short, cut in this order (and say why in DECISIONS.md)
1. Caching of Fake Store calls
2. Rate limit on /enquiries
3. Extra reusable views in the app
