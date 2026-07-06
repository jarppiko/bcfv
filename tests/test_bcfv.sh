#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BCFV="${ROOT}/../bcfv"
TMP_ROOT="$(mktemp -d)"
PASS=0
FAIL=0

cleanup() {
    rm -rf "${TMP_ROOT}"
}
trap cleanup EXIT

fail() {
    echo "✗ $1"
    FAIL=$((FAIL + 1))
}

pass() {
    echo "✓ $1"
    PASS=$((PASS + 1))
}

assert_file_exists() {
    local file="$1"
    if [ ! -f "$file" ]; then
        fail "Expected file to exist: $file"
        return 1
    fi
}

assert_file_not_exists() {
    local file="$1"
    if [ -e "$file" ]; then
        fail "Expected file not to exist: $file"
        return 1
    fi
}

assert_grep() {
    local needle="$1"
    local file="$2"
    if ! grep -F -- "$needle" "$file" >/dev/null; then
        fail "Expected '$file' to contain '$needle'"
        return 1
    fi
}

assert_not_grep() {
    local needle="$1"
    local file="$2"
    if grep -F -- "$needle" "$file" >/dev/null; then
        fail "Expected '$file' not to contain '$needle'"
        return 1
    fi
}

run_bcfv() {
    "${BCFV}" "$@"
}

skip_if_missing_bin() {
    local bin="$1"
    if ! command -v "$bin" >/dev/null 2>&1; then
        echo "Skipping tests requiring $bin: not installed"
        exit 0
    fi
}

setup_dir() {
    local name="$1"
    local dir="${TMP_ROOT}/${name}"
    mkdir -p "$dir"
    echo "$dir"
}

write_small_file() {
    local path="$1"
    local content="$2"
    printf '%s' "$content" > "$path"
}

get_checksum_file() {
    local dir="$1"
    local algo="$2"
    printf '%s/%s.%s' "$dir" ".checksum" "$algo"
}

test_create_mode() {
    local testdir
    testdir="$(setup_dir create_mode)"
    write_small_file "${testdir}/a.txt" "alpha"
    write_small_file "${testdir}/b.txt" "bravo"

    run_bcfv -c -a md5 "${testdir}"
    local checksum_file="${testdir}/.checksum.md5"
    assert_file_exists "${checksum_file}" || return 1
    assert_grep "a.txt" "${checksum_file}"
    assert_grep "b.txt" "${checksum_file}"
    pass "create mode writes md5 checksum file"
}

test_update_mode() {
    local testdir
    testdir="$(setup_dir update_mode)"
    write_small_file "${testdir}/one.txt" "first"
    write_small_file "${testdir}/two.txt" "second"

    run_bcfv -c -a md5 "${testdir}"
    local checksum_file="${testdir}/.checksum.md5"
    assert_file_exists "${checksum_file}" || return 1

    local before_one
    local before_two
    before_one="$(grep -F -- 'one.txt' "${checksum_file}")"
    before_two="$(grep -F -- 'two.txt' "${checksum_file}")"

    write_small_file "${testdir}/two.txt" "second-updated"
    run_bcfv -u -a md5 "${testdir}"

    local after_one
    local after_two
    after_one="$(grep -F -- 'one.txt' "${checksum_file}")"
    after_two="$(grep -F -- 'two.txt' "${checksum_file}")"

    if [ "$before_one" != "$after_one" ]; then
        fail "Update mode should preserve unchanged checksum for one.txt"
        return 1
    fi
    if [ "$before_two" = "$after_two" ]; then
        fail "Update mode should refresh changed checksum for two.txt"
        return 1
    fi

    pass "update mode refreshes only changed files"
}

test_check_mode() {
    local testdir
    testdir="$(setup_dir check_mode)"
    write_small_file "${testdir}/check.txt" "verify"
    run_bcfv -c -a md5 "${testdir}"
    if ! run_bcfv -a md5 "${testdir}" >/dev/null; then
        fail "check mode should succeed on valid checksums"
        return 1
    fi
    pass "check mode verifies existing checksums"
}

test_list_mode() {
    local testdir
    testdir="$(setup_dir list_mode)"
    write_small_file "${testdir}/list.txt" "value"
    run_bcfv -c -a md5 "${testdir}"

    local output
    output="$(run_bcfv -l -a md5 "${testdir}")"
    if ! printf '%s' "$output" | grep -F -- 'list.txt' >/dev/null; then
        fail "list mode should print file path entries"
        return 1
    fi
    pass "list mode prints checksums for directory files"
}

test_empty_dir() {
    local testdir
    testdir="$(setup_dir empty_dir)"
    run_bcfv -c -a md5 "${testdir}"
    assert_file_not_exists "${testdir}/.checksum.md5" || return 1
    pass "create mode does not create checksum file for empty directory"
}

test_unicode_and_special_filenames() {
    local testdir
    testdir="$(setup_dir unicode_files)"
    write_small_file "${testdir}/üñîçødé.txt" "one"
    write_small_file "${testdir}/file with spaces.txt" "two"
    write_small_file "${testdir}/special!@#\$%^&*().jpg" "three"

    run_bcfv -c -a md5 "${testdir}"
    local checksum_file="${testdir}/.checksum.md5"
    assert_file_exists "${checksum_file}" || return 1
    assert_grep "üñîçødé.txt" "${checksum_file}"
    assert_grep "file with spaces.txt" "${checksum_file}"
    assert_grep "special!@#\$%^&*().jpg" "${checksum_file}"

    if ! run_bcfv -a md5 "${testdir}" >/dev/null; then
        fail "check mode should work for Unicode and special filenames"
        return 1
    fi
    pass "Unicode and special characters in filenames are handled correctly"
}

test_options() {
    local testdir
    testdir="$(setup_dir options)"
    write_small_file "${testdir}/option.txt" "opt"

    run_bcfv -c -q -a md5 "${testdir}"
    assert_file_exists "${testdir}/.checksum.md5" || return 1

    local base_dir="${TMP_ROOT}/base"
    mkdir -p "${base_dir}/inner"
    write_small_file "${base_dir}/inner/sample.txt" "base"
    run_bcfv -b "${base_dir}" -c -a md5 "inner"
    assert_file_exists "${base_dir}/inner/.checksum.md5" || return 1

    local custom="${TMP_ROOT}/custom"
    mkdir -p "$custom"
    write_small_file "${custom}/custom.txt" "custom"
    CHECKSUM='.sum' run_bcfv -f -c -a md5 "$custom"
    assert_file_exists "${custom}/.sum.md5" || return 1

    pass "command line options -q, -b and -f work as expected"
}

main() {
    skip_if_missing_bin md5sum

    test_create_mode
    test_update_mode
    test_check_mode
    test_list_mode
    test_empty_dir
    test_unicode_and_special_filenames
    test_options

    echo
    echo "${PASS} tests passed, ${FAIL} tests failed"
    if [ "$FAIL" -ne 0 ]; then
        exit 1
    fi
}

main "$@"
