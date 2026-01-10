# Reusable math module
# Also works as standalone target file: nux -t math.nu add 1 2

# Add two numbers
export def add [
    a: number,  # first number
    b: number,  # second number
] { $a + $b }

# Multiply two numbers
export def mul [
    a: number,  # first number
    b: number,  # second number
] { $a * $b }

# Raise base to exponent
export def power [
    base: number,  # base number
    exp: number,   # exponent
] { $base ** $exp }

# Alias for power
export alias pow = power
