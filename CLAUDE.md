# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Source for the **[Karnak documentation site](https://weasis.org/karnak-documentation/)** — the docs for the [Karnak](https://github.com/nroduit/karnak) DICOM gateway (de-identification + DICOM attribute normalization). It is a Hugo static site using the [Relearn theme](https://github.com/McShelby/hugo-theme-relearn), pulled in as a git submodule at `themes/hugo-theme-relearn`. Content is authored in Markdown; there is no application code.

## Common commands

```shell
# First-time setup (theme is a submodule — required for the site to build)
git submodule update --init --recursive

# Local dev server with live reload at http://localhost:1313
hugo serve

# Production build (matches CI)
hugo --gc --minify

# Update the theme to its latest upstream
cd themes/hugo-theme-relearn && git pull origin main && cd ../..
```

Hugo **extended** is required (Dart Sass). CI pins `HUGO_VERSION` in `.github/workflows/hugo.yaml` — prefer matching that locally when reproducing CI behavior. There is no test suite; the build itself is the gate.

### HUGO_GH_TOKEN

`layouts/shortcodes/latest-download.html` (the portable-download table, used via `{{< latest-download >}}` on `userguide/portable.en.md`) calls the GitHub Releases API at build time and needs a GitHub token in the `HUGO_GH_TOKEN` env var. Behavior without it:

- **token unset/empty** → the shortcode renders an inline red error and skips the network call, so `hugo`/`hugo serve` still build successfully. Use this for local work that doesn't touch the download table.
- **token set but invalid** → the GetRemote call returns `Unauthorized` and the **whole build fails**. Either export a valid PAT or leave the var unset.

CI injects a valid token from the `HUGO_GH_TOKEN` secret.

## Architecture

- **Content** lives under `content/`. Files are language-suffixed: `*.en.md` (English, default). French is declared in `config.toml` but is largely untranslated — when adding a page, mirror the existing `.en.md` convention; section landing pages are `_index.en.md`. `defaultContentLanguageInSubdir = true`, so English is served under `/en/`, not the root.
- **Top-level sections** map to the site nav:
  - `installation/` — deploying/running Karnak (Docker, logs).
  - `profiles/` — de-identification and tag-morphing rule authoring (YAML profiles, conditions, expressions, masks, dates, tags, API).
  - `userguide/` — the web portal, with a `gateway/` subsection for `sources` and `destinations`.
- **Static assets** under `static/` are served at the site root; images referenced from Markdown live in `static/images/...` and are linked as `/images/...`.
- **Theme overrides** sit in `layouts/` and shadow same-path files in `themes/hugo-theme-relearn/layouts/`. Custom shortcodes are in `layouts/shortcodes/`: `latest-download.html` (release-driven download table), `image-gallery.html`, `mkd.html` (inline-include another Markdown file), `since.html` / `until.html` / `version.html` (version markers, see below), `badgeC.html`, `svg.html`, `svg-inline.html`. `layouts/partials/custom-header.html` injects the canonical link, Google consent/analytics, the lightbox assets, and the documentation version filter.
- **Deployment** — pushes to `main` trigger `.github/workflows/hugo.yaml`, which builds with Hugo extended (`--gc --minify`) and deploys `public/` to GitHub Pages. `/public` and `resources/` are gitignored build artifacts — never commit them.

## Content style

- **English content (`*.en.md`) is American English** (e.g. _color_, _organization_, _customize_, _-ize_ endings). Normalize British spellings when polishing a page.
- Different sections target different readers — match the register: `profiles/`, `installation/`, and `userguide/gateway/` are for integrators/administrators (config keys, YAML, protocol/DICOM detail, code snippets are appropriate), while the rest of `userguide/` is operator-facing portal documentation (lead with what the user sees and does). Look at neighboring pages before setting the tone or adding front-matter keys.

## Version-aware content

The site follows the same scheme as the Weasis documentation
(`nroduit.github.io`): a rolling window of Karnak versions documented from a
**single content tree** — there is no per-version copy of `content/`.
`data/versions.toml` is the only place the window is declared; the sidebar
selector, the badges and the block filter all derive from it. Today the window
is `2.0` (current; Karnak 2.0.0 is the first release, so there is no older
`supported` entry yet) plus `2.1` as `next`, documented ahead of time. Rolling
the window forward at release time is a two-line edit (the comments in that
file spell out the steps). With a single window entry the selector hides itself.

Mark version differences in Markdown with:

```markdown
Destinations can be paused {{< since "2.1.0" >}}.
The legacy pseudonymization endpoint is available {{< until "2.0.3" >}}.

{{% version since="2.1" %}}
A whole passage — paragraphs, images, tables — that only exists from 2.1 on.
{{% /version %}}
```

- `since` / `until` are **self-contained phrases** ("since v2.1.0"), so write the
  sentence around them without repeating the word: `paused {{< since "2.1.0" >}}`,
  not `paused since {{< since "2.1.0" >}}`. That way the call can later be
  deleted without breaking the sentence. They are the **only** way to mark a
  version: do not use `badgeC` or the theme's `{{% badge title="Version" %}}`
  for that, since neither is filtered. The theme's `badge` shortcode is still
  fine for non-version labels such as `style="info"`.
- A `since` version older than the whole window still renders, but without a
  filter index: the feature is present in every documented version, so the badge
  stays in its ordinary state whatever the reader selects. Nothing is dropped
  when the window rolls forward — pruning a marker that has stopped being
  interesting is an editorial call. Keep it where the version is the
  information (a deployment requirement, an API change); drop it where it is
  just a changelog note with no action attached.
- A `since` version *newer* than the window, and an `until` version older than
  it, are both reported as build warnings: the first means `versions.toml` is
  stale, the second means the sentence applies to no documented version at all.
- Versions are tracked at **minor** granularity (`2.1`); a patch-level argument
  such as `2.1.2` is displayed in full but filters as `2.1`.
- Everything is always rendered into the HTML; the reader's choice only hides
  content client-side (generated CSS keyed on `<html data-docv>`). So there is
  one canonical URL per topic, one search index, and full content with
  JavaScript off. Never use these shortcodes to hide something that must not be
  published.
- A `{{% version %}}` block must **not** contain headings. Hugo does not register
  headings that live inside a shortcode's inner content, so their anchors drop
  out of the fragment registry (breaking internal links, with a build warning)
  and out of the page TOC. Gate a section with an inline `since` badge on its
  first paragraph instead, and keep blocks to prose, lists, tables and images.
- `?v=2.0` in a URL preselects a version — the application's Help links
  (`HelpView` in the Karnak frontend) can use it to send readers to the right
  variant.

When a **whole page** only applies to part of the window, gate it in front
matter instead of wrapping the body:

```toml
since: "2.1.0"   # or: until: "2.0.3"
```

The page then hides its own sidebar entry outside that range and shows a banner
above the title. The page itself is never hidden — someone arriving from a
search engine or an in-app help link must still be able to read it. Use this
only when the whole page is version-specific; a page that merely gained a
section wants a `version` block.

**Other documentation lines.** A version that leaves the window can stay online
as its own build instead of being folded into this one. Add a *line entry* to
`data/versions.toml` — any entry that declares a `url` — with a `branch` and a
state of `maintained` (the previous major, still receiving fixes) or `archived`
(frozen). The "Build other documentation lines" step of
`.github/workflows/hugo.yaml` rebuilds each such branch, with its own content,
layouts and theme commit, into `public/<url>/` on every deploy; nothing is
written back to the repository and no built HTML is committed. Line entries are
never filtered — selecting one in the sidebar navigates to it.

A line build sets `params.docline` and `params.doclinestate`, which make it
`noindex`, point its canonical at the same page on the current line, and show a
banner: "still maintained" for `maintained`, "no longer updated" for `archived`,
which also drops the version selector since the build is frozen.

**At a major release**, snapshot the line rather than annotating across it —
that is the case where most screenshots change at once. Branch the current
content (e.g. `2.x`), reset `data/versions.toml` on `main` to the new major's
window, and add one line entry for the old branch at `/2.x/`. Re-shoot
screenshots **in place**, keeping the same file paths: the branch split is what
versions the images, so no Markdown changes. On the old branch add the
mirror-image entry pointing back at `/`, and point the application's Help links
at the matching path prefix — routing between lines must be a path, never a
query parameter. Within each line, keep using `since` / `until`.

Moving parts: `data/versions.toml`, `layouts/partials/_karnak/*.gotmpl`,
`layouts/partials/docversion-head.html` (generated CSS + selection bootstrap),
`layouts/partials/sidebar/element/docversion.html` (selector, wired through
`sidebarheadermenus` in `config.toml`), `layouts/partials/docversion-page.html`
(page banners, via the `content-header.html` hook), `static/js/doc-version.js`,
the `since` / `until` / `version` shortcodes, and the "Build other documentation
lines" step in `.github/workflows/hugo.yaml`. These files are kept
deliberately close to their Weasis counterparts (`_weasis/` there, `_karnak/`
here) so a fix in one site ports to the other with a rename.

## Editing notes

- `[params.link] errorlevel = 'warning'` in `config.toml` means broken internal links surface as **warnings** during `hugo serve`/build, not failures — watch the dev-server output when changing links. (The content currently has a number of pre-existing broken relative links that show up here.)
- `markup.goldmark.renderer.unsafe = true` is intentional so shortcodes and inline HTML/JS render. `markup.goldmark.parser.attribute.block = true` enables `{ ... }` attribute lists on block elements (headings, images, tables).
- `markup.highlight.guessSyntax = false`: code fences **must** declare a language, otherwise they render unstyled (this is also what keeps mermaid fences working).
- External links open in a new tab via `[params] externalLinkTarget = '_blank'` (don't re-add a custom `_markup/render-link.html` override for this).