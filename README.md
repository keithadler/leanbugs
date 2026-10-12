# leanbugs

A curated corpus of bugs in the Lean theorem prover, published at
[leanbugs.com](https://leanbugs.com). Each bug is classified by which guarantee of the trusted
pipeline it breaks, how it got in, and which checkers it gets past.

The site is built with [Verso](https://github.com/leanprover/verso) and deployed to GitHub Pages,
the same way as [lean-eval-leaderboard](https://github.com/leanprover/lean-eval-leaderboard).

## Adding a bug

Add `bugs/lean-NNNN.json`, using the next free number, and open a pull request. The build checks
every entry against the schema and fails on unknown fields or values, so CI tells you what's wrong.

```json
{
  "id": "lean-0001",
  "title": "One line saying what is wrong",
  "summary": "A paragraph: what happens, how it is reached, what it affects.",
  "status": "fixed",
  "subsystem": "kernel",
  "guarantee-broken": ["kernel-soundness"],
  "mechanism": ["kernel-internal"],
  "symptom": "proves-False",
  "severity": "unsoundness",
  "issue": "https://github.com/leanprover/lean4/issues/NNNNN",
  "fix-prs": ["https://github.com/leanprover/lean4/pull/NNNNN"],
  "fixed-in": "v4.X.Y",
  "zulip": "https://leanprover.zulipchat.com/#narrow/...",
  "fools": ["kernel"],
  "discovery": ["fro-bug-hunt"],
  "features": ["nested-inductive"],
  "links": [{"label": "Postmortem", "url": "https://..."}]
}
```

`id`, `title`, `summary`, `status`, `subsystem` and `severity` are required; the rest are
optional. Leave a field out rather than guess. A bug that breaks no guarantee, such as a missing
check, has no `guarantee-broken`.
`fixed-in` is the first stable release with the fix, or the release candidate if no stable
release has it yet. The allowed values for each field are listed in [`LeanBugs/Schema.lean`](LeanBugs/Schema.lean).

The two axes people most often mix up:

- **`guarantee-broken`** is *which promise fails*: `kernel-soundness` (the kernel accepts an
  ill-typed term), `compiler-soundness` (compiled code or the runtime disagrees with the logic, which
  matters to proofs that use `native_decide`), `elaborator-faithfulness` (the term is fine but isn't
  what the source said), `environment-injection` (a term skips the kernel or elaborator),
  `reporting-faithfulness` (`#print axioms`, the pretty-printer or a checker describes the
  environment wrongly), and `kernel-completeness` (a valid declaration is rejected).
- **`mechanism`** is *how the bug got in*, such as `kernel-internal`, `native-decide-quirk` or
  `code-gen-miscompile`.

**`fools`** lists the checkers that accept the bad proof, so the corpus can answer "what gets
past Comparator?".

## Building locally

```bash
lake build
lake exe leanbugs --output _site
python3 -m http.server -d _site
```

## Deployment

`.github/workflows/deploy.yml` builds on every push and pull request, and publishes to GitHub Pages
from `main` only. The repository's Pages source must be set to **GitHub Actions**.
