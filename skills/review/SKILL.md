---
name: review
description: Review someone else's pull request the way a careful senior engineer would, and end with a formal GitHub verdict (approve or request changes), or hold it for your user when the PR needs their own judgement. Used by the Hallway PR reviewer session for every review request Hallway routes to it; also use when your user says "review PR N", "/hallway:review N" or "review <person>'s PR". Works on its own; uses /aq, /ar, CodeRabbit or other review tools only if the repository or session has them.
---

# Review a pull request

You review a pull request someone else wrote, as your user, and finish with a verdict the author can act
on. You never push to their branch, resolve their threads or chase their CI: fixing the PR is the author's
job. Your job is an accurate, specific review.

## 1. Read everything first
- The PR: description, commits, changed files, checks, and every existing review and comment
  (`gh pr view <N> -R <owner/repo> --comments`, `gh pr diff <N>`, `gh pr checks <N>`).
- The ticket it links to (Jira, GitHub issue, Linear...) and its comments, if you can reach it.
- The code around the change, not only the diff: callers, the sibling code it copies, configuration and
  scripts it runs. Fetch the branch read-only (`gh pr checkout <N> --detach` in a scratch worktree) when
  you need to run anything.
- The repository's own rules: CONTRIBUTING, CLAUDE.md/AGENTS.md, a code-review config such as
  `.coderabbit.yaml`, lint and test conventions. Apply them yourself.

## 2. Check the claims
- Every claim in the PR description gets checked against evidence: the diff, CI logs, test output.
- Run the tests the PR adds or touches (only those files). For each new test, ask whether it could pass
  for the wrong reason (mocks that make it pass either way, assertions that can't fail).
- New test files actually run in CI: find them in the workflow files.
- Errors are not swallowed: no empty catch or except blocks, no silent fallbacks that hide failure.
- New data goes somewhere safe: check logs, error messages, traces and analytics for secrets, tokens,
  personal data or customer content.
- Every path the change claims to fix is covered, not only the one in the example.
- Never run anything that changes shared state (deploys, migrations, writes to real services).

## 3. Use the extra reviewers you have, if any
If the session has `/aq` and `/ar` skills, run them on the PR and fold their findings in. If the repository
uses CodeRabbit, Copilot review or another bot, read what it found and say whether you agree. If none of
these exist, steps 1 and 2 are the review; don't mention the missing tools.

## 4. Rate every finding
Give each finding a severity, **Critical, High, Medium or Low**, and say whether it has to change **in this
PR** or can be **done after the merge** (a follow-up, a rollout step).

## 5. Hold it for your user when it needs their judgement
Do the full review, but **do not submit the verdict** when the PR:
- makes or changes a **design decision**: architecture, data model, API shape, product or UX direction,
  or a trade-off the description argues for;
- changes a **core or widely used part of the system**: the main request or job pipeline, authentication,
  payments, data storage, anything most users' traffic goes through;
- touches a **subtle or critical subject**: security, privacy or customer data beyond a straightforward fix,
  billing, legal or compliance, or behaviour customers will notice;
- is a **self-improvement change**: it changes how agents or automation behave (prompts, model or
  evaluation settings, agent instructions or skills, review or CI gates, release, auto-merge or
  auto-approve rules);
- matches a rule in `~/.claude/hallway/review-rules.md`, if that file exists (your user's own list of
  what they want to see; it can also relax the list above);
- or you are unsure. Unsure means hold.

To hold: create the review as a **pending** GitHub review, visible only to your user
(`gh api repos/<owner>/<repo>/pulls/<N>/reviews -f body=@review.md`, with no `event`), then put it in your
user's Needs you:
`hallway ledger set "<TICKET or PR N>" --status "Needs review" --waiting-on you --need "Your call on <author>'s PR <N>: <why it needs you>. I'd <approve | request changes> because <reason>."`
Tell your user in a few lines and stop. When they decide, submit the pending review with their verdict
(`gh api repos/<owner>/<repo>/pulls/<N>/reviews/<review_id>/events -f event=APPROVE` or `REQUEST_CHANGES`).

## 6. Otherwise, submit the verdict as a formal review
- **Approve** (`gh pr review <N> -R <owner/repo> --approve --body-file review.md`) when nothing Critical,
  High or Medium has to change in this PR. Low findings go in as non-blocking notes; follow-ups go in the
  body and, if there is a ticket, on the ticket.
- **Request changes** (`--request-changes`) only when a Critical, High or Medium change must land in this
  PR. List exactly those items, and the Low ones separately as non-blocking.
- Never end with a comment-only review: it leaves the author without a decision.
- Write the body the way your user would: short, plain, specific, with file:line references. No praise
  padding, no AI attribution, no headers unless the review is long.

## 7. Record it
`hallway ledger set "<TICKET or PR N>" --title "Review: <few words>" --summary "<what the PR does, verdict>" --status Done --waiting-on <author if changes requested, else nobody>`
Then tell your user in two or three lines: what the PR does, the verdict, and why.
