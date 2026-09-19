---
title: ICSME 2026 Paper Presentation
date: 2026-09-18
author: Arumoy Shome
abstract: |
    Transcript of my paper presentation at ICSME 2026, Benevento Italy.
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

What I want to talk to you about today
is this tiny, but (in my opinion) significant gap
between this transition.
What is the actual workflow?
What are practitioners doing
to make this transition possible?

---

To address this gap
we ask three questions.
What are the exact engineering changes
that transition ML prototypes into automated scripts?
What are the software quality attributes that motivate these changes?
And finally,
what are the tensions and trade-offs that arise during such an endeavour?

---

We answer these questions
by conducting semi-structured interviews
with 13 practitioners from academia and industry.
We analyze the data using reflexive thematic analysis.
And our findings can be summarized into 23 engineering changes,
20 software quality attributes that are considered,
and 7 tensions and trade-offs that practitioners must navigate during this transition.

---

I grouped the 23 engineering changes into five high level themes
and I would like to share a few of them with you today.

When working within a notebook
we typically work with a smaller subset of the data.
This data tends to be static (either a CSV or JSON file)
and viewed locally on one's computer.
In a production script,
the data is often pulled from an API
and its scale tends to be much larger.
We find that practitioners take snapshots
of the intermediate datasets created by the automated pipeline
which helps debug issues at points of failure.
If the computation is expensive and time consuming,
then practitioners can also resume the process from the checkpoints.

---

We find that practitioners use `assert` statements
to ensure data quality in the automated pipeline.
Assertions include checking for missing values,
ensuring that the distribution of features
are within the expected range,
and that all expected features are still present in the training data
because the schema can be changed by an upstream system.

---

Another use of assertions
is to explicitly stop the pipeline execution
if certain constraints are not satisfied.
For instance, we spoke to a software engineer
who introduced assertions
to prevent data scientists on their team
from training complex models,
because this affected the overall latency of the system.

Finally, when working within a notebook
we tend to use the output of each cell
to make decisions on how to proceed with the analysis.
This unfortunately does not scale in automated pipelines
because you may have multiple scripts
that run asynchronously.
To overcome this challenge
practitioners adopt structured logging systems.

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

Another interesting finding
is that there are now two artifacts that need to be maintained in parallel.
All our participants said that they start a new project in a notebook
because it is really convenient
and allows them to produce a prototype quickly.
However once they migrate to automated pipelines,
they still continue to use notebooks from time-to-time
to debug issues.
So now you have two artifacts with diverged development history.
Practitioners face challenges
when trying to identify which parts need to be synced between the two artifacts.
You may be using an old data slice in your notebook
to debug an issue in the script,
or your script may have matured further than the code in your notebook.

---

Another challenge that practitioners mentioned repeatedly
is with debugging datasets.
The existing IDEs and text editors are optimized for information in text.
But when working with data, we are dealing with tables.
So when you try to explore a table inside your REPL,
you see this truncated version which is not that useful.

Major players in the Data and AI industry are taking notice,
and we are beginning to see development in the developer tool space.
Positron is an IDE for data scientists
with an integrated table viewer
and descriptive statistics visualizations.
This comes from Posit,
who are the creators of R studio (so they really know what they are doing).

Another interesting project is NBdev
from Jeremy Howard,
the ex-president of Kaggle.
His take on the matter
is to consider the notebook as the primary artifact,
with mechanisms to extract documentation from the markdown cells into a website,
and your code into scripts.

Finally, we have Kedro
which comes from Quantum Black, the AI arm of **MCINSEY**.
Kedro provides a framework
to organize your automated pipelines
and enforces many of the software quality best practices
that we are aware of.

---

Perhaps a more disruptive development on the horizon
is the *use and abuse* of AI agents.
Software development is increasingly being delegated to AI.
They are writing code,
tests,
and also being integrated into the review process.
There is this amazing paper that came out recently by Margaret-Anne,
who shows us the hidden cost of delegating software development to AI agents.
Her primary thesis is this notion of *cognitive debt*,
which silently erodes the shared mental model
of the codebase amongst the development team.

So on my train ride to Benevento,
I was trying to think about how oversight and cognitive debt interact with one another.
Both are hidden, and are not directly visible in the artifact (source code) itself.
Both have this notion of cognition,
but they play opposite roles.
The human is tightly integrated into the execution loop of the notebook,
and their mental model is what provides the oversight
and drives the analysis.
Whereas cognitive debt silently erodes the mental model of the code base.
And finally
oversight debt is incurred while developing AI
whereas cognitive debt is incurred from the use of AI.

So is cognitive debt a subset of oversight debt?
Is it the other way around?
Or do they have something in common?
Curious to hear your thoughts.

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
