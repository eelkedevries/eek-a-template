#!/usr/bin/env bash
# Structural check for a generated Android project tree.
#
# Asserts that the Android stack rendered a buildable-looking project: the
# committed Gradle wrapper is present, gradlew is executable, the app module and
# key sources exist, no unrendered Copier/Jinja markers remain, and the Node CI
# did not leak in. This is the cheap half of the toolkit's Android validation;
# the end-to-end half (an actual `assembleDebug`) runs in CI.
#
# Usage: scripts/validate-generated.sh <generated-project-dir>
set -euo pipefail

DIR="${1:?usage: validate-generated.sh <generated-project-dir>}"
fail=0
ok()   { printf 'ok    %s\n' "$*"; }
bad()  { printf 'FAIL  %s\n' "$*"; fail=1; }

require_file() { if [[ -f "$DIR/$1" ]]; then ok "$1"; else bad "missing $1"; fi; }

echo "Validating generated Android project: $DIR"

require_file "settings.gradle.kts"
require_file "build.gradle.kts"
require_file "gradle.properties"
require_file "gradlew"
require_file "gradlew.bat"
require_file "gradle/wrapper/gradle-wrapper.jar"
require_file "gradle/wrapper/gradle-wrapper.properties"
require_file "gradle/libs.versions.toml"
require_file "app/build.gradle.kts"
require_file "app/src/main/AndroidManifest.xml"
require_file "app/src/main/kotlin/MainActivity.kt"
require_file "app/src/main/kotlin/ui/theme/Theme.kt"
require_file "app/src/main/res/values/strings.xml"

# The wrapper jar must be committed, non-empty, and gradlew executable.
if [[ -s "$DIR/gradle/wrapper/gradle-wrapper.jar" ]]; then ok "wrapper jar is non-empty"; else bad "wrapper jar missing or empty"; fi
if [[ -x "$DIR/gradlew" ]]; then ok "gradlew is executable"; else bad "gradlew is not executable"; fi

# No unrendered template markers in any authored text file. A Jinja `{{` not
# preceded by `$` or a `{%` statement signals an unrendered marker; GitHub
# Actions `${{ ... }}` expressions are legitimate and excluded by the lookbehind.
markers="$(grep -RIlP --include='*.kt' --include='*.kts' --include='*.xml' \
  --include='*.toml' --include='*.md' --include='*.yml' --include='*.properties' \
  -e '(?<!\$)\{\{' -e '\{%' "$DIR" 2>/dev/null || true)"
if [[ -n "$markers" ]]; then
  bad "unrendered template markers found in:"; printf '%s\n' "$markers"
else
  ok "no unrendered template markers"
fi

# The Android stack must get build-apk.yml and must NOT inherit the Node CI.
if [[ -f "$DIR/.github/workflows/build-apk.yml" ]]; then ok "build-apk.yml present"; else bad "missing build-apk.yml"; fi
if [[ -e "$DIR/.github/workflows/check-build.yml" ]]; then bad "Node check-build.yml leaked into Android project"; else ok "no Node check-build.yml"; fi

if [[ "$fail" -ne 0 ]]; then echo "STRUCTURAL CHECK FAILED"; exit 1; fi
echo "STRUCTURAL CHECK PASSED"
