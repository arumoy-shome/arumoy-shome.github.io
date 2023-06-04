---
title: Research Workflow
date: 2021-06-03
abstract: |
    An outline of my research workflow which I have developed to
    handle the non-linear nature of scientific work.
---

Here I outline a workflow which I have developed to handle the
non-linear nature of scientific research. There are days when one
reads several papers without making much sense of them. However,
a single paper the next day can result in a clear picture of the
domain. The workflow acknowledges the fact that there are many more
failures rather than successes in research. However, a failure is
still an outcome---and this is what helps us decide what to do
next---so it should still be recorded.

Research workflows are highly personal. If you decide to adopt any or
all ideas I present here, it may require some tweaking so that it
works for you. Years of performing an extrinsic search for existing
solutions was unfruitful. Instead, I simply started reading papers and
let the process develop organically. Soon I noticed some common
patterns and standardisation which allowed me to automate some aspects
of the process.

There are 3 interdependent phases to this process described below.

# Finding papers

I save the bibtex entry in a bib file (generally in the project root
along with the other latex files). This is because the bibtex-mode in
Emacs provides powerful search options, templates for adding entries,
sorting entries, cleaning up, and much more. Besides, the bib files
ultimately gets used in the report so it makes sense to group the two
together and keep them in the same location.

::: {.callout-note title="UPDATE 2021-06-15 Tue"}

I no longer save bibtex entry in a bib file. Instead, I store them
with my notes in the same org file in source code blocks. I use
org-tangle to generate the bib file when needed.

:::

First, I use good ol' Google Scholar (along with a plugin to enable my
institution's proxy) to find papers. Once, I find a paper I open it
and read the abstract. If the abstract appeals to my current research
focus or is interesting to me in general, I download it and save it in
a folder which syncs across my devices. Next, I grab the bibtex entry
and create a task using org-capture where I save the bibtex entry, one
liner on why I found the paper interesting. I add the location to the
pdf on disk, I set the title of the task as the bibtex entry and
I save it to my *inbox* (or relevant project org file).

::: {.callout-note title="UPDATE 2021-06-15 Tue"}

I have written an Elisp package that automates all of this. With the
bibtex entry in my clipboard, I now issue an org-capture template
which creates a new task with the bibkey as the header, adds relevant
properties such as *first author* *last author* and *source* of
publication, and sticks the bibtex entry in a source block (see
[aocp.el](https://github.com/arumoy-shome/aocp.el)).

:::

In [scientific paper discovery](../scientific-paper-discovery)
I describe my process of finding relevant papers in more detail.

# Reading papers

I read the papers on my laptop. My screen is usually split 50-50
between Emacs (where I take notes) and a pdf viewer. I do not make any
highlights because its easy to abuse and it ties the information to
the pdf viewer application that I am using.

Instead, I take notes in plain text (as of 2020, I have been using
org-mode, an Emacs major mode to do so). There are several, rationales
for doing this digitally. First, I require these notes to be
searchable and link-able to other notes. Second, research projects
often span for a long duration. Having digital notes ensures that I do
not have notes distributed amongst several analog
papers/journals. Lastly, I take notes on papers in a specific
manner. These notes have a specific purpose - and thus a carefully
constructed structure as described in the next section - and thus come
under the category of *hard* information (I talk more about
productivity and how I categorise information in
[productivity](../productivity)).

I use the 3 pass technique as presented by S. Keshav in his paper
titled "How to read a paper" (2007). I employ the first pass as
a screening method to identify if a given paper is worth reading in
full. During the first pass, I read the introduction and conclusion
and briefly glance over the sections of the paper and the
diagrams. The goal here is to determine the problem that the paper is
trying to solve and get a preliminary idea of the proposed solution
and results. Generally, I can determine all the above characteristics
just by the reading the introduction and conclusion if the paper is
well written.

During the second pass, I read the results, discussion and limitation
sections in full. During this phase I {edit, elaborate} my earlier
notes made during first pass and also add my personal remarks
pertaining to the paper. When reading scientific work in detail, it is
often helpful to read at a macro and micro level. For instance, before
reading a section from top to bottom - in a linear sense - I often
find it helpful to first scan the sub-sections and draw a tree diagram
of the topics. This allows me to have a visual representation of the
section which often times is enough to quickly conduct a mental
cost-benefit analysis of reading the section in detail.

I rarely read a paper in it's entirety. I think this is essential when
you peer-review a paper (which I do not do yet as of [2021-06-30 Wed])
but unnecessary for day-to-day scientific work.

# Writing notes

Notes on paper being read will always be in relation to the current
research focus/goal. A paper may be read multiple times but will have
different notes if they were made with reference to different
research questions.

Following this rationale, I store the notes in an org file pertaining
to the project I am working on. I store the pdfs in a central
location, synced with a cloud service provider so as to have offline
access.

And following are the aspects that I look out for when reading papers.

```
+ problem statement :: What is the problem the paper is trying to
  solve? Why is this problem important? Why should I care? This
  generally leads to a good material for the introduction of my
  paper as well.
+ solution :: What is the solution the paper proposes? How is it
  better compared to existing ones (do the authors try to show its
  worth by comparing to existing solutions)? Why should I care about
  it?
+ results :: What were the analytical experiments conducted and what
  were their results? What datasets were used? What models were used
  and how did they perform? How was their performance evaluated?

  Generally, in my field these questions can be answered by reading
  the results section, very rarely are results disclosed in the
  conclusion section. Note that falls out of the 'first pass' content
  so I may come back to this only if I need this information for the
  task at hand.
+ limitations :: Does the paper identify its limitations? what
  future work can be done?
+ remarks :: My personal remarks on the paper. Was it well written? Is
  it scientifically sound? Does it present a good overview of the
  problem it is trying to solve? This critical examination and
  cross-checking is essential when conducting a literature review.
```

After writing down notes on the topics above, I try to write a one
line summary of the paper along with my remarks. These are always
guided by the research question or work at hand.

The *"why should I care?"* flavor questions will generally be guided
by the research question or personal interest that I may have at the
time of reading.

It's worth elaborating on the writing process itself because this in
itself is a highly non-linear and dynamic activity. With regards to my
personal writing, I have noticed that the quantity and quality of
notes are inversely proportional. In the early stages of a project, or
when I am trying to familiarise myself with a new research topic,
I tend to write more notes which are primitive (meaning they emphasise
on the first principles) and are similar to the papers I am reading at
that point in time. However, with exposure to more papers, the notes
become more concise and opinionated (they reflect my thoughts and
ideas on the matter).

I also employ writing on paper and typing in an iterative, cyclic
manner to formulate concise and clear text which express my
discoveries, ideas and opinions.
