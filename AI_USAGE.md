# AI usage notes

## Tools and models
- Claude Sonnet 5.5, used in a Claude Project (claude.ai) as a step-by-step pair-programmer.

## Agent instruction files committed to the repo
- `CLAUDE.md` (rules for the AI), `PLAN.md` (the plan and step list)

## Plan / spec
- See `PLAN.md`. Written with the AI from my kickoff prompt, then reviewed and confirmed by me before any code.

## Key prompts and moments
1. Kickoff prompt: set the stack, architecture (ports and adapters), code style, git rules and "one step at a time".
   It also told the AI to challenge my decisions.
2. Step 4 (search): before writing code the AI pointed out that a plain "contains" search makes "men" also match
   "women's clothing", and proposed "typed word must start a word in the product" matching. I accepted it and it is
   covered by a test.
3. Workflow instruction from me after Step 4: "don't explain anything right now, we complete the flow first, and explain everything one by one at the end".
   From then on the AI kept replies short (step header, what was built, one Terminal block, expected result) and the explanations are saved for my
   interview preparation.
4. The kickoff rule "challenge risky decisions" is why the AI inspected the generated Xcode project (Step 8) and removed settings that would break a
   reviewer's build, instead of just building on top of it.
5. (add 1-2 of your own prompts that mattered)

## Where the AI got something wrong, and how I caught it
- Step 2: the AI put `#` comment lines inside the Terminal block. macOS zsh does not accept `#` comments when
  pasted, so it printed `command not found: #`. Harmless, but caught only because I ran it. Fixed by sending
  blocks with no comments.
- Step 2: the AI did not warn that (a) git would use a wrong auto-detected author email, and (b) GitHub needs a
  token, not a password. Caught from the Terminal output (committer shown as `...@Vineeths-MacBook-Pro.local`
  and a password prompt). Fixed with `git config` and `git commit --amend --reset-author`.
- Step 2: the AI's first tool check ran in a separate Linux machine, not on my Mac, so it could not see my
  Docker/Xcode. Caught by the AI itself; I ran the version checks on my Mac instead.
- Step 3: the AI's tests passed, but `npm run typecheck` found a type error in the test file (reading
  `mock.calls[0][0]` on a mock with no parameters). Tests alone did not show it; running typecheck did. Fixed.
- Step 3: the AI could not reach Fake Store from its own machine, so the adapter was proven with mocked tests
  only. The real call is checked by me on my Mac with `npm run try:fakestore`.
- Step 5: running the real server showed two things the unit tests did not: (a) a missing `q` gave the unfriendly
  message "expected string, received undefined" (fixed with a clear message and a test), and (b) stopping the
  server started with `tsx` by its process id left it running (so the smoke test uses the compiled server).
- Step 6: the AI could not run Docker on its own machine, so the Dockerfile and docker-compose were only checked by
  reading. The email path was proven with a throwaway SMTP server and a stand-in Fake Store, and the Docker run is
  checked by me with `docker compose up --build` on my Mac.
- Step 7: the AI's first draft of the architecture test had a fourth rule ("only adapters may mention Fake Store") that needed a
  confusing text-cleaning trick. I dropped it because I could not explain it simply, and kept three clear rules.
- Step 7: `npm run typecheck` caught that the new `vitest.config.ts` did not fit this CommonJS project. Renamed to `.mts`.
- Step 7: coverage numbers were measured first, so the new tests target real gaps (wiring in `server.ts`, the real mail transport,
  failed answers being cached) and not guesses.
- Step 8: the AI assumed the classic Xcode "New Project" wizard. In Xcode 27 clicking "App" opened an untitled SwiftUI project instead,
  which I noticed from a screenshot, and we redid it via File > New > Project.
- Step 8: the AI read the generated project file before changing it and found defaults that would break a reviewer's build:
  minimum iOS 27.2, my personal signing team ID, a UI-tests target we do not want, iPad support, and main-actor-by-default concurrency.
  They were changed and the project file was re-checked for valid structure.
- Step 8: the AI has no Swift compiler on its own machine, so the Swift code was only reviewed by reading. It is compiled and tested on my Mac
  with `xcodebuild test`.
- Step 9: Swift code again written without a compiler. Concurrency risk noted by the AI up front: a non-isolated async view model would
  update the screen off the main thread, so view models are `@MainActor` and their tests are too.
- Step 9: the AI's first Swift build failed: `RemoteImageView()` and `StateView()` had no plain `init()` because each class defines its own
  `init(frame:)`. Caught by the compiler on my Mac (the AI cannot compile Swift). Fixed with a small convenience init in both classes.
- Steps 10 and 11: the Swift compiled and the tests passed on the first run. That is NOT proof they are right (the AI cannot compile Swift, so a
  green run on my Mac is the first real check). So I also ran the full flow by hand on the simulator against the real backend and Mailpit
  (screenshots in `docs/screenshots`).
- Step 11: the coverage report showed what the tests do not prove: `CategoryCell` and `SectionHeaderView` at 0%, `ProductCell` at 11%, because the
  tests never lay out the real collection view. Recorded as a known gap in DECISIONS.md instead of hiding it.
- Environment finding (fixed in Step 2): this Mac had only Xcode Command Line Tools selected (`xcodebuild` failed).

## My own review notes
- (add your own notes here as you review each step)

## Time spent (honest log)
Wall-clock times come from the git commit times (IST, 21 Nov). They include time spent waiting for AI replies, running commands and reading.
Please correct them with your real active time before submitting.

| Phase | Wall-clock | Notes |
|-------|------------|-------|
| Planning and repo setup | 14:15 - 15:14 | structure, rules, repo, docker-compose (Steps 1-2) |
| Backend building | 15:14 - 17:46 | foundation, services, routes, enquiry and email, Docker (Steps 3-6) |
| Backend testing | 17:46 - 17:59 | gap tests, architecture test, coverage (Step 7) |
| iOS building | 17:59 - 18:46 | project, networking, all screens (Steps 8-10) |
| iOS testing | 18:46 - 18:55 | wiring, router, layout and image tests (Step 11) |
| Docs and final review | 18:56 - (fill in) | README, DECISIONS, AI_USAGE, PR (Steps 12-13) |

Total so far: about 4 hours 40 minutes from the first message to the last test run.
My own review time (reading the code, running the flow, asking the AI to explain): (fill in)
