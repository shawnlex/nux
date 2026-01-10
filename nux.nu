# Example nux.nu demonstrating all nux features

use std/log

########################################################
# Basic targets
########################################################

# Build the project
export def build [] {
    log debug "debug msg (visible with nux -d)"
    print "building..."
}

# Run tests with optional filter
export def test [
    # arg with ? is optional with a default value of null
    pattern?: string,  # filter pattern (optional, default to '*' set inside the cmd)
    # flag without default value defaults to false
    --verbose(-v),     # show verbose output
] {
    { pattern: ($pattern | default '*'), verbose: $verbose } | to json | print
}

# Echo all arguments (variadic via --wrapped)
export def --wrapped echo [...args] {
    { arg_num: ($args | length), args: $args } | to json | print
}

# Count words from stdin: echo "hello world" | nux -s wc
export def word-count [] { str stats }

export alias wc = word-count

########################################################
# Namespaced targets (dev)
########################################################

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

# Run tests in watch mode
export def "dev test" [
    # explicitly set default value to true
    --watch(-w) = true,  # enable watch mode
] {
    { watch: $watch } | to json | print
}

export alias dt = dev test

########################################################
# Import module as namespace: nux math add 1 2
########################################################

export use math.nu
