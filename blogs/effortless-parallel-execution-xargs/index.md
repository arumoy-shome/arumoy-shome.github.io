---
title: Effortless Parallel Execution with xargs & Friends
date: 2022-05-08
author: Arumoy Shome
abstract: |
    Recently, I had to run [Tensorflow Data
    Validation](https://github.com/tensorflow/data-validation) on over 500
    public datasets from [Kaggle](https://kaggle.com/) to generate a
    baseline schema file for further analysis. I chose to do this using
    the xargs unix command.
categories: [shell]
---

Recently, I had to run [Tensorflow Data
Validation](https://github.com/tensorflow/data-validation) on over 500
public datasets from [Kaggle](https://kaggle.com/) to generate a
baseline schema file for further analysis. I chose to do this using
the xargs unix command.

Following is a python script which generates the schema file and saves
it to disk for a single csv dataset.

```{.python filename="csv2schema.py"}
#!/usr/bin/env python

import os
import sys
import tensorflow_data_validation as tfdv
import pandas as pd

_CWD = os.path.dirname(__file__)
DATADIR = os.path.abspath(os.path.join(_CWD, '..', 'data'))
STATSDIR = os.path.join(DATADIR, 'stats', 'train')
SCHEMADIR = os.path.join(DATADIR, 'schema')

name, _ = os.path.basename(sys.argv[1]).split('.')

if os.path.isfile(os.path.join(SCHEMADIR, name+'.proto')):
    print(name+'.proto', 'already exists, skipping...')
else:
    frame = pd.read_csv(os.path.join(DATADIR, 'train', name+'.csv'))
    stats = tfdv.generate_statistics_from_dataframe(frame)
    schema = tfdv.infer_schema(stats)
    tfdv.write_stats_text(stats, os.path.join(STATSDIR, name+'.proto'))
    tfdv.write_schema_text(schema, os.path.join(SCHEMADIR, name+'.proto'))
```

The script accepts as argument a valid csv file (we assume that the
file names are pruned and do not contain a period character within the
name, but only to denote the extension). We read the file as a pandas
dataframe, generate the statistics using
`tfdv.generate_statistics_from_dataframe` function and infer a schema
which is stored on disk for later analysis.

Following is the bash shellscript wrapper which executes the python
script presented above across several datasets using the `find`
command. You may have to experiment with the `-P` flag which specifies
the number of cores to distribute the execution across.

```{.bash filename="csv2schema.bash}
#!/usr/bin/env bash

mkdir -p data/{schema,stats/train}

find data/train -type f |
    xargs -n 1 -P 4 ./bin/write-schema.py
```

 That's all there is to it! Write your main script with one file in
 mind, and distribute across several files using a combination of
 `find` and `xargs`.
