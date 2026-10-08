
---
title: ESEM 2026 Paper Presentation
date: 2026-10-09
author: Arumoy Shome
abstract: |
    Transcript of my paper presentation at ESEM 2026, Munich Germany.
---

This is a Jupyter notebook.
It has its roots in the literate programming paradigm,
which was introduced by Knuth 4 decades ago.
Although it was meant to be a general programming paradigm,
it seems to have found its place amongst the Data and AI community.

When you are developing an ML model,
you typically start by developing a prototype.
This is an iterative and exploratory process,
and a notebook works really well with this workflow.
You can write code in logical chunks inside _cells_,
execute them,
analyze the results,
and decide how to proceed forward with the analysis.

---

Once you have an ML prototype ready inside your notebook,
you need to migrate it into a script
so that it can be tested
and deployed within your production system.

When we look at the existing literature in this research area,
we find a lot of diverse perspectives.
There are papers that highlight the collaboration challenges
within heterogeneous development teams
comprising of data scientists and software engineers.
There are papers from the HCI community
that look at the interaction between humans and notebooks.
We have papers that show the software and code quality concerns
that arise when you program in this style.
And we have papers that focus on the post-deployment challenges,
and some that propose metrics
to measure the production readiness of your ML prototypes.

---

A few weeks ago I presented our paper at ICSME in Benevento
which focused on this tiny, but (in my opinion) significant gap
between this transition.
What is the actual workflow?
What are practitioners doing
to make this transition possible?

---

An overarching observation
across several engineering changes that we found in this study,
is that the human is deeply integrated within the execution loop of the notebook.
Each cell is a potential checkpoint
where the human judges the output
and decides what to do next.
There is a cost associated with the oversight that the human provides,
which only becomes visible
when the human is removed from the execution loop,
when we are ready to move from notebooks to scripts.

The primary construct of this study
is this new form of technical debt,
incurred from the interactive workflow provided by notebook.
We define this as *oversight debt*.

---

The next logical thing to ask is
how do you measure oversight debt?
Because then we can investigate
which stages of the pipeline incurs oversight debt,
and we can start thinking about how to repay it.

---

To answer that question,
let me take you back three years ago
when I first started looking into notebooks and this topic.
I was just beginning my PhD pilgrimage
so I was still a baby researcher.

---

During this time
I wrote two short papers
to develop this research idea further.
And there are two things that came out of this endeavour that I am happy about.
First, is this opening line in this paper
where I wrote "Visualizations are the bread and butter of a data scientist" (that is a good line).
And second, is this beautiful slide (those are visualizations that I mined from the notebooks).

On a more serious note,
I was really fascinated with visualizations in ML notebooks
and wanted to investigate them in depth.

---

I had all sorts of crazy ideas,
like I wanted to automatically generate tests (or assertions) from a visualization.
And of course I wanted  to do that using LLMs.
I had this over engineered data collection pipeline,
and I was way too deep trying to create the training set
by trying to find ways to link visualizations with assertions written inside notebooks.

But this one idea started to materialize.
Which is that there are two distinct types of validation happening in notebooks.
We have implicit expectations that are manually checked using visualizations and output of cells,
and there are explicit checks written using assertions.

---

Eventually Diomidis became a part of this project,
and he said "wait a minute, these are feedback statements"
(and I was a baby researcher no more).

---

Which brings us to today, to this paper.
What is a feedback statement?
We define them as code statements that practitioners **intentionally** write in notebooks
to gain insights into the execution cycle of a program.

---

We start by asking what the intent behind the statements are?
What do practitioners hope to learn or explore with the statements?
If the type of feedback varies by the source of the notebook?
Which stages of the development pipeline do they occur?
And how do they map to known crash modes in ML notebooks.

---

We start by mining public Jupyter notebooks in Python from GH and KG.
We extract feedback statements from the notebooks.
We cluster them based on semantic similarity,
and use stratified proportional sampling to get a representative population.
We use grounded theory to manually analyze the statements.

---

The outcome of RQ1 is a taxonomy of feedback statements.
The taxonomy has validation and exploratory statements
that are divided into several sub-types.

---

For RQ2 and RQ3 we conducted a series of hypothesis tests.
In the interest of time I am only sharing some of the findings
but if you are interested you can find the details in the paper.

We find that feedback is overwhelmingly exploratory.
85% of the statements are exploratory while 15% are validation.
Also note that of these 15% only 4 statements were found in KG.

The upstream stages of the pipeline contain more feedback
and practitioners author validation statements in the downstream stages
(We will come back to this observation later).

---

We also map our taxonomy of validation statements
with the taxonomy of crashes that occur in Jupyter notebooks.
We find an overlap between a significant portion of the crashes and validation statements.
More interestingly, we find that VAL-APPROX type of validation do not have a counterpart in the crash taxonomy.

This is interesting because we see that
crash and validation cover different aspects of the failure space.
Crash analysis shows us the most frequently occuring problems,
but validation statements show us the defensive patterns
that practitioners use to prevent crashes in the first place.

---

Wang et al., report that data preparation contains the most amount of crashes.
We independently find that feedback occurs in the upstream stages.
So its nice to see that despite the inverted lenses,
both studies arrive at the same conclusion.

---

Even more interesting is that although data preparation deserves the most attention,
we find that validation statements are not frequently written here.
Our hypothesis is that data quality does not have an oracle.
The notion of what good data looks like
is formed during the exploration and analysis itself.
So this ties back to a paper we wrote back in 2022
where we ask if there are data-agnostic, data quality checks.
We introduced a catalog of *data smells* (like code smells but for data).

---

One way to repay oversight debt
is to reduce the reliance on manual checks.
And we can think about this w.r.t., two dimensions.
The lifecycle stage (and I have simplified this to development and production),
and the degree of automation for the check.

Top-right is the ideal state that we want to be in
(we want as much automated checks as possible in production).
And it is possible to have manual checks in production
(like drift detection; A/B testing etc).

Not all checks need to be migrated into production,
they can be discarded once the prototype is ready.

The low-hanging fruit are the assertions we find in the notebooks,
which can be migrated (with modifications) to production.

For the exploratory statements we have several paths.
In this study we found statements that have a boolean output.
These can be promoted to assertions.
The rest of the exploratory statements
record the probe (what did the practitioner look at?)
But the predicate (what counts as wrong)
needs to be reconstructed with the practitioner (more challenging).

---

A more disruptive development is the use and abuse of AI agents.
Developers are increasingly delegating the SDLC to these agents
and we see possibilities here:
1. Agents trained on public notebooks so they generate exploratory statements in a faster rate
2. Perhaps an opportunity here is they can automatically insert assertions as they write analysis code.

---

Everything that I talked about so far is in the past,
because as of three weeks ago
I started working as a Data and AI Engineer
at Dot Technology.

We are a small startup based in the Netherlands.
We are a lean outfit of 25 "real" (real because they are mechanical and electrical engineers) engineers
...and me.
We primarily operate in the electrification of off-highway machines
such as the excavators you see behind me.
But we are quickly expanding into on-highway vehicles
and electric charge-point market.

We manufacture electric drivetrains (the muscle),
along with the VCU (the vehicle control unit, the brain, its a micro controller).
In a few weeks we are going to officially launch
a telemetry device, at the IoT Expo in Amsterdam.
This is the Dot Link Unit which communicates
with the VCU and relays sensor data for us to analyze.
The next vision for the company
is to develop data and AI products.
So I am also happy to discuss
this infamous bridge between academia and industry
that I crossed recently.

Thank you for your attention.
