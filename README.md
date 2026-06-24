# eek-a-template

A public [Copier](https://copier.readthedocs.io) template that scaffolds new
**eek-a-dev** project repositories: the two-root `docs/` + `docs-dev/` layout,
agent instruction files (`AGENTS.md` / `CLAUDE.md`), the numbered-prompt
workflow, pre-commit hooks, GitHub Actions CI, and a public-build safety check.

This repository is the **single source of truth** for the project skeleton. It is
public so it can be fetched without authentication from both Claude Code and the
claude.ai code sandbox. The private `eek-a-dev` toolkit owns and maintains this
template; do not fork the skeleton into other tools — delegate to it.

## Use it

Interactively:

```bash
copier copy gh:OWNER/eek-a-template ./my-project
```

Non-interactively (how the `eek-a-dev-scaffold` skill drives it):

```bash
copier copy --defaults --trust \
  --data project_name=my-project \
  --data project_title="My Project" \
  --data description="One-line description." \
  --data stack_kind=node \
  --data "stack=node-vite + typescript" \
  --data visibility=public \
  --data static_site=true \
  gh:OWNER/eek-a-template ./my-project
```

`--trust` is required because the template may run tasks; this template defines
none, but copier still asks. `--defaults` accepts the seeded defaults for any
`--data` you omit.

## Pull later template improvements into an existing project

Because each generated project carries a `.copier-answers.yml`, you can re-apply
template changes without losing local edits:

```bash
copier update --trust
```

## Questions the template asks

| Variable | Meaning | Default |
|---|---|---|
| `project_name` | repo name (lowercase, GitHub-style) | — (validated) |
| `project_title` | human title | derived from `project_name` |
| `description` | one-line description (seeds README + overview) | — |
| `stack_kind` | `node` / `static-html` / `python` / `r` / `android` / `other` | `node` |
| `stack` | free-text stack description | derived from `stack_kind` |
| `visibility` | `public` / `private` | `public` |
| `static_site` | publishes a static site? | true for node / static-html |
| `allow_private_static` | confirm a paid plan / external host (only asked on conflict) | false |
| `language_locale` | locale convention | British English … |
| `workflow_policy` | commit/branch/push policy | commit-to-`main` |
| `verify_command` | verify command | `npm run check` for node, else blank |
| `testing_policy` | testing policy | no tests unless asked |
| `license` | `none` / `MIT` | `none` |
| `author`, `year` | MIT copyright fields (only asked when licensing) | — |
| `jdk_version` | JDK major version (Android only) | `17` |
| `android_compile_sdk` | compileSdk API level (Android only) | `37` |
| `android_target_sdk` | targetSdk API level (Android only) | `36` |
| `android_min_sdk` | minSdk API level (Android only) | `24` |
| `android_package` | application id / package (Android only) | derived from `project_name` |

### Guard: private + static site

GitHub Pages will not serve a private repository on GitHub Free. If
`visibility=private` and `static_site=true`, copier asks `allow_private_static`
and **refuses** unless you confirm a paid plan or an external host. Resolve by
making the repo public, using a paid plan, hosting on Netlify/Cloudflare/Vercel,
or keeping it private with no live site.

### Android: build the APK in CI, download, sideload

Select the stack with `--data stack_kind=android`. The Android stack ships a
complete, buildable project — Kotlin, Jetpack Compose with Material 3, a single
`app` module, Kotlin-DSL build scripts, a Gradle version catalogue, and a
**committed** Gradle wrapper (jar included, `gradlew` executable). Platform
levels and the JDK are template variables (`android_compile_sdk`,
`android_target_sdk`, `android_min_sdk`, `jdk_version`) with current-stable
defaults; library and plugin versions live in the version catalogue
(`gradle/libs.versions.toml`).

The phone is not used for compilation. The generated `Build APK` workflow builds
a **debug** APK on a GitHub-hosted runner (Android SDK preinstalled; no secrets,
no signing) and uploads it as the `app-debug` artefact. The loop is: push →
CI builds → download the artefact from the run → sideload. Release signing and
store distribution are deferred to a later, separately scoped prompt.

## What the template does not do

It produces the framework only. It does **not** scaffold stack-specific source
(e.g. `npm create vite`), create the GitHub repo, or build features. The
`eek-a-dev-scaffold` skill handles those judgement steps after running the
template; per-stack guidance lives in that skill's `references/stack-presets.md`.
The **Android** stack is the exception: because its build runs in CI straight
from the generated tree, the template ships the complete buildable project
rather than deferring the scaffold.

## Publishing this template

```bash
git init && git add -A && git commit -m "eek-a-template"
git tag v0.1.0                       # copier resolves to the latest tag by default
gh repo create eek-a-template --public --source . --push --remote origin
git push --tags
```

Tag a new release whenever you change the skeleton so projects can `copier update`
to a known version.

## Layout

```
eek-a-template/
├── copier.yml          # questions, computed values, conventions, conflict guard
├── README.md           # this file (not copied into generated projects)
└── template/           # the rendered project tree (_subdirectory)
    ├── .copier-answers.yml.jinja
    ├── AGENTS.md.jinja                 # conventions block filled from answers
    ├── README.md.jinja                 # stack-aware
    ├── CLAUDE.md
    ├── .gitignore, .pre-commit-config.yaml
    ├── .github/workflows/
    │   ├── check-build.yml
    │   └── {% raw %}{% if static_site %}deploy-pages.yml{% endif %}{% endraw %}
    ├── docs/                           # user-facing
    ├── docs-dev/                       # internal: agent guides, prompts, reference, planning
    ├── scripts/                        # validate-prompts, check-public-build, new-prompt
    └── {% raw %}{% if license == 'MIT' %}LICENSE{% endif %}{% endraw %}.jinja
```
