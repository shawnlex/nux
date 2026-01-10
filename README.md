# nux

Nux: Nushell Executor — a task runner powered by [Nushell](https://www.nushell.sh/)

## Installation

Requires: [nushell](https://www.nushell.sh/) (`nu`) in PATH.

```sh
brew install nushell
```

**One-liner install:**

```sh
nu -c 'def install [] { let p = mktemp; http get https://raw.githubusercontent.com/shawnlex/nux/refs/heads/main/nux | save -f $p; chmod +x $p; try { nu $p --install }; rm $p; }; install'
```

This fetches nux, then prompts you to select a directory from your PATH.

**Manual install:**

```sh
# Download nux
curl -o nux https://raw.githubusercontent.com/shawnlex/nux/main/nux

# Option 1: Interactive install (prompts for PATH directory)
nu ./nux --install

# Option 2: Manual copy
# Assume ~/.local/bin is in $PATH
cp nux ~/.local/bin/ && chmod +x ~/.local/bin/nux
```

**Upgrade:**

```sh
nux -u https://raw.githubusercontent.com/shawnlex/nux/main/nux
```

## Quick Start

Create a `nux.nu` file in your project root (see [nux.nu](./nux.nu) for a complete example):

```nushell
# Build the project
export def build [] {
    print "building..."
}
```

Run targets:

```sh
nux              # show all available targets
nux build        # run the "build" target
nux dev test     # run namespaced target. do not add quotes
nux dt           # run an alias, eg dt -> dev test
```

## Usage

### Running Targets

```sh
nux <target> [args...] [flags...]
nux build
nux test "my-pattern" --verbose
nux dev serve localhost --port 3000
```

### Target Help

```sh
nux                     # list all targets with descriptions
nux help <keyword>      # filter targets by keyword (e.g., nux help dev)
nux <target> -h         # show detailed help for a target
nux <target> --help     # same as above
```

### Nux Flags

Nux flags must come **before** the target name:

```sh
nux [nux-flags] <target> [target-args...]
```

| Flag                       | Description                                  |
| -------------------------- | -------------------------------------------- |
| `-t, --target-file <file>` | Use specific target file (default: `nux.nu`) |
| `-l, --list`               | List all targets (compact)                   |
| `-i, --interactive`        | Start nushell session after running target   |
| `-d, --debug`              | Enable debug logging                         |
| `-n, --dry-run`            | Show commands without executing              |
| `-s, --stdin`              | Pass stdin to target                         |
| `-H, --nux-help`           | Show nux flags                               |
| `-v, --version`            | Show nux version                             |
| `--install`                | Install nux to a PATH directory              |
| `-u, --upgrade-url <url>`  | Upgrade nux from URL                         |

Examples:

```sh
nux -l                         # compact target list
nux -t ./math.nu add 3 4       # use different target file
nux -n build                   # dry-run: show what would execute
nux -i build                   # run build, then drop into nushell session
echo "hello world" | nux -s wc # pipe stdin to target
```

## Interactive Nu Session

Use `nux -i` to drop into a nushell session with all your targets loaded as commands:

```sh
nux -i              # start session with targets available
nux -i build        # run build, then stay in session
```

**Why interactive mode?**

In non-interactive mode, each `nux` invocation spawns a new process. Interactive mode keeps you in a single nushell session where targets become native commands—you can pipe, filter, and compose them with nushell's full power.

**Example: Analyze files with `nux word-count`**

```sh
$ nux -i
# Now in nushell with targets loaded as commands

# List files, run word-count on each, add filename, sort by lines descending
> ls | where type == 'file'
  | each { |f| open $f.name | nux word-count | insert file $f.name }
  | sort-by lines -r

╭───┬───────┬───────┬───────┬───────┬───────────┬───────────────┬───────────╮
│ # │ lines │ words │ bytes │ chars │ graphemes │ unicode-width │   file    │
├───┼───────┼───────┼───────┼───────┼───────────┼───────────────┼───────────┤
│ 0 │   320 │  1237 │ 11247 │ 11247 │     11247 │         11247 │ nux       │
│ 1 │   261 │   865 │  7325 │  6857 │      6857 │          6857 │ README.md │
│ 2 │    64 │   200 │  1800 │  1800 │      1800 │          1800 │ nux.nu    │
│ 3 │    24 │   199 │  1211 │  1211 │      1211 │          1211 │ LICENSE   │
│ 4 │    23 │    70 │   489 │   489 │       489 │           489 │ math.nu   │
╰───┴───────┴───────┴───────┴───────┴───────────┴───────────────┴───────────╯

# Or use math targets directly
> 1..5 | each { nux math power 2 $in }
╭───┬────╮
│ 0 │  2 │
│ 1 │  4 │
│ 2 │  8 │
│ 3 │ 16 │
│ 4 │ 32 │
╰───┴────╯
```

This workflow is impossible with non-interactive mode—you'd need separate `nux` calls for each file, losing the ability to stream and transform data in a single pipeline.

## Writing Targets

See [nux.nu](./nux.nu) for a complete example demonstrating all features.

### Basic Target

```nushell
# Build the project
export def build [] {
    log debug "debug msg (visible with nux -d)"
    print "building..."
}
```

### Arguments and Flags

```nushell
# Run tests with optional filter
export def test [
    # arg with ? is optional with a default value of null
    pattern?: string,  # filter pattern (optional, default to '*' set inside the cmd)
    # flag without default value defaults to false
    --verbose(-v),     # show verbose output
] {
    { pattern: ($pattern | default '*'), verbose: $verbose } | to json | print
}
```

```sh
nux test                    # pattern='*', verbose=false
nux test "my-pattern"       # pattern='my-pattern', verbose=false
nux test --verbose          # pattern='*', verbose=true
nux test "custom" -v        # pattern='custom', verbose=true
```

### Typed Flags with Defaults

```nushell
# Start development server
export def "dev serve" [
    host:string, # mandatory arg
    --port(-p): int = 8080,  # port number (must be >= 100)
] {
    if $port < 100 {
        error make { msg: $"invalid port ($port): must be >= 100" }
    }
    { host: $host, port: $port } | to json | print
}
```

```sh
nux dev serve localhost             # port=8080 (default)
nux dev serve 0.0.0.0 --port 3000   # port=3000
nux dev serve localhost --port 80   # error: must be >= 100
```

### Variadic Arguments

Use `--wrapped` for commands that accept arbitrary args/flags:

```nushell
# Echo all arguments (variadic via --wrapped)
export def --wrapped echo [...args] {
    { arg_num: ($args | length), args: $args } | to json | print
}
```

```sh
nux echo a b c                    # args: [a, b, c]
nux echo "hello world" foo        # args: ["hello world", foo]
nux echo --flag value             # args: [--flag, value]
```

### Namespaced Targets

Group related targets with space-separated names:

```nushell
# Start development server
export def "dev serve" [host:string, --port(-p): int = 8080] { ... }

# Run tests in watch mode
export def "dev test" [--watch(-w) = true] { ... }
```

Run with: `nux dev serve localhost`, `nux dev test`

### Aliases

```nushell
export alias wc = word-count
export alias dt = dev test
```

### Stdin Support

```nushell
# Count words from stdin: echo "hello world" | nux -s wc
export def word-count [] { str stats }
```

### Importing Modules

Import other nushell modules as namespaced targets (see [math.nu](./math.nu)):

```nushell
# Creates: nux math add, nux math mul, nux math power, nux math pow
export use math.nu
```

The imported module can also be used standalone:

```sh
nux -t ./math.nu add 3 4    # outputs: 7
nux -t ./math.nu pow 2 10   # outputs: 1024
```

## Project Structure

```
project/
├── nux.nu          # main target file (auto-discovered)
├── math.nu         # optional: importable module
└── tests/
    └── nux.nu      # test targets
```

Nux searches for `nux.nu` upward from the current directory.

## Development

Run tests:

```sh
nux -t ./tests/nux.nu test
# or
cd tests && nux test
```

## License

ISC
