/-
On v4.32.1 Lean accepts this file and `#check @mutB` shows `mutB : Sort u → Sort u`, a
type mentioning a universe parameter that `mutB` never declared. On v4.33.0 and later the
kernel rejects the mutual block.
From the fix's regression test, with the `#guard_msgs` removed and the `#check` added.
-/

import Lean.CoreM
import Lean.AddDecl

/-!
The kernel must reject a mutual definition whose members disagree on their
universe level parameters.

`add_mutual` shares one `type_checker` across all members, and the infer-type
cache is keyed on the expression alone, not on the level parameters in scope.
So the member declaring `u` must be checked first: it populates the cache for
`Sort u → Sort u`, and without this check the second member would hit that
entry and never run `check_level`, entering the environment with an undeclared
universe parameter in its type.
-/

open Lean

private def ty : Expr := .forallE `x (.sort (.param `u)) (.sort (.param `u)) .default
private def val : Expr := .lam `x (.sort (.param `u)) (.bvar 0) .default

#eval addDecl <| .mutualDefnDecl [
  { name := `mutA, levelParams := [`u], type := ty, value := val,
    hints := .opaque, safety := .partial },
  { name := `mutB, levelParams := [], type := ty, value := val,
    hints := .opaque, safety := .partial }]

#check @mutB
