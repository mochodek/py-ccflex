# py-ccflex - Python Flexible Code Classifier
This project is an implementation of machine learning for classyfing lines of code. It can be used to count lines of 
code given by an example, find violations of coding guidelines or mimic other metrics (e.g. McCabe complexity). 

The whole idea is build around the pipes-and-filters architecture style, where we use a number of components that 
process data and can be exchanged. The _bin_ folder contains these scripts. Components communicates with each other by
producing intermediary files (mostly in the csv format). 

Since this project is modular, we can use R to make some more advanced classifications, which are not available in Python.

The idea is described in the following paper:
* Ochodek, M., Staron, M., Bargowski, D., Meding, W., & Hebig, R. (2017, February). Using machine learning to 
design a flexible LOC counter. In Machine Learning Techniques for Software Quality Evaluation (MaLTeSQuE), 
IEEE Workshop on (pp. 14-20). IEEE.

* available at: [IEEE Xplore](http://ieeexplore.ieee.org/abstract/document/7882011/)

```bibtex
@inproceedings{ochodek2017using,
  title={Using machine learning to design a flexible LOC counter},
  author={Ochodek, Miroslaw and Staron, Miroslaw and Bargowski, Dominik and Meding, Wilhelm and Hebig, Regina},
  booktitle={Machine Learning Techniques for Software Quality Evaluation (MaLTeSQuE), IEEE Workshop on},
  pages={14--20},
  year={2017},
  organization={IEEE}
}
``` 

## Installation

To install pyccflex, download or clone the repository and run in the root directory:
```
pip install -e .
```
This will install dependencies and link the scripts present in the _bin_ directory.

## How to run 

In order to run the tool you will need to prepare a training sample and define the decision classes. 

Decision classes are defined in the classes.json file. Below is an example of the file defining two classes: 
count and ignore. The _line_prefix_ property is used to define a sequence of characters used to label a line of code. 
The prefix should be placed at the beginning of line without any following spaces. 
The _default_ key defines a decision class that should
be used if a line doesn't start from any of the predefined prefixes.  
 
Example of classes.json:
```json
{
  "classes": {
    "labeled": [
      {
        "line_prefix": "@",
        "name": "count",
        "value": 1
      }
    ],
    "default": {
      "name": "ignore",
      "value": 0
    }
  }
}
```

The training sample is code with labeled lines that you would like to classify. We use a json file
to define different locations (e.g., paths to training or classify code). 

Example of locations.json:
```json
{
  "train": {
    "baseline_dir": "path to main dir for the training code base",
    "locations": [
      {
        "path": "A path to some location withing a baseline_dir - could be the same as baseline_dir",
        "include": [
          ".+[.]cpp$",
          ".+[.]c$",
          ".+[.]h$"
        ],
        "exclude": []
      }
    ]
  },

  "classify": {
    "baseline_dir": "path to main dir for the code base to classify",
    "locations": [
      {
        "path": "A path to some location withing a baseline_dir - could be the same as baseline_dir",
        "include": [
          ".+[.]cpp$",
          ".+[.]c$",
          ".+[.]h$"
        ],
        "exclude": []
      }
    ]
  },

  "workspace_dir": {
    "path": "../ccflex_tmp",
    "erase": true
  },

  "rscript_executable_path": "C:/Program Files/R/bin/RScript.exe" 
}

```

Each location is defined under a key (e.g., "train" or "classify"). Some of the scripts
expect to obtain the path to the location.json file and keys in the file as parameters.

There are several additional json files that provide configuration parameters, e.g.,:
* classifiers_options.json - contains configurations of classifiers 
* files_format.json - allows to configure properties of intermediary files produced
and accepted by filters (e.g., a cvs separator)
* manual_features.json - configuration of manually predefined feature extracted
from the lines of code 

Finally, you can compose your own sequence of filters and run them. 
The easiest way is to create a bash script, like one below:

run.sh:
```
#!/bin/sh

LOCATIONS_CONFIG="./locations.json"
CLASSES_CONFIG="./classes.json"
FILES_FORMAT_CONFIG="./files_format.json"
MANUAL_FEATURES_CONFIG="./manual_features.json"
CLASSIFIERS_CONFIG="./classifiers_options.json"

# 1. create workspace
create-workspace --locations_config $LOCATIONS_CONFIG

# 2. read codebases, transform them to CSV, and extract features
lines2csv "train" --locations_config $LOCATIONS_CONFIG --classes_config $CLASSES_CONFIG --files_format_config $FILES_FORMAT_CONFIG
basic-manual-features "train" --add_decision_class true --add_contents true --locations_config $LOCATIONS_CONFIG --manual_features_config $MANUAL_FEATURES_CONFIG
lines2csv "classify" --locations_config $LOCATIONS_CONFIG --classes_config $CLASSES_CONFIG --files_format_config $FILES_FORMAT_CONFIG
basic-manual-features "classify" --add_decision_class true --add_contents true --locations_config $LOCATIONS_CONFIG --manual_features_config $MANUAL_FEATURES_CONFIG
vocabulary-extractor "classify" "vocabulary.csv" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG

# 3. run classification algorithms
classify_CART "train-basic-manual.csv" "classify-basic-manual.csv" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
classify_RandomForest "train-basic-manual.csv" "classify-basic-manual.csv" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
classify_KNN "train-basic-manual.csv" "classify-basic-manual.csv" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
classify_MultinomialNB "train-basic-manual.csv" "classify-basic-manual.csv" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
classify_c50_r "train-basic-manual.csv" "classify-basic-manual.csv" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG

# 4. merge results to a single csv file
merge_results --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG

# 5. generate reports
generate_html "train-basic-manual.csv" "training-lines-html.html" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
generate_html "results/classify-output-ALL.csv" "classified-lines-ALL.html" --all OK --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG

```

Let's explain the steps in the file:
1. Create a workspace directory - it will store all intermediary and output files.
1. Read train and classify code bases and extract all lines and features.
1. Run different classifiers, each will produce csv files with classification as 
an output (also separate files for each decision class).
1. Merge results of all classifiers into a single file for easier analysis.
1. Generate simple HTML reports.