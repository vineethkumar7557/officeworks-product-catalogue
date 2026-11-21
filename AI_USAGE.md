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
2. (add the next ones as they happen)

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
- Environment finding: this Mac has only Xcode Command Line Tools selected (`xcodebuild` fails). Needs fixing
  before the iOS steps.

## My own review notes
- (add your own notes here as you review each step)

## Time spent (honest log)
| Phase     | Time | Notes |
|-----------|------|-------|
| Planning  | started 14:15 (IST, 21 Nov) | steps 1-2 |
| Building  |      | |
| Testing   |      | |
| Reviewing |      | |
