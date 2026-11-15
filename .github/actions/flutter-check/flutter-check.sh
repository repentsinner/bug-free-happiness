#!/usr/bin/env bash
# Dart and Flutter correctness check (§spec:flutter-correctness).
#
# One implementation for a developer's shell, a project's own CI script and
# the flutter-check action, so a passing local run predicts a passing CI run.
# The script runs whichever `dart` and `flutter` are on PATH; the action
# installs the SDK that `resolve` names before it runs `check`.
#
#   flutter-check.sh [check] [--floor] [--expect CHECK] [PACKAGE...]
#       Resolve dependencies, analyze with infos fatal, check formatting and
#       run the tests in each package directory (default: the current one).
#       Every check runs to completion, then the verdict fails naming each
#       check that failed. --floor runs the floor leg's rules: the analyzer
#       fails on errors and warnings but not infos, and formatting is not
#       checked. --expect is for self-tests: pass, or the one check expected
#       to fail (deps, analyze, format or tests). FLUTTER_CHECK_FLOOR=true
#       and FLUTTER_CHECK_EXPECT set the same defaults from the environment.
#
#   flutter-check.sh resolve [--floor] [--sdk-version VERSION] PACKAGE
#       Print the SDK the package needs as key=value lines: `install` (the
#       SDK to install) and `version`. --floor names the oldest SDK the package's `environment`
#       constraint admits: `flutter` for a Flutter package, `sdk` otherwise.
set -euo pipefail

checks=(deps analyze format tests)

die() {
  echo "::error::$*" >&2
  exit 1
}

usage() {
  echo "usage: flutter-check.sh [check] [--floor] [--expect CHECK] [PACKAGE...]" >&2
  echo "       flutter-check.sh resolve [--floor] [--sdk-version VERSION] PACKAGE" >&2
  exit 2
}

# The Flutter toolchain when any dependency is the Flutter SDK
# (`sdk: flutter`), the Dart toolchain otherwise.
toolchain_of() {
  if grep -Eq "^[[:space:]]+sdk:[[:space:]]*[\"']?flutter[\"']?[[:space:]]*(#.*)?$" "$1/pubspec.yaml"; then
    echo flutter
  else
    echo dart
  fi
}

# Only an exact release pins anything: a channel or a partial version moves
# under the project the day a release lands.
is_release() {
  [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# One key of pubspec.yaml's top-level `environment` map, unquoted.
environment_of() {
  awk -v key="$2" '
    /^environment:/ { inside = 1; next }
    inside && /^[^[:space:]#]/ { exit }
    inside && $1 == key ":" {
      sub(/^[^:]*:[[:space:]]*/, ""); sub(/[[:space:]]+#.*$/, ""); gsub(/["\047]/, "")
      print; exit
    }' "$1/pubspec.yaml"
}

# The oldest release a constraint admits: ^X.Y.Z, >=X.Y.Z with or without an
# upper bound, or an exact X.Y.Z. A prerelease suffix admits prereleases of
# that version; the oldest release it admits is still X.Y.Z.
lower_bound() {
  local re='^(\^|>=)?[[:space:]]*([0-9]+\.[0-9]+(\.[0-9]+)?)(-[0-9A-Za-z.]+)?([[:space:]]*<[^<>]*)?$'
  [[ $1 =~ $re ]] || return 1
  local version=${BASH_REMATCH[2]}
  [[ $version == *.*.* ]] || version=$version.0
  echo "$version"
}

# The nearest .fvmrc from the package up to the repository root, as fvm
# itself finds it, so a monorepo's single root pin covers every package.
find_fvmrc() {
  local dir top
  dir=$(cd "$1" && pwd -P)
  top=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || echo "$dir")
  while :; do
    if [ -f "$dir/.fvmrc" ]; then
      echo "$dir/.fvmrc"
      return
    fi
    if [ "$dir" = "$top" ] || [ "$dir" = / ]; then
      return
    fi
    dir=$(dirname "$dir")
  done
}

resolve() {
  local sdk_version="" floor=${FLUTTER_CHECK_FLOOR:-false} package
  while [ $# -gt 0 ]; do
    case "$1" in
      --floor) floor=true; shift ;;
      --sdk-version) sdk_version=${2-}; shift 2 ;;
      -*) usage ;;
      *) break ;;
    esac
  done
  [ $# -eq 1 ] || usage
  package=$1
  [ -f "$package/pubspec.yaml" ] || die "$package has no pubspec.yaml"

  local toolchain install version pin fvmrc
  toolchain=$(toolchain_of "$package")
  if [ "$floor" = true ]; then
    # A Flutter package's floor is a Flutter release, which bundles the Dart
    # it runs, so its constraint is environment.flutter, not environment.sdk.
    local key=sdk constraint
    [ "$toolchain" = flutter ] && key=flutter
    constraint=$(environment_of "$package" "$key")
    [ -n "$constraint" ] || die "$package/pubspec.yaml has no environment.$key, so the floor leg has no oldest SDK to run"
    version=$(lower_bound "$constraint") ||
      die "$package/pubspec.yaml environment.$key is '$constraint', which names no oldest release such as ^3.4.0 or >=3.4.0"
    install=$toolchain
    pin="environment.$key, the floor"
  else
    fvmrc=$(find_fvmrc "$package")
    # .fvmrc names a Flutter release, and Flutter bundles Dart, so a Dart
    # package pinned there runs the dart of that Flutter release: the one its
    # developer runs through fvm.
    if [ -n "$fvmrc" ]; then
      install=flutter
      pin=$fvmrc
      version=$(sed -n 's/.*"flutter"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$fvmrc" | head -n 1)
      is_release "$version" || die "$fvmrc names Flutter '$version', not a release such as 3.50.0"
    elif [ -n "$sdk_version" ]; then
      install=$toolchain
      pin=sdk-version
      version=$sdk_version
      is_release "$version" || die "sdk-version is '$version', not a release such as 3.50.0"
    else
      die "$package has no SDK pin: add a .fvmrc naming a Flutter release, or set sdk-version"
    fi
  fi

  echo "$package: $install $version from $pin, $toolchain toolchain" >&2
  echo "install=$install"
  echo "version=$version"
}

# Runs one check from the package directory and records its outcome.
run_check() {
  local name=$1
  shift
  echo "::group::$name: $*"
  if (cd "$package" && "$@"); then
    outcome[$name]=pass
  else
    outcome[$name]=fail
  fi
  echo "::endgroup::"
  echo "$name: ${outcome[$name]}"
}

# The outcome --expect asks of one check. Analysis and tests cannot run
# without resolved dependencies, so they are skipped when resolution fails,
# and the floor leg skips formatting.
wanted() {
  local check=$1
  if [ "$floor" = true ] && [ "$check" = format ]; then
    echo skip
  elif [ "$check" = "$expect" ]; then
    echo fail
  elif [ "$expect" = deps ] && { [ "$check" = analyze ] || [ "$check" = tests ]; }; then
    echo skip
  else
    echo pass
  fi
}

check_package() {
  package=$1
  [ -f "$package/pubspec.yaml" ] || die "$package has no pubspec.yaml"

  local tool leg=pinned analyze=(--fatal-infos)
  tool=$(toolchain_of "$package")
  # Lint rules and formatter output change between SDK releases, so on the
  # floor leg they report the tools' differences, not the code's defects.
  if [ "$floor" = true ]; then
    leg=floor
    analyze=(--fatal-warnings)
    [ "$tool" = flutter ] && analyze+=(--no-fatal-infos)
  fi
  echo "== $package: $tool toolchain, $leg leg"
  "$tool" --version

  outcome=([analyze]=skip [format]=skip [tests]=skip)
  run_check deps "$tool" pub get
  if [ "${outcome[deps]}" = pass ]; then
    run_check analyze "$tool" analyze "${analyze[@]}"
  fi
  if [ "$floor" = false ]; then
    run_check format dart format --output=none --set-exit-if-changed .
  fi
  if [ "${outcome[deps]}" = pass ]; then
    run_check tests "$tool" test
  fi

  local check failed=() want
  for check in "${checks[@]}"; do
    [ "${outcome[$check]}" = fail ] && failed+=("$check")
    if [ "$expect" != pass ]; then
      want=$(wanted "$check")
      echo "$check: ${outcome[$check]} (expected $want)"
      [ "${outcome[$check]}" = "$want" ] || mismatches=$((mismatches + 1))
    fi
  done
  if [ "$expect" = pass ] && [ ${#failed[@]} -gt 0 ]; then
    local IFS=,
    echo "::error::$package ($leg leg): failed checks: ${failed[*]}"
    mismatches=$((mismatches + 1))
  fi
}

check() {
  expect=${FLUTTER_CHECK_EXPECT:-pass}
  floor=${FLUTTER_CHECK_FLOOR:-false}
  while [ $# -gt 0 ]; do
    case "$1" in
      --floor) floor=true; shift ;;
      --expect) expect=${2-}; shift 2 ;;
      -*) usage ;;
      *) break ;;
    esac
  done
  case "$expect" in
    pass | deps | analyze | format | tests) ;;
    *) die "--expect must be pass, deps, analyze, format or tests, not '$expect'" ;;
  esac
  if [ "$floor" = true ] && [ "$expect" = format ]; then
    die "--expect format cannot match: the floor leg does not check formatting"
  fi
  [ $# -gt 0 ] || set -- .

  declare -gA outcome
  mismatches=0
  for package in "$@"; do
    check_package "$package"
  done
  [ "$mismatches" -eq 0 ]
}

case "${1-}" in
  resolve) shift; resolve "$@" ;;
  check) shift; check "$@" ;;
  -h | --help) usage ;;
  *) check "$@" ;;
esac
