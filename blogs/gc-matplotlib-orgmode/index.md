---
title: Garbage Collection for Matplotlib in org-mode
date: 2021-01-05
abstract: Notes on managing memory when using org-mode and python to conduct data science analysis.
categories: [python, emacs]
---

I was experiencing random crashes when using emacs and orgmode as a replacement for jupyter notebooks. Turns out that matplotlib does not clear the memory automatically after every plot. So after a few plots, the python interpreter running inside emacs was using a lot of memory and causing emacs to crash. The solution seems to be manual memory management. The solution proposed by [this stack overflow comment](https://stackoverflow.com/a/59762314) seems to be manual memory release followed by garbage collection.

The process is a bit more involved when using seaborn as it interacts with matplotlib internally. For axes level figures, we can pass an `axes` object to seaborn. In essense, we have control over the `matplotlib.pyplot` object so we can use the solution proposed above.  For figure level objects however, seaborn returns a `PairGrid` or `FacetGrid` object. We can however access the underlying axes and figure from this object and call their corresponding `clear()` function.

::: {.callout-note title="2021-10-08"}
I was assigning the same variable to the various plots so I don't understand why it was accumulating so much memory. Another alternative is to execute each plot in a separate python process. This can be done by writing individual methods to perform a certain transformation or visualisation. If we execute the entire file as a script, we can invoke all methods, or import the module and pick-and-choose what to do.

The problem may be specific to Emacs because it's built to edit text after all. With the python process running inside Emacs, it may be panicking when it sees a 1GB 'file' and crashing cause it thinks it is using too much memory. So perhaps even Jupyter was using so much memory but since there is no limit to how much memory it can use (and my laptop has plenty of memory to give) I didn't observe this problem. Regardless, I think the solution proposed above will help.
:::

::: {.callout-note title="2021-10-15"}
When using seaborn axes level methods, it's best to pass the matplotlib Axes object ourselves (using `matplotlib.pylot.subplots`) so that we can manually clear the memory using the solution provided in the stack overflow post. When using figure level methods, seaborn returns a `FacetGrid` object which has the `axes` & `fig` attributes which give us to the underlying matplotlib axes and figure objects respectively. We can call the `clear` method on them to clear the memory.
:::