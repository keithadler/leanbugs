/-
On v4.32.1 the kernel rejects `KIPData` ("universe level ... is too big"), though
`Sort (imax 1 0)` is `Prop`. On v4.33.0 and later it is accepted, as it is for `Sort 0`.
From the first case of the fix's regression test.
-/

import Lean.CoreM
import Lean.AddDecl

open Lean

-- `Sort (imax 1 0)` normalizes to `Prop`, so this is an inductive predicate and a `Bool` field
-- is allowed, exactly as it would be for `Sort 0`.
#eval show CoreM Unit from
  addDecl <| .inductDecl [] 0 [
    { name := `KIPData
      type := .sort (.imax (.succ .zero) .zero)
      ctors := [{ name := `KIPData.mk
                  type := .forallE `b (.const ``Bool []) (.const `KIPData []) .default }] }
  ] false
