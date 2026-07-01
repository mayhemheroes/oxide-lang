#!/usr/bin/env bash
#
# mayhem/build.sh — build oxide-lang's fuzz targets as sanitized binaries
# (OSS-Fuzz Rust path: ASan via RUSTFLAGS + -Zbuild-std so std is instrumented too),
# plus the project's own test suite (normal flags) so mayhem/test.sh only RUNS it.
#
# Two targets:
#   * parse  — libFuzzer harness over the lexer+parser (mayhem/fuzz crate, cargo-fuzz),
#              via the crate's public, non-diverging API.
#   * oxide  — the FULL pipeline (lex -> parse -> interpret), run as a FILE-INPUT
#              target (`/mayhem/oxide @@`). Faithful successor to the original
#              `/oxide @@` Mayhem target. Built from the ADDITIVE mayhem/oxide-runner
#              crate (upstream oxide-cli untouched): it drives the public Engine and
#              bakes __asan_default_options=detect_leaks=0. A file-input binary (not a
#              libfuzzer-sys harness) because the interpreter reports language errors
#              via process::exit(1) — clean exits, not crashes — whereas libfuzzer-sys
#              aborts on any panic, turning every expected language error into a false
#              crash.
#
# Runs inside the commit image (RUST mayhem/Dockerfile) as `mayhem` in /mayhem.
# Rust toolchain + cargo registry live at $CARGO_HOME=/opt/toolchains/rust/cargo.
#
# AIR-GAPPED CONTRACT (SPEC §6.5): the PATCH tier re-runs THIS script OFFLINE, resolving
# crates from the $CARGO_HOME registry this first (online) build populates. Do NOT put
# --offline here (the rlenv runtime sets CARGO_NET_OFFLINE=true for the re-run).
set -euo pipefail

# clang rejects SOURCE_DATE_EPOCH='' — must be unset or a valid integer.
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH

: "${MAYHEM_JOBS:=$(nproc)}"
export CARGO_BUILD_JOBS="$MAYHEM_JOBS"

cd "$SRC"

# Debug-info contract (SPEC §6.2 item 10): Mayhem triage cannot read DWARF >= 4, and
# LLVM default -Cdebuginfo emits DWARF-5, so pin DWARF < 4 explicitly. Overridable via
# $RUST_DEBUG_FLAGS (the rust arm of the DEBUG_FLAGS contract verify-repo checks).
export RUST_DEBUG_FLAGS="${RUST_DEBUG_FLAGS:--Cdebuginfo=1 -Zdwarf-version=3}"

# Honor the $SANITIZER_FLAGS contract (SPEC §6.1): rustc ignores the clang-oriented
# $SANITIZER_FLAGS, so we map the ASan intent to the rustc sanitizer flag. ASan is the
# default halting sanitizer; an explicit empty SANITIZER_FLAGS still keeps ASan here.
SANITIZER_FLAGS="${SANITIZER_FLAGS:-}"
RUST_SANITIZER="-Zsanitizer=address"
case "$SANITIZER_FLAGS" in
  *address*|"") RUST_SANITIZER="-Zsanitizer=address" ;;
esac

# OSS-Fuzz Rust libFuzzer+ASan flags. --cfg fuzzing matches libfuzzer-sys;
# force-frame-pointers aids ASan backtraces.
export RUSTFLAGS="${RUSTFLAGS:-} --cfg fuzzing ${RUST_SANITIZER} ${RUST_DEBUG_FLAGS} -Cforce-frame-pointers"

# libfuzzer-sys compiles its C++ runtime shim via the cc crate; clang defaults to
# DWARF-5. -Zdwarf-version only governs Rust CUs, so pin the C/C++ objects to DWARF-3
# too (the cc crate honors CFLAGS/CXXFLAGS).
export CFLAGS="${CFLAGS:-} -gdwarf-3"
export CXXFLAGS="${CXXFLAGS:-} -gdwarf-3"

FUZZ_DIR="mayhem/fuzz"
TRIPLE="x86_64-unknown-linux-gnu"

# The rustc nightly ships PRECOMPILED ASan/std runtime archives whose compiler-rt CUs
# carry DWARF-5; those CUs would land (emitted first) in the linked binary and fail the
# DWARF < 4 gate. Triage needs no runtime debug symbols — strip debug info from them
# (writable: the Dockerfile chowned /opt/toolchains/rust to 2000).
for _rt in $(find /opt/toolchains/rust -name 'librustc-*_rt.asan.a' 2>/dev/null); do
  echo "stripping DWARF-5 debug info from runtime archive: $_rt"
  objcopy --strip-debug "$_rt" "$_rt.tmp" && mv "$_rt.tmp" "$_rt"
done

# Clean prior fuzz/runner target trees so every crate recompiles with our DWARF-3
# flags (a cached artifact would keep DWARF-5). Fast; harmless on the offline re-run.
rm -rf "$SRC/$FUZZ_DIR/target" "$SRC/mayhem/oxide-runner/target"

# ── libFuzzer targets from the additive fuzz crate ────────────────────────────
FUZZ_TARGETS=()
for f in "$FUZZ_DIR"/fuzz_targets/*.rs; do
  FUZZ_TARGETS+=("$(basename "${f%.*}")")
done
[ "${#FUZZ_TARGETS[@]}" -gt 0 ] || { echo "ERROR: no fuzz targets under $FUZZ_DIR/fuzz_targets/" >&2; exit 1; }

echo "=== cargo fuzz build (image nightly, ASan via RUSTFLAGS) ==="
echo "RUSTFLAGS=$RUSTFLAGS"
echo "libfuzzer targets: ${FUZZ_TARGETS[*]}"

for t in "${FUZZ_TARGETS[@]}"; do
  echo "--- building fuzz target: $t ---"
  cargo fuzz build --fuzz-dir "$FUZZ_DIR" -O --debug-assertions "$t"
  bin="$SRC/$FUZZ_DIR/target/$TRIPLE/release/$t"
  [ -x "$bin" ] || { echo "ERROR: expected fuzz binary not found at $bin" >&2; exit 1; }
  cp "$bin" "/mayhem/$t"
  echo "built /mayhem/$t"
done

# ── the full-pipeline file-input target: additive mayhem/oxide-runner crate ────
# Build std WITH the sanitizer (-Zbuild-std) so the whole binary — including std —
# is ASan-instrumented, matching the cargo-fuzz binaries.
echo "=== cargo build (oxide-runner, ASan, DWARF-3, -Zbuild-std) ==="
( cd "$SRC/mayhem/oxide-runner"
  # Force debug info into the release binary (the DWARF < 4 gate requires a
  # .debug_info section); -Cstrip=none keeps it from being stripped at link.
  CARGO_PROFILE_RELEASE_DEBUG=1 \
  RUSTFLAGS="$RUSTFLAGS -Cstrip=none" \
  cargo build --release -Z build-std --target "$TRIPLE" -j "$MAYHEM_JOBS" )
cli_bin="$SRC/mayhem/oxide-runner/target/$TRIPLE/release/oxide"
[ -x "$cli_bin" ] || { echo "ERROR: oxide runner binary not found at $cli_bin" >&2; exit 1; }
cp "$cli_bin" /mayhem/oxide
echo "built /mayhem/oxide"

# ── the project's own TEST suite (NORMAL flags) so mayhem/test.sh only RUNS it ──
echo "=== cargo test --no-run (normal flags) ==="
env -u RUSTFLAGS -u CFLAGS -u CXXFLAGS cargo test --no-run -p oxide-interpreter -j "$MAYHEM_JOBS"

echo "build.sh complete"
