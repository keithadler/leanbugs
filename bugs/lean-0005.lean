/-
On v4.24.0 this prints `false`. On v4.25.0 and later it prints `true`.
From the issue.
-/

#eval
  let s : Substring := ⟨"", ⟨1⟩, 0⟩
  s == s
