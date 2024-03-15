---
title: Bash commands
abstract: Bash (`bash`) commands I frequently use.
date: 2024-02-01
categories: [shell]
---

# Best practices

Start scripts with the following flags:

```bash
set -euo pipefail
set -x
```

1. `set -e`: immediately exit if any command has a non-zero exit code
2. `set -u`: immediately exit if any undefined variables are used
3. `set -o pipefail`: immediately exit if any command in a pipeline
   fails
4. `set -x`: print each command being run with its values
