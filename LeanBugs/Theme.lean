import VersoBlog

open Verso.Genre Blog Theme Template
open Verso.Output Html

namespace LeanBugs

/--
Copied from lean-eval-leaderboard's `SiteTheme.lean` (itself copied from `VersoManual.Html`).

If the current address has no trailing slash, then add it. Otherwise, relative URLs don't work right
on servers that don't do this step.
-/
def addSlashJs : String :=
r#"(function(){
  const {protocol:proto, host:hostName, pathname:path, search:srch, hash:hsh} = window.location;
  if (!(path.endsWith("/") || path.endsWith(".html"))) {
    window.location.replace(`${proto}//${hostName}${path}/${srch}${hsh}`);
  }
})()"#

def siteName : String := "Lean Bugs"

def theme : Theme := { Theme.default with
  primaryTemplate := do
    let title ← param (α := String) "title"
    -- Verso emits a `<base href>` pointing at the site root, so the relative URLs below resolve
    -- against it from every page.
    return {{
      <html lang="en">
        <head>
          <script>{{addSlashJs}}</script>
          <meta charset="UTF-8"/>
          <meta name="viewport" content="width=device-width, initial-scale=1"/>
          <meta name="color-scheme" content="light dark"/>
          <title>{{ if title == siteName then .text true siteName else .text true s!"{title} — {siteName}" }}</title>
          {{← builtinHeader }}
          <link rel="icon" href="data:,"/>
          <link rel="stylesheet" href="static/style.css"/>
        </head>
        <body>
          <header class="topbar">
            <a class="wordmark" href=".">{{.text true siteName}}</a>
            <nav>
              <a href="bugs/">"All bugs"</a>
              <a href="https://github.com/sflean/leanbugs">"GitHub"</a>
            </nav>
          </header>
          <main>
            {{ ← param "content" }}
          </main>
          <footer>
            "Maintained by the "
            <a href="https://sflean.group">"SF Lean meetup"</a>
            ". Corrections and new entries welcome as "
            <a href="https://github.com/sflean/leanbugs/pulls">"pull requests"</a>
            "."
          </footer>
        </body>
      </html>
    }}
}

end LeanBugs
