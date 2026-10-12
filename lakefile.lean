import Lake
open Lake DSL

require verso from git "https://github.com/leanprover/verso" @ "v4.34.0"

package leanbugs where

lean_lib LeanBugs where

@[default_target]
lean_exe leanbugs where
  root := `Main
  supportInterpreter := true
