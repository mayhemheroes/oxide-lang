#!/usr/bin/env bash
#
# mayhem/test.sh — RUN oxide-lang's own functional test suite (already compiled by
# mayhem/build.sh via `cargo test --no-run`). These are golden-output tests: each
# runs an .ox script through the interpreter and asserts stdout == the recorded
# .output file (see oxide-interpreter/tests/common/mod.rs::compare_output). A no-op
# / exit(0) PATCH breaks the asserted output and FAILS here.
#
# Emits a CTRF summary (file + `CTRF {...}` stdout marker); exit non-zero iff failed>0.
set -uo pipefail
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH
: "${MAYHEM_JOBS:=$(nproc)}"
cd "$SRC"

emit_ctrf() {
  local tool="$1" passed="$2" failed="$3" skipped="${4:-0}" pending="${5:-0}" other="${6:-0}"
  local tests=$(( passed + failed + skipped + pending + other ))
  cat > "${CTRF_REPORT:-$SRC/ctrf-report.json}" <<JSON
{
  "results": {
    "tool": { "name": "$tool" },
    "summary": {
      "tests": $tests,
      "passed": $passed,
      "failed": $failed,
      "pending": $pending,
      "skipped": $skipped,
      "other": $other
    }
  }
}
JSON
  printf 'CTRF {"results":{"tool":{"name":"%s"},"summary":{"tests":%d,"passed":%d,"failed":%d,"pending":%d,"skipped":%d,"other":%d}}}\n' \
    "$tool" "$tests" "$passed" "$failed" "$pending" "$skipped" "$other"
  [ "$failed" -eq 0 ]
}

# RUN the pre-built suite (build.sh already compiled it with --no-run; this reuses
# those artifacts and must not recompile). Golden-output tests read relative paths,
# so cargo runs each test binary with CWD at the package root — do not cd elsewhere.
LOG="$(mktemp)"
env -u RUSTFLAGS cargo test -p oxide-interpreter -j "$MAYHEM_JOBS" 2>&1 | tee "$LOG" || true

# Sum "test result: ok. <P> passed; <F> failed; ... <I> ignored;" lines across the
# suite's several test binaries (examples.rs, syntax.rs, ...).
passed=0; failed=0; skipped=0
while read -r p f i; do
  passed=$(( passed + p ))
  failed=$(( failed + f ))
  skipped=$(( skipped + i ))
done < <(grep -E '^test result:' "$LOG" \
          | sed -E 's/^test result: [a-zA-Z]+\. ([0-9]+) passed; ([0-9]+) failed;( ([0-9]+) ignored;)?.*/\1 \2 \4/' \
          | awk '{print $1, $2, ($3==""?0:$3)}')

# A build that produced no test binaries (or a runner that never printed a result
# line) is a build.sh bug — fail loudly rather than reporting a vacuous pass.
if [ "$(( passed + failed + skipped ))" -eq 0 ]; then
  echo "ERROR: no 'test result:' lines — test suite did not run (build.sh should have compiled it)" >&2
  rm -f "$LOG"
  emit_ctrf "cargo-test" 0 1 0
  exit 1
fi

rm -f "$LOG"
emit_ctrf "cargo-test" "$passed" "$failed" "$skipped"
