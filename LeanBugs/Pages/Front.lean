import VersoBlog

open Verso Genre Blog

#doc (Page) "Lean Bugs" =>

A curated corpus of bugs in the Lean theorem prover, with an emphasis on the ones that matter for
trust: proofs of `False`, statements that don't say what their source says, and checkers that
can be fooled.

LLVM and GCC have bug-study datasets, and Rocq keeps a regression file per reported bug plus a
curated list of critical soundness bugs. Lean has an issue tracker, a few checkers that can be run
against each other, and scattered Zulip threads. This site collects the bugs in one place, each one
classified by which guarantee of the trusted pipeline it breaks, how it got in, and which checkers
it gets past.

Entries live as JSON files in the
[`bugs/` directory of the repository](https://github.com/sflean/leanbugs/tree/main/bugs).
To add or correct one, open a pull request; the site build checks every entry against the schema.
