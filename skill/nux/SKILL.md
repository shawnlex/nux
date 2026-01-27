---
name: nux
description: Task runner powered by Nushell. Use when working with nux.nu files, creating or running targets, or when the user mentions nux, Nushell tasks, or task runners in Nushell projects.
license: MIT
metadata:
  author: shawnlex
  version: "0.0.1"
compatibility: Requires nushell (nu) in PATH
---

# Nux - Nushell Task Runner

Nux executes exported functions (targets) from `nux.nu` files.

## Prerequisites

Before using nux, check that prerequisites are installed:

### Check Installation

```sh
which nu    # Check if Nushell is installed
which nux   # Check if nux is installed
```

### Installing Nushell (required)

If `nu` is not found, prompt the user to install Nushell first:

- **macOS**: `brew install nushell`
- **Windows**: `winget install nushell`
- **Linux**: See https://www.nushell.sh/book/installation.html

### Installing nux

If `nu` is available but `nux` is not found, offer the user these options:

1. **One-liner install (recommended)** - automatically prompts for PATH directory:
   ```sh
   nu -c 'def install [] { let p = mktemp; http get https://raw.githubusercontent.com/shawnlex/nux/refs/heads/main/nux | save -f $p; chmod +x $p; try { nu $p --install }; rm $p; }; install'
   ```

2. **Manual download + interactive install**:
   ```sh
   curl -o nux https://raw.githubusercontent.com/shawnlex/nux/main/nux
   nu ./nux --install
   ```

3. **Manual download + copy to PATH** (if user knows their preferred bin directory):
   ```sh
   curl -o ~/.local/bin/nux https://raw.githubusercontent.com/shawnlex/nux/main/nux
   chmod +x ~/.local/bin/nux
   ```

After installation, verify with `nux -v`.

## Core Concepts

- **Targets**: Exported functions in `nux.nu` run via `nux <target>`
- **Target file**: Default is `nux.nu`, change with `-t` flag
- **Namespaced targets**: Functions like `dev serve` called as `nux dev serve` (no quotes)

## Running Targets

```sh
nux                                    # list all available targets
nux <target> [args...] [flags...]      # run a target
nux build                              # run "build" target
nux dev serve localhost --port 3000    # namespaced target with args/flags
nux -t ./other.nu mytarget             # use different target file
```

## Getting Help

```sh
nux                     # list all targets with descriptions
nux help <keyword>      # filter targets by keyword
nux <target> -h         # detailed help for a target
nux -H                  # show nux flags
```

## Nux Flags (must come BEFORE target name)

| Flag | Description |
|------|-------------|
| `-t, --target-file <file>` | Use specific target file (default: `nux.nu`) |
| `-l, --list` | List all targets (compact) |
| `-i, --interactive` | Start nushell session after running target |
| `-d, --debug` | Enable debug logging |
| `-n, --dry-run` | Show commands without executing |
| `-s, --stdin` | Pass stdin to target |
| `-H, --nux-help` | Show nux flags |
| `-v, --version` | Show nux version |

## Writing Targets in nux.nu

### Basic Target

```nushell
# Build the project
export def build [] {
    print "building..."
}
```

### Target with Arguments and Flags

```nushell
# Run tests with optional filter
export def test [
    pattern?: string,      # optional argument
    --verbose(-v),         # boolean flag
] {
    print $"Running tests with pattern: ($pattern | default '*')"
}
```

### Typed Flags with Defaults

```nushell
# Start development server
export def "dev serve" [
    host: string,              # required argument
    --port(-p): int = 8080,    # flag with default value
] {
    print $"Serving on ($host):($port)"
}
```

### Variadic Arguments

```nushell
# Echo all arguments
export def --wrapped echo [...args] {
    print $args
}
```

### Namespaced Targets

```nushell
# Creates: nux dev serve, nux dev test
export def "dev serve" [] { ... }
export def "dev test" [] { ... }
```

### Aliases

```nushell
export alias wc = word-count
export alias dt = dev test
```

### Stdin Support

```nushell
# Usage: echo "hello" | nux -s word-count
export def word-count [] { str stats }
```

### Importing Modules

```nushell
# Creates namespaced targets: nux math add, nux math mul
export use math.nu
```

## Interactive Mode

Use `nux -i` to drop into a Nushell session with targets loaded:

```sh
nux -i              # start session with targets available
nux -i build        # run build, then stay in session
```

## File Discovery

Nux searches for `nux.nu` upward from the current directory, similar to how npm finds `package.json`.

## Best Practices

1. Use descriptive comments above targets - they become help text
2. Group related targets with namespaces (e.g., `dev serve`, `dev test`)
3. Use typed arguments and flags for better error messages
4. Use `-n` (dry-run) to preview commands before execution
5. Use `-i` (interactive) for iterative development and debugging
