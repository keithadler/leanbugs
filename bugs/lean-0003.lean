/-
On v4.33.1 Lean accepts `flt`, with `native_decide`'s axiom as the only non-standard one.
On v4.34.0 and later `native_decide` finds the proposition false.
From the issue, as reported.
-/

def marvelousProof : String := "a truly marvelous proof"
def marginStart : String.Pos.Raw := ⟨2^63⟩
def marginEnd : String.Pos.Raw := ⟨2^63 + 1⟩

theorem flt
    (a b c n : Nat) (hn : 2 < n) (ha : 0 < a) (hb : 0 < b) (hc : 0 < c) :
    a ^ n + b ^ n ≠ c ^ n :=
  -- The one-byte margin is too narrow to contain the proof.
  have tooNarrow :
      String.Pos.Raw.extract marvelousProof marginStart marginEnd = "" := rfl
  -- Native execution fits the entire proof into it anyway.
  have proofFits :
      String.Pos.Raw.extract marvelousProof marginStart marginEnd = marvelousProof := by
    native_decide
  -- Fermat's proof fits after all.
  absurd (tooNarrow.symm.trans proofFits) (by decide)

#print axioms flt
