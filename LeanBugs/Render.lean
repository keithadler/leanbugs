import VersoBlog
import LeanBugs.Schema

/-!
# Pages built from the entries

The entries are read when the site is generated, not when it is compiled, so adding a bug needs no
Lean code. Each bug becomes a page under `bugs/`, and the front page gets a table of all of them.
-/

open Verso Doc Output Html
open Verso.Genre Blog

namespace LeanBugs

private def txt (s : String) : Html := .text true s

private def chips (vs : Array String) : Html :=
  if vs.isEmpty then txt "—" else
  .seq <| vs.map fun v => {{ <span class="chip">{{txt v}}</span> }}

private def linkTo (label url : String) : Html :=
  {{ <a href={{url}}>{{txt label}}</a> }}

/-- A GitHub issue or PR URL shortened to `#1234` for display. -/
private def shortRef (url : String) : String :=
  match (url.splitOn "/").reverse with
  | n :: kind :: _ => if kind == "issues" || kind == "pull" then s!"#{n}" else url
  | _ => url

private def row (label : String) (value : Html) : Html :=
  {{ <tr><th>{{txt label}}</th><td>{{value}}</td></tr> }}

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
    <table class="bug">
      {{row "Status" (txt b.status)}}
      {{row "Fixed in" (txt (b.fixedIn.getD "—"))}}
      {{row "Subsystem" (txt b.subsystem)}}
      {{row "Guarantee broken" (chips b.guaranteeBroken)}}
      {{row "Mechanism" (chips b.mechanism)}}
      {{row "Symptom" (txt b.symptom)}}
      {{row "Severity" (txt b.severity)}}
      {{row "Fools" (chips b.fools)}}
      {{row "Discovery" (chips b.discovery)}}
      {{row "Features" (chips b.features)}}
      {{row "References" refList}}
    </table>
  }}

/-- The page for one bug. -/
def Bug.part (b : Bug) : Part Page :=
  let title := s!"{b.id}: {b.title}"
  Part.mk #[.text title] title none
    #[.para #[.text b.summary], .other (.blob b.detailHtml) #[]] #[]

/-- The table of all bugs on the front page. -/
def indexHtml (bugs : Array Bug) : Html :=
  {{
    <table class="index">
      <thead><tr><th>"ID"</th><th>"Bug"</th><th>"Guarantee broken"</th><th>"Status"</th></tr></thead>
      <tbody>
        {{bugs.map fun b => {{
          <tr>
            <td><a href={{s!"bugs/{b.id}/"}}><code>{{txt b.id}}</code></a></td>
            <td>{{txt b.title}}</td>
            <td>{{chips b.guaranteeBroken}}</td>
            <td>{{txt b.status}}</td>
          </tr>
        }}}}
      </tbody>
    </table>
  }}

/-- `front` with the bug table appended. -/
def withIndex (front : Part Page) (bugs : Array Bug) : Part Page :=
  { front with content := front.content ++ #[
      .other (.blob {{ <h2>{{txt s!"Bugs ({bugs.size})"}}</h2> }}) #[],
      .other (.blob (indexHtml bugs)) #[]] }

end LeanBugs
