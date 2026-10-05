#!/bin/sh
# The job: confirm the Brewfile is satisfied (`brew bundle check`) and that what it
# installed actually runs. Exits 0 when every check passes.
set -u
here=$(cd "$(dirname "$0")/.." && pwd)
export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_ENV_HINTS=1

fail=0
ok()  { echo "ok   $1"; }
bad() { echo "FAIL $1"; fail=1; }

command -v brew >/dev/null || { echo "FAIL brew not on PATH"; exit 1; }
echo "$(brew --version | head -1) at $(brew --prefix)"

if brew bundle check --verbose --file="$here/Brewfile"; then ok "brew bundle check: Brewfile satisfied"
else bad "brew bundle check: Brewfile NOT satisfied"; fi

for f in $(brew bundle list --formula --file="$here/Brewfile"); do
  brew list --versions "$f" >/dev/null && ok "installed: $(brew list --versions "$f")" || bad "not installed: $f"
done

out=$(hello 2>&1) && [ "$out" = "Hello, world!" ] && ok "hello runs: $out" || bad "hello: $out"
out=$(tree --version 2>&1) && ok "tree runs: $out" || bad "tree: $out"

[ $fail -eq 0 ] && echo PASS || echo FAILED
exit $fail
