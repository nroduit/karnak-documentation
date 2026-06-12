# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Source for the **[Karnak documentation site](https://osirix-foundation.github.io/karnak-documentation/)** — the docs for the [Karnak](https://github.com/OsiriX-Foundation/karnak) DICOM gateway (de-identification + DICOM attribute normalization). It is a Hugo static site using the [Relearn theme](https://github.com/McShelby/hugo-theme-relearn), pulled in as a git submodule at `themes/hugo-theme-relearn`. Content is authored in Markdown; there is no application code.

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
- **Theme overrides** sit in `layouts/` and shadow same-path files in `themes/hugo-theme-relearn/layouts/`. Custom shortcodes are in `layouts/shortcodes/`: `latest-download.html` (release-driven download table), `image-gallery.html`, `mkd.html` (inline-include another Markdown file), `badgeC.html`, `svg.html`, `svg-inline.html`. `layouts/partials/custom-header.html` injects the canonical link, Google consent/analytics, and the lightbox assets.
- **Deployment** — pushes to `main` trigger `.github/workflows/hugo.yaml`, which builds with Hugo extended (`--gc --minify`) and deploys `public/` to GitHub Pages. `/public` and `resources/` are gitignored build artifacts — never commit them.

## Content style

- **English content (`*.en.md`) is American English** (e.g. _color_, _organization_, _customize_, _-ize_ endings). Normalize British spellings when polishing a page.
- Different sections target different readers — match the register: `profiles/`, `installation/`, and `userguide/gateway/` are for integrators/administrators (config keys, YAML, protocol/DICOM detail, code snippets are appropriate), while the rest of `userguide/` is operator-facing portal documentation (lead with what the user sees and does). Look at neighboring pages before setting the tone or adding front-matter keys.

## Editing notes

- `[params.link] errorlevel = 'warning'` in `config.toml` means broken internal links surface as **warnings** during `hugo serve`/build, not failures — watch the dev-server output when changing links. (The content currently has a number of pre-existing broken relative links that show up here.)
- `markup.goldmark.renderer.unsafe = true` is intentional so shortcodes and inline HTML/JS render. `markup.goldmark.parser.attribute.block = true` enables `{ ... }` attribute lists on block elements (headings, images, tables).
- `markup.highlight.guessSyntax = false`: code fences **must** declare a language, otherwise they render unstyled (this is also what keeps mermaid fences working).
- External links open in a new tab via `[params] externalLinkTarget = '_blank'` (don't re-add a custom `_markup/render-link.html` override for this).