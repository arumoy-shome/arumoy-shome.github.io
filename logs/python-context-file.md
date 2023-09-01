---
title: Python context file
date: 2020-07-01
abstract: Python context file for managing imports.
categories: [python]
---

Stolen from The Hitchhiker's Guide to Python[^hitchhiker], I use a
`context.py` file to import python source code located in another
directory. This is especially useful for importing source code into
test files (which are typically located under the `test/` directory
for me) and for ipython notebooks (which are typically located under
the `notebooks` directory for me).

Stick the following snippet in a `context.py` file in the directory
where the source code is required to be imported.

```{.python filename="context.py"}
import os
import sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

import sample
```

And in the file where the module need to be imported, stick the
following.

```{.python filename="your-python-file.py"}
from .context import sample
```

[^hitchhiker]: https://docs.python-guide.org/writing/structure/
