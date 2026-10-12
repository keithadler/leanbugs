import VersoBlog
import LeanBugs.Schema
import LeanBugs.Theme

/-!
# Pages built from the entries

The entries are read when the site is generated, not when it is compiled, so adding a bug needs no
Lean code. Each bug becomes a page under `bugs/`, and the front page gets a table of all of them.
-/

open Verso Doc Output Html
open Verso.Genre Blog

namespace LeanBugs

private def txt (s : String) : Html := .text true s

/-- Tags, styled like lean-eval's problem tags. -/
private def chips (vs : Array String) : Html :=
  if vs.isEmpty then txt "—" else
  {{ <div class="lifecycle-tag-list">{{vs.map fun v => {{ <span class="lifecycle-tag">{{txt v}}</span> }}}}</div> }}

private def linkTo (label url : String) : Html :=
  {{ <a href={{url}}>{{txt label}}</a> }}

/-- A GitHub issue or PR URL shortened to `#1234` for display. -/
private def shortRef (url : String) : String :=
  match (url.splitOn "/").reverse with
  | n :: kind :: _ => if kind == "issues" || kind == "pull" then s!"#{n}" else url
  | _ => url

private def row (label : String) (value : Html) : Html :=
  {{ <tr><th scope="row">{{txt label}}</th><td>{{value}}</td></tr> }}

/-- The classification table on a bug's own page. -/
def Bug.detailHtml (b : Bug) : Html :=
  let refs : Array Html :=
    (b.issue.toArray.map fun u => linkTo s!"issue {shortRef u}" u)
    ++ b.fixPrs.map (fun u => linkTo s!"fix {shortRef u}" u)
    ++ (b.zulip.toArray.map fun u => linkTo "Zulip thread" u)
    ++ b.links.map (fun l => linkTo l.label l.url)
  let refList : Html :=
    if refs.isEmpty then txt "—" else {{ <ul class="refs">{{refs.map fun r => {{<li>{{r}}</li>}}}}</ul> }}
  {{
    <div class="lifecycle-table-scroll"><table class="lifecycle-table bug-detail">
      {{row "Status" (txt b.status)}}
      {{row "Fixed in" (txt (b.fixedIn.getD "—"))}}
      {{row "Subsystem" (txt b.subsystem)}}
      {{row "Guarantee broken" (chips b.guaranteeBroken)}}
      {{row "Mechanism" (chips b.mechanism)}}
      {{row "Symptom" (txt (b.symptom.getD "—"))}}
      {{row "Severity" (txt b.severity)}}
      {{row "Fools" (chips b.fools)}}
      {{row "Discovery" (chips b.discovery)}}
      {{row "Features" (chips b.features)}}
      {{row "References" refList}}
    </table></div>
  }}

/-- The reproduction from `bugs/<id>.lean`, if there is one. -/
def Bug.reproHtml (b : Bug) : Html :=
  match b.repro with
  | none => .empty
  | some code =>
    let file := s!"bugs/{b.id}.lean"
    let source : Html := match b.reproSource with
      | some u =>
        let label := if shortRef u != u then shortRef u else ((u.splitOn "/").getLast?.getD u)
        {{ " Adapted from " {{linkTo label u}} "." }}
      | none => .empty
    {{
      <h2>"Reproduction"</h2>
      <p class="repro-note">
        "Shows the bug on Lean " <code>{{txt (b.reproOn.getD "?")}}</code> "."
        {{source}} " "
        {{linkTo file s!"{repoUrl}/blob/main/{file}"}}
      </p>
      <pre class="repro"><code class="language-lean">{{txt code.trimAsciiEnd.toString}}</code></pre>
    }}

/-- The page for one bug. -/
def Bug.part (b : Bug) : Part Page :=
  let title := s!"{b.id}: {b.title}"
  Part.mk #[.text title] title none
    #[.para #[.text b.summary], .other (.blob b.detailHtml) #[], .other (.blob b.reproHtml) #[]] #[]

/-- The table of all bugs on the front page. -/
def indexHtml (bugs : Array Bug) : Html :=
  {{
    <div class="lifecycle-table-scroll"><table class="lifecycle-table">
      <thead><tr>
        <th scope="col">"ID"</th><th scope="col">"Bug"</th>
        <th scope="col">"Guarantee broken"</th><th scope="col">"Status"</th>
      </tr></thead>
      <tbody>
        {{bugs.map fun b => {{
          <tr>
            <td class="bug-id">{{txt b.id}}</td>
            <th scope="row"><a href={{s!"bugs/{b.id}/"}}>{{txt b.title}}</a></th>
            <td>{{chips b.guaranteeBroken}}</td>
            <td>{{txt b.status}}</td>
          </tr>
        }}}}
      </tbody>
    </table></div>
  }}

/-- `front` with the bug table appended. -/
def withIndex (front : Part Page) (bugs : Array Bug) : Part Page :=
  { front with content := front.content ++ #[
      .other (.blob {{ <h2>{{txt s!"Bugs ({bugs.size})"}}</h2> }}) #[],
      .other (.blob (indexHtml bugs)) #[]] }

end LeanBugs
