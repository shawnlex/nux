# Test nux features with nux itself

use std/log
use std/assert

export def test [] {
    test-nux-help
    test-target-help
    test-target-help-detailed
    
    test-args-flags
    test-echo-parsing
    test-debug-flag

    test-module-as-target-file
    test-errors
}

const default_nux_file = 'nux.nu'
# main nux.nu file in parent dir, which is run and tested by this test, aka. self_nux_file
const main_dir = path self '..'
const main_nux_file = $main_dir | path join $default_nux_file

# the test nux.nu file, launched to test the main nux.nu file
const test_nux_file = path self 

# test: help for nux itself
export def test-nux-help [] {
    test-start "nux help"

    let regular_help_patterns = [$main_nux_file, "Usage:", "Targets:", "Aliases:", "[dev]", "[math]"]
    let nux_flags_pattern = ["Nux Flags:", "--target-file", "--interactive", "--list", "--debug", "--stdin"]

    def verify-help [--regular-help(-r) = true] {
        let stdout = $in.stdout | ansi strip
        for pattern in $regular_help_patterns {
            assert-match $pattern $stdout --invert (not $regular_help)
        }
        for pattern in $nux_flags_pattern {
            assert-match $pattern $stdout --invert $regular_help
        }
    }

    run-main-nux | verify-help
    run-main-nux-explicit | verify-help
    run-main-nux help | verify-help
    run-main-nux-explicit help | verify-help

    run-main-nux -H | verify-help -r false
    run-main-nux --nux-help | verify-help -r false
    run-main-nux-explicit -H | verify-help -r false

    test-pass
}

# test: help with nux targets search
export def test-target-help [] {
    test-start "target help"

    def verify-help [patterns: list, non_patterns: list = []] {
        let stdout = $in.stdout 
        for pattern in $patterns {
            assert-match $pattern $stdout
        }
        for non_pattern in $non_patterns {
            assert-match $non_pattern $stdout --invert true
        }
    }

    def target-names []  {
        $in | each {|item| $" ($item) - " }
    }

    # sub cmds under [dev] namespace
    let dev_patterns = [
        "[dev]",
        ...(["dev serve", "dev test"] | target-names),
    ] 
    let dev_non_patterns = ["math", "Aliases:"]
    run-main-nux dev | (verify-help $dev_patterns $dev_non_patterns)
    run-main-nux help dev | (verify-help $dev_patterns $dev_non_patterns)

    # cmds from math.nu module
    let math_patterns = [
        "[math]",
        ...(["math add", "math mul", "math power"] | target-names),
        "math pow -> power",
        "Aliases:",
    ]
    let math_non_patterns = ["dev", "build", "test", "echo"] | target-names
    run-main-nux math | (verify-help $math_patterns $math_non_patterns)
    run-main-nux help math | (verify-help $math_patterns $math_non_patterns)

    test-pass
}

# test: exact, detailed target help
export def test-target-help-detailed [] {
    test-start "target help detailed"
    let expected_patterns = ["Run tests with optional filter", "Usage:", "-v, --verbose", "Parameters:", "pattern <string>:"]
    def verify [] {
        let stdout = $in.stdout
        for pattern in $expected_patterns {
            assert-match $pattern $stdout
        }
    }
    run-main-nux test -h | verify
    run-main-nux test --help | verify

    test-pass
}

# test: args and flags parsing 
export def test-args-flags [] {
    test-start "args and flags"

    run-main-nux test | assert-json { pattern: '*', verbose: false }
    run-main-nux test "my-pattern" | assert-json { pattern: 'my-pattern', verbose: false }
    run-main-nux test --verbose | assert-json { pattern: '*', verbose: true }
    run-main-nux test "custom" -v | assert-json { pattern: 'custom', verbose: true }

    run-main-nux dev serve "localhost" | assert-json { host: 'localhost', port: 8080 }
    run-main-nux dev serve "0.0.0.0" --port 3000 | assert-json { host: '0.0.0.0', port: 3000 }

    run-main-nux dev test | assert-json { watch: true }
    run-main-nux dev test --watch=false | assert-json { watch: false }

    test-pass
}

export def test-echo-parsing [] {
    test-start "echo parsing"

    def verify [expected: list] {
        $in | assert-json { arg_num: ($expected | length), args: $expected }
    }

    run-main-nux echo a b c | verify [a, b, c]
    run-main-nux echo "hello world" foo | verify ["hello world", foo]
    run-main-nux echo "one two" "three four" | verify ["one two", "three four"]
    run-main-nux echo 'has"quote' "has'single" | verify ['has"quote', "has'single"]
    run-main-nux echo "key=value" --not-a-flag | verify ["key=value", "--not-a-flag"]
    run-main-nux echo --flag a msg | verify ['--flag', 'a', 'msg']

    test-pass
}

# test: --debug/-d flag enables log debug output
export def test-debug-flag [] {
    test-start "debug flag"

    let debug_pattern = "debug msg"
    assert-match $debug_pattern (run-main-nux build | get stderr) --invert true
    assert-match $debug_pattern (run-main-nux --debug build | get stderr)
    assert-match $debug_pattern (run-main-nux -d build | get stderr)

    test-pass
}

# test: module as target file
export def test-module-as-target-file [] {
    test-start "module as target"

    let cases = [
        [args, output];
        [[add 3 4], "7"]
        [[mul 3 4], "12"]
        [[power 3 4], "81"]
        [[pow 3 4], "81"]
    ]

    for case in $cases {
        run-main-nux math ...$case.args | assert-text $case.output
        run-main-nux-explicit -t ./math.nu ...$case.args | assert-text $case.output
    }

    test-pass
}

# test: error cases
export def test-errors [] {
    test-start "errors"

    run-main-nux dev serve | assert-error "missing_positional"
    run-main-nux math add foo bar | assert-error "parse_mismatch"
    run-main-nux dev serve localhost --port abc | assert-error "parse_mismatch"
    run-main-nux test --unknown-flag | assert-error "unknown_flag"
    run-main-nux build extra | assert-error "extra_positional"
    run-main-nux-explicit -t ./nonexistent.nu build | assert-error "module_not_found"
    run-main-nux dev serve localhost --port 80 | assert-error "invalid port.*must be >= 100"

    test-pass
}

########################################################
# Test runners
########################################################

def run-main-nux --wrapped [...args] {
    cd $main_dir
    log debug $"run-main-nux: nux ($args)"
    nux ...$args | complete | sanitize-output
}

def run-main-nux-explicit --wrapped [--target-file(-t): string = $default_nux_file, ...args] {
    cd $main_dir
    log debug $"run-main-nux-explicit: nux -t ($target_file) ($args)"
    nux -t $target_file ...$args | complete | sanitize-output
}

def sanitize-output [] {
    $in | update stdout { |it| $it.stdout | ansi strip } | update stderr { |it| $it.stderr | ansi strip }
}

########################################################
# Test progress UI
########################################################

def test-start [name: string] {
    log info $"testing ($name)"
}

def test-pass [] {
    print $"✅"
}

def dot [] {
    print -n "."
}

########################################################
# Assertions (each prints a dot on success)
########################################################

# Assert output (stdout or stderr) contains/matches pattern
def assert-match [
    pattern: string,
    output: string,
    --invert = false,
    --regex(-r),
] {
    if $regex {
        if $invert {
            assert ($output !~ $pattern) $"should not match regex: ($pattern)\noutput:\n($output)"
        } else {
            assert ($output =~ $pattern) $"should match regex: ($pattern)\noutput:\n($output)"
        }
    } else {
        if $invert {
            assert not ($output | str contains $pattern) $"should not contain: ($pattern)\noutput:\n($output)"
        } else {
            assert ($output | str contains $pattern) $"should contain: ($pattern)\noutput:\n($output)"
        }
    }
    dot
}

# Assert piped result.stdout parses as expected JSON
def assert-json [expected: record] {
    let parsed = $in.stdout | str trim | from json
    assert equal $parsed $expected $"expected ($expected | to json) but got ($parsed | to json)"
    dot
}

# Assert piped result.stdout equals expected text
def assert-text [expected: string] {
    let actual = $in.stdout | str trim
    assert equal $actual $expected $"expected '($expected)' but got '($actual)'"
    dot
}

# Assert piped result has non-zero exit and output matches error pattern
def assert-error [error_pattern: string] {
    let result = $in
    assert ($result.exit_code != 0) $"expected non-zero exit code, got ($result.exit_code)"
    let combined = $"($result.stdout)\n($result.stderr)"
    assert ($combined =~ $error_pattern) $"expected error matching '($error_pattern)' in:\n($combined)"
    dot
}