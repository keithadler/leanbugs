import Lean.Data.Json

/-!
# The bug entry schema

Each bug is one JSON file, `bugs/<id>.json`. This module parses an entry and checks it: required
fields are present, every enum-valued field uses a known value, and no unknown keys appear. The site
build refuses to run if any entry fails, so a malformed entry fails CI on its pull request.

The axes follow the schema sketch in the SF Lean bug-corpus notes. `guarantee-broken` is *which
promise of the trusted pipeline fails*; `mechanism` is *how the bug got in*. They are kept apart on
purpose: users filter on the first, implementers on the second.
-/

open Lean

namespace LeanBugs

/-! ## Enumerations -/

def statuses : List String :=
  ["open", "fixed", "wontfix", "by-design", "spec-ambiguous"]

def subsystems : List String :=
  ["parser", "elaborator", "typeclass", "unifier", "tactic", "simp", "grind",
   "kernel", "code-gen", "runtime", "lake", "lsp", "server", "build"]

def guarantees : List String :=
  [ "kernel-soundness"         -- the kernel accepts an ill-typed `Expr`
  , "compiler-soundness"       -- compiled code disagrees with the logical definition
  , "elaborator-faithfulness"  -- a well-typed `Expr`, but not what the source said
  , "environment-injection"    -- an `Expr` bypasses the kernel or elaborator
  , "reporting-faithfulness"   -- `#print axioms`, the pretty-printer or a checker describes it wrong
  , "kernel-completeness"      -- the kernel rejects a valid declaration
  ]

def mechanisms : List String :=
  ["tactic-misbehavior", "macro-or-notation-shadowing", "addDeclCore-doCheck-false",
   "native-decide-quirk", "code-gen-miscompile", "checker-disagreement", "kernel-internal",
   "memory-safety", "dependency"]

def symptoms : List String :=
  ["proves-False", "wrong-elaboration", "infinite-loop", "oom", "crash", "bad-error-message",
   "perf-regression", "ide-hang", "rejects-valid"]

def severities : List String :=
  ["unsoundness", "wrong-result", "crash", "perf", "ux"]

def checkers : List String :=
  ["kernel", "lean4checker", "lean4lean", "nanoda", "ind-models", "con-leche", "SafeVerify",
   "Comparator", "print-axioms"]

def discoveries : List String :=
  ["user-report", "fro-bug-hunt", "ai-assisted", "external-security-research",
   "Lean4Lean-formalization", "kernel-arena-differential", "external-checker-diff",
   "random-gen", "proof-mutation", "pbt-counterexample", "found-while-formalizing"]

/-! ## Entries -/

/-- A link with a short label, e.g. a postmortem or a write-up. -/
structure Link where
  label : String
  url : String
deriving Inhabited, Repr

/-- One bug. JSON keys are the kebab-case forms of these field names. -/
structure Bug where
  id : String
  title : String
  summary : String
  status : String
  subsystem : String
  guaranteeBroken : Array String
  symptom : String
  severity : String
  issue : Option String := none
  fixPrs : Array String := #[]
  fixedIn : Option String := none
  zulip : Option String := none
  mechanism : Array String := #[]
  fools : Array String := #[]
  discovery : Array String := #[]
  features : Array String := #[]
  links : Array Link := #[]
deriving Inhabited, Repr

def knownKeys : List String :=
  ["id", "title", "summary", "status", "subsystem", "guarantee-broken", "symptom", "severity",
   "issue", "fix-prs", "fixed-in", "zulip", "mechanism", "fools", "discovery", "features", "links"]

private def optField [FromJson α] (j : Json) (k : String) : Except String (Option α) :=
  match j.getObjVal? k with
  | .ok .null | .error _ => pure none
  | .ok v => match fromJson? v with
    | .ok a => pure (some a)
    | .error e => throw s!"field `{k}`: {e}"

private def reqField [FromJson α] (j : Json) (k : String) : Except String α := do
  match ← optField j k with
  | some a => pure a
  | none => throw s!"missing required field `{k}`"

private def arrField [FromJson α] (j : Json) (k : String) : Except String (Array α) :=
  return (← optField (α := Array α) j k).getD #[]

instance : FromJson Link where
  fromJson? j := return { label := ← reqField j "label", url := ← reqField j "url" }

instance : FromJson Bug where
  fromJson? j := return {
    id := ← reqField j "id"
    title := ← reqField j "title"
    summary := ← reqField j "summary"
    status := ← reqField j "status"
    subsystem := ← reqField j "subsystem"
    guaranteeBroken := ← reqField j "guarantee-broken"
    symptom := ← reqField j "symptom"
    severity := ← reqField j "severity"
    issue := ← optField j "issue"
    fixPrs := ← arrField j "fix-prs"
    fixedIn := ← optField j "fixed-in"
    zulip := ← optField j "zulip"
    mechanism := ← arrField j "mechanism"
    fools := ← arrField j "fools"
    discovery := ← arrField j "discovery"
    features := ← arrField j "features"
    links := ← arrField j "links"
  }

/-! ## Validation -/

private def checkOne (field : String) (allowed : List String) (v : String) : Array String :=
  if allowed.contains v then #[] else #[s!"`{field}`: unknown value `{v}` (allowed: {allowed})"]

private def checkAll (field : String) (allowed : List String) (vs : Array String) : Array String :=
  vs.foldl (· ++ checkOne field allowed ·) #[]

private def isUrl (s : String) : Bool :=
  s.startsWith "https://" || s.startsWith "http://"

/-- Problems with a parsed entry. `fileStem` is the file name without `.json`, which must equal
the entry's `id`. -/
def Bug.problems (b : Bug) (fileStem : String) : Array String := Id.run do
  let mut errs := #[]
  if b.id != fileStem then
    errs := errs.push s!"`id` is `{b.id}` but the file is `{fileStem}.json`"
  unless b.id.startsWith "lean-" && (b.id.drop 5).all Char.isDigit && b.id.length == 9 do
    errs := errs.push s!"`id` must look like `lean-0001`, not `{b.id}`"
  if b.guaranteeBroken.isEmpty then
    errs := errs.push "`guarantee-broken` must name at least one guarantee"
  errs := errs ++ checkOne "status" statuses b.status
    ++ checkOne "subsystem" subsystems b.subsystem
    ++ checkAll "guarantee-broken" guarantees b.guaranteeBroken
    ++ checkOne "symptom" symptoms b.symptom
    ++ checkOne "severity" severities b.severity
    ++ checkAll "mechanism" mechanisms b.mechanism
    ++ checkAll "fools" checkers b.fools
    ++ checkAll "discovery" discoveries b.discovery
  for u in [b.issue, b.zulip].filterMap (·) ++ b.fixPrs.toList ++ (b.links.map (·.url)).toList do
    unless isUrl u do errs := errs.push s!"not a URL: `{u}`"
  return errs

/-- Keys present in the JSON object that the schema does not know, which are usually typos. -/
def unknownKeys (j : Json) : Array String :=
  match j.getObj? with
  | .ok obj => obj.foldl (init := #[]) fun acc k _ => if knownKeys.contains k then acc else acc.push k
  | .error _ => #[]

/-- Parse and check one file. Returns the entry, or every problem found with it. -/
def loadBug (path : System.FilePath) : IO (Except (Array String) Bug) := do
  let stem := path.fileStem.getD ""
  let text ← IO.FS.readFile path
  let j ← match Json.parse text with
    | .ok j => pure j
    | .error e => return .error #[s!"invalid JSON: {e}"]
  let extra := (unknownKeys j).map (s!"unknown field `{·}`")
  match fromJson? (α := Bug) j with
  | .error e => return .error (extra.push e)
  | .ok b =>
    let errs := extra ++ b.problems stem
    return if errs.isEmpty then .ok b else .error errs

/-- Load every `*.json` under `dir`, sorted by id. Fails with all problems in all files at once. -/
def loadBugs (dir : System.FilePath) : IO (Except (Array String) (Array Bug)) := do
  let entries ← dir.readDir
  let files := entries.filter (·.path.extension == some "json") |>.map (·.path)
  let mut bugs := #[]
  let mut errs := #[]
  for f in files do
    match ← loadBug f with
    | .ok b => bugs := bugs.push b
    | .error es => errs := errs ++ es.map (s!"{f}: {·}")
  bugs := bugs.qsort (·.id < ·.id)
  for i in [1:bugs.size] do
    if bugs[i]!.id == bugs[i-1]!.id then errs := errs.push s!"duplicate id `{bugs[i]!.id}`"
  return if errs.isEmpty then .ok bugs else .error errs

end LeanBugs
