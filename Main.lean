import VersoBlog
import LeanBugs.Schema
import LeanBugs.Render
import LeanBugs.Theme
import LeanBugs.Pages.Front

/-!
# `leanbugs`: generate the site

`lake exe leanbugs --output _site` reads every entry in `bugs/`, refuses to continue if any of them
breaks the schema, and writes the static site to `_site/`. Run it from the repository root.
-/

open Lean
open Verso Doc
open Verso.Genre.Blog
open LeanBugs

/-- The bug pages are known only once the entries are read, so the site is built at run time
rather than with Verso's `site` syntax. -/
def leanbugsSite (bugs : Array Bug) : Site :=
  let front := %doc LeanBugs.Pages.Front
  let allBugs : Part Page :=
    Verso.Doc.Part.mk #[.text "All bugs"] "All bugs" none #[.other (.blob (indexHtml bugs)) #[]] #[]
  .page (%docName LeanBugs.Pages.Front) (withIndex front bugs) #[
    .static "static" "static",
    .page "bugs" `LeanBugs.allBugs allBugs
      (bugs.map fun b => .page b.id (Name.mkStr `LeanBugs.bug b.id) b.part #[])
  ]

def main (args : List String) : IO UInt32 := do
  match ← loadBugs "bugs" with
  | .error errs =>
    IO.eprintln s!"leanbugs: {errs.size} problem(s) in bugs/:"
    for e in errs do IO.eprintln s!"  {e}"
    return 1
  | .ok bugs =>
    IO.eprintln s!"leanbugs: {bugs.size} entries"
    blogMain theme (leanbugsSite bugs) {} args
