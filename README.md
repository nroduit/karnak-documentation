# Karnak Documentation Website

[![Hugo](https://img.shields.io/badge/Built%20with-Hugo-FF4088?logo=hugo)](https://gohugo.io/)
[![Theme](https://img.shields.io/badge/Theme-Relearn-blue)](https://github.com/McShelby/hugo-theme-relearn)
[![Deploy](https://github.com/nroduit/karnak-documentation/actions/workflows/hugo.yaml/badge.svg)](https://github.com/nroduit/karnak-documentation/actions/workflows/hugo.yaml)
[![License](https://img.shields.io/github/license/nroduit/karnak-documentation)](LICENSE)

Source of the **[Karnak documentation website](https://karnak.weasis.org/)**: installation, de-identification profiles, gateway configuration and user guides for the [Karnak](https://github.com/nroduit/karnak) DICOM gateway.

The site is a static [Hugo](https://gohugo.io/) site built on the [Relearn](https://github.com/McShelby/hugo-theme-relearn) theme. All content is Markdown; there is no application code.

---

## 🚀 Getting started

### Prerequisites

- [Git](https://git-scm.com/)
- [Hugo **extended**](https://gohugo.io/installation/) — the extended build is required (the theme needs Dart Sass). CI builds with Hugo `0.165.0`; use the same version to reproduce its output.

### 1. Clone the repository with its theme

The theme is a git submodule, so clone with submodules:

```shell
git clone --recurse-submodules https://github.com/nroduit/karnak-documentation.git
cd karnak-documentation
```

If the repository is already cloned without submodules:

```shell
git submodule update --init --recursive
```

### 2. Run the development server

```shell
hugo serve
```

The site is served at [http://localhost:1313/en/](http://localhost:1313/en/) and reloads on every change. Keep an eye on the terminal: broken internal links are reported there as warnings, not as build failures.

### 3. Build for production

```shell
hugo --gc --minify
```

This is the exact command CI runs. The output lands in `public/`, which is ignored by git together with `resources/`; never commit either.

### Optional: the download table

The portable-download table (`{{< latest-download >}}` on the *Portable distribution* page) reads the GitHub Releases API at build time and needs a token in the `HUGO_GH_TOKEN` environment variable:

- **unset** — the table shows an inline error and the rest of the site builds normally. Fine for everyday editing.
- **set to a valid personal access token** — the table is rendered.
- **set but invalid** — the whole build fails. Unset the variable rather than leaving a stale token in place.

CI provides its own token from a repository secret.

### Updating the theme

The theme is pinned to a commit. To move it to the latest upstream, pull inside the submodule and commit the new pointer:

```shell
cd themes/hugo-theme-relearn
git pull origin main
cd ../..
git add themes/hugo-theme-relearn
```

Rebuild the site afterwards; theme updates occasionally change layout partials that this repository overrides.

---

## 📁 Project structure

| Path | Description |
|------|-------------|
| `content/` | Markdown sources, one file per page (`page.en.md`), section landing pages named `_index.en.md` |
| `content/installation/` | Deploying and running Karnak (Docker Compose, logs) |
| `content/profiles/` | Authoring de-identification and tag-morphing profiles (YAML, conditions, expressions, masks, dates, API) |
| `content/userguide/` | The web portal, with a `gateway/` subsection for DICOM sources and destinations |
| `static/` | Files served as-is from the site root; images live in `static/images/` and are referenced as `/images/...` |
| `layouts/` | Overrides of theme partials and the custom shortcodes (`latest-download`, `image-gallery`, `since` / `until` / `version`, …) |
| `assets/` | Theme customizations (CSS variables, light/dark overrides) |
| `data/versions.toml` | The list of Karnak releases the site documents (see below) |
| `themes/hugo-theme-relearn/` | The Relearn theme, as a git submodule |
| `config.toml` | Site configuration |
| `.github/workflows/hugo.yaml` | Build and deployment to GitHub Pages |

---

## ✍️ Writing conventions

- **Language.** English pages use the `.en.md` suffix and American English spelling (*color*, *customize*, *organization*). French is declared in the configuration but mostly untranslated; new pages are written in English.
- **Audience.** `installation/`, `profiles/` and `userguide/gateway/` address integrators and administrators: configuration keys, YAML, DICOM detail and code snippets belong there. The rest of `userguide/` is written for portal operators: lead with what the user sees and does. Read a neighboring page before setting the tone.
- **Code fences must declare a language** (` ```yaml `, ` ```shell `, ` ```json `). Fences without one render unstyled; this is what keeps Mermaid diagrams working.
- **Links.** External links open in a new tab automatically. Internal links are relative to the page; the development server warns about broken ones.
- **Images** go in `static/images/`. Screenshots open in a lightbox when clicked, so they can be displayed at a reduced size.
- **Version-specific facts** are marked with the shortcodes described in the next section, never with a plain badge.

---

## 🏷️ Documenting Karnak versions

The site can document **several Karnak releases from one set of pages**. There is no copy of `content/` per version: pages state which release a given behavior belongs to, and readers filter the page to their own version.

Karnak 2.0.0 is the first release, so the window in `data/versions.toml` currently holds just the current release, `2.0`, and the upcoming `2.1`, documented ahead of time as a preview.

### What the reader gets

A **version selector** sits in the sidebar under the search box, defaulting to the current stable release. Picking another version adapts the page:

- facts that arrived later are flagged **"not in your version"** in red;
- passages and pages describing features absent from that release are hidden, and a page opened directly still shows its content above a banner explaining why;
- the choice is remembered, and `?v=2.0` in a URL preselects a version, which is how an in-app **Help** link can land a reader on the right variant.

Filtering happens **in the browser only**. Every version's content is always present in the HTML, so search engines, printouts and readers without JavaScript see the complete page. Never use these markers to keep something unpublished.

### The version window

`data/versions.toml` lists the releases the site documents, oldest first. Versions are tracked at **minor** granularity (`2.1`, not `2.1.3`); patch-level detail lives in the badge text.

| state | meaning |
|-------|---------|
| `supported` | an older release still documented |
| `current` | the latest stable release, the selector's default |
| `next` | the upcoming release, documented ahead of time |
| `maintained` / `archived` | a separate documentation line, published at its own URL |

### Marking a version in a page

Pick the mode that matches the *scope* of what changed:

| What is version-specific | Mode | In range | Out of range |
|--------------------------|------|----------|--------------|
| a fact inside a sentence | `{{< since "2.1.0" >}}` / `{{< until "2.0.3" >}}` | blue / amber badge reading *since v2.1.0* or *until v2.0.3* | red dashed badge prefixed with **×** |
| a passage (paragraphs, lists, tables, images) | `{{% version since="2.1" %}}` … `{{% /version %}}` (also `until=`) | shown | hidden |
| an entire page | `since: "2.1.0"` or `until: "2.0.3"` in the front matter | normal page | dropped from the sidebar; opened directly it still shows its content, above a banner naming the release it needs |

```markdown
Destinations can be paused {{< since "2.1.0" >}} from the gateway page.

{{% version until="2.0" %}}
In 2.0 the destination had to be deleted instead.
{{% /version %}}
```

### Rules worth knowing

1. **A badge is a whole phrase.** `{{< since "2.1.0" >}}` renders *"since v2.1.0"*, so write `paused {{< since "2.1.0" >}}`, never `paused since {{< since "2.1.0" >}}`. The marker can then be deleted later without leaving a broken sentence.
2. **Patch versions are fine in the text.** `{{< since "2.1.2" >}}` displays the full version but filters as `2.1`.
3. **A version older than the window still renders** and simply never turns red: the feature is present in every documented release. Keep the badge where the version *is* the information (a deployment requirement, an API change); drop it where it is a changelog note nobody can act on.
4. **A `version` block must not contain headings.** Hugo does not register headings inside a shortcode, so their anchors and table-of-contents entries disappear. Mark such a section with an inline badge on its first paragraph instead.
5. **Shortcodes do not run inside code blocks.** Put the note on a line below the block.
6. **Watch the build.** A `since` newer than the window, or an `until` older than it, is reported as a warning: the first means `versions.toml` is stale, the second that the sentence applies to no documented release.

### When a release ships

Roll the window forward in `data/versions.toml`: `next` becomes `current`, the old `current` becomes `supported`, add the new `next`, and drop the oldest entry. The comments in that file spell this out, including how to keep an old release online as an archived line. At a **major** release the whole line is branched instead; see the notes in `data/versions.toml` and `CLAUDE.md`.

---

## 🚢 Deployment

Every push to `main` runs `.github/workflows/hugo.yaml`, which builds the site with Hugo extended (`hugo --gc --minify`) and publishes `public/` to GitHub Pages at [karnak.weasis.org](https://karnak.weasis.org/). The workflow can also be started by hand from the *Actions* tab. Any documentation line declared in `data/versions.toml` with a `branch` and a `url` is rebuilt from that branch during the same run.

---

## 🤝 Contributing

Contributions are welcome. To propose a change:

1. Fork the repository and create a branch.
2. Add or edit Markdown files under `content/`, following the conventions above.
3. Preview with `hugo serve` and check the terminal for new warnings.
4. Open a pull request against `main`.

Every published page has an **Edit this page** link that opens the matching file on GitHub, which is the quickest route for small fixes.

## 📚 Useful links

- [Karnak project](https://github.com/nroduit/karnak) and its [releases](https://github.com/nroduit/karnak/releases)
- [Karnak Docker image](https://hub.docker.com/r/nroduit/karnak)
- [Weasis](https://weasis.org/), the DICOM viewer from the same project
- [Hugo documentation](https://gohugo.io/documentation/)
- [Relearn theme documentation](https://mcshelby.github.io/hugo-theme-relearn/)
