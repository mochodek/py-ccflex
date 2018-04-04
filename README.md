# py-ccflex - Python Flexible Code Classifier
This project is an implementation of machine learning for classyfing lines of code. It can be used to count lines of 
code given by an example, find violations of coding guidelines or mimic other metrics (e.g. McCabe complexity). 

The whole idea is build around the pipes-and-filters architecture style, where we use a number of components that 
process data and can be exchanged. The _bin_ folder contains these scripts. Components communicates with each other by
producing intermediary files (mostly in the csv format). 

Since this project is modular, we can use R to make some more advanced classifications, which are not available in Python
by simply calling any script / program available in the operating system.

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

## Getting started

In order to run the tool you will need to prepare a training sample and define decision classes. 

Decision classes are defined in the classes.json file. Below is an example of the file defining two classes: 
count and ignore. The _labeled_ key contains definitions of the classes that you would like to manually label 
in the code. In this example, it is the *count* class. The _line_prefix_ property is used to define a sequence 
of characters used to label a line of code. 
The prefix should be placed at the beginning of line without any following spaces. 
The _default_ key defines a decision class that should
be used if a line does not start from any of the predefined prefixes.  
 
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

The training sample is the code with labeled lines that you would like to classify. We use a json file
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
FEATURE_SELECTORS_CONFIG="./feature_selectors_options.json"

# 1. create workspace
create_workspace --locations_config $LOCATIONS_CONFIG

# 2. read codebases, transform them to CSV, and extract features
lines2csv "train" --locations_config $LOCATIONS_CONFIG --classes_config $CLASSES_CONFIG --files_format_config $FILES_FORMAT_CONFIG
lines2csv "classify" --locations_config $LOCATIONS_CONFIG --classes_config $CLASSES_CONFIG --files_format_config $FILES_FORMAT_CONFIG

# manually defined features
predefined_manual_features "train" --add_decision_class --add_contents --locations_config $LOCATIONS_CONFIG --manual_features_config $MANUAL_FEATURES_CONFIG
predefined_manual_features "classify"  --add_contents --locations_config $LOCATIONS_CONFIG --manual_features_config $MANUAL_FEATURES_CONFIG

# bag of words
vocabulary_extractor "train-lines.csv"  "vocabulary.csv" --top_words_threshold 10 --token_signature_for_missing --min_ngrams 1 --max_ngrams 2 --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
bag_of_words "train" "vocabulary.csv" --min_ngrams 1 --max_ngrams 2 --token_signature_for_missing --add_decision_class --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
bag_of_words "classify" "vocabulary.csv" --min_ngrams 1 --max_ngrams 2 --token_signature_for_missing --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG

# merge manual features and bag of words
merge_inputs --input_files "train-basic-manual.csv" "train-bag-of-words.csv" --output_file "train-manual-and-bow.csv" --add_decision_class --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
merge_inputs --input_files "classify-basic-manual.csv" "classify-bag-of-words.csv" --output_file "classify-manual-and-bow.csv"  --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG

# add context +/- lines
add_seq_context  "train-manual-and-bow.csv" "train-manual-and-bow-ctx.csv" --prev_cases 1 --next_cases 1 --add_decision_class --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
add_seq_context  "classify-manual-and-bow.csv" "classify-manual-and-bow-ctx.csv" --prev_cases 1 --next_cases 1 --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG

# perform feature selection - remove duplicated features
select_features  "train-manual-and-bow-ctx.csv" "classify-manual-and-bow-ctx.csv" --output_file_prefix "min-" --feature_selectors "VarianceThreshold" --add_decision_class --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --feature_selectors_options $FEATURE_SELECTORS_CONFIG --classes_config $CLASSES_CONFIG

# 3. run classification algorithms
# train and classify using bag-of-words feature
#classify "train-bag-of-words.csv" "classify-bag-of-words.csv" --classifiers "CART" "RandomForest" "C50" "MultinomialNB" "KNN"  --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG

# train and classify using manually defined features
#classify "train-basic-manual.csv" "classify-basic-manual.csv" --classifiers "CART" "RandomForest" "C50" "MultinomialNB" "KNN"  --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG

# train and classify using both manually defined and bag-of-words feature
#classify "train-manual-and-bow.csv" "classify-manual-and-bow.csv" --classifiers "CART" "RandomForest" "C50" "MultinomialNB" "KNN"  --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG

# train and classify using both manually defined and bag-of-words feature with +/- context lines
classify "min-train-manual-and-bow-ctx.csv" "min-classify-manual-and-bow-ctx.csv" --classifiers "CART" "RandomForest" "C50" "MultinomialNB" "KNN"  --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG

# 4. merge results to a single csv file
merge_results --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG

# 5. generate html reports
generate_html "processing/train-basic-manual.csv" "training-lines-manual-features.html" --all  --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
generate_html "processing/train-bag-of-words.csv" "training-lines-bow-features.html" --all  --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
generate_html "results/classify-output-ALL.csv" "classified-lines-ALL.html" --all --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
generate_html "results/classify-output-ALL-count.csv" "classified-lines-ALL-count.html" --all --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
generate_html "results/classify-output-C50-count.csv" "classified-lines-C50-count.html" --all --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG


```

Let's explain the steps in the file:
1. Create a workspace directory - it will store all intermediary and output files.
1. Read train and classify code bases and extract all lines and features.
1. Run different classifiers, each will produce csv files with classification as 
an output (also separate files for each decision class).
1. Merge results of all classifiers into a single file for easier analysis.
1. Generate simple HTML reports.

## Components

Here you can find a list of components (filters) that are currently available. We will enumerate
the most important options of the tools. If you want to know the whole list of parameters 
just run any of the tools with --help parameter.

### create_workspace
The script creates the workspace directory. 

*Input:*
* --locations_config - path to locations configuration (json). The file shall contain
 the "workspace_dir" key that defines path to the workspace folder. There is also the *erase* option
 which if set to true will clear the folder each time the script is executed 

*Output:* None

### lines2csv
The script extracts cases from your source code. It traverse through the folder structure, readers
files and extracts them to a single csv file. Later, this file is used by other tools without the 
need of accessing the code.

*Input:* 
* the first parameter is the *key* of location defined in the locations json file that is going to be 
scanned for the code
* --locations_config - path to locations configuration (json). 
* --classes_config - files containing definitions of decision classes. The tool needs to know what are
the decision classes and how to identify them in the code

*Output:* 
* \<location key>-lines.csv is produced in the processing folder of the workspace


### predefined_manual_features
This script analyses the lines.csv file to extract manually crafted features, e.g., presence of some 
substring in a line. The definition of the features is provide in a json file (e.g., manual_features.json).

*Input:* 
* the first parameter is the *key* of location defined in the locations json file that is going to be 
scanned for the code
* --locations_config - path to locations configuration (json). 
* --manual_features_config - a json file containing names of features and patterns to be found (see example 
in the code)

*Output:* 
* \<location key>-basic-manual.csv - a file containing extracted features that could be used to train a classifer

### vocabulary_extractor
This script can be used to automatically build a vocabulary, which then can be used to automatically
extract features (bag of words).

*Input:* 
* the first parameter is the name of lines file or path to a similar file located in other location 
than the workspace (sometimes you may like to build your vocabulary using a different code base).

* the second parameter is the name of vocabulary file to create

* --top_words_threshold - allows to limit the number of words in the vocabulary

* --token_signature_for_missing - if the number of words is limited the question is what to do with 
those outside the vocabulary? By using this option, we create a signature of a token which is not 
in a vocabulary and add to the vocabulary.

* --min_ngrams, --max_ngrams - sometimes it is worth to have pairs, triples, ... of words as features.
This option allows to provide the minimal and maximum number of consecutive words to 
form a feature.

*Output:* 
* \<vocabulary name>.csv - the final vocabulary
* base-\<vocabulary name>.csv - the base vocabulary consisting only 1-grams
* base-\<vocabulary name>.json - the base vocabulary file in the same format as used to define manual 
features (you can use it to configure your manual feature extractor) 

### bag_of_words
This scripts extract features using a given vocabulary and creates a bag of wrods representation.

*Input:* 
* the first parameter is the *key* of location defined in the locations json. The tool will look for
lines.csv file based on this key
* the second parameter is the name of the vocabulary file (see vocabulary_extractor)
* --token_signature_for_missing - if the number of words is limited the question is what to do with 
those outside the vocabulary? By using this option, we create a signature of a token which is not 
in a vocabulary and add to the vocabulary.
* --min_ngrams, --max_ngrams - sometimes it is worth to have pairs, triples, ... of words as features.
This option allows to provide the minimal and maximum number of consecutive words to 
form a feature.

*Output:* 
* \<location key>-bag-of-words.csv - a file containing extracted features that could be used to train a classifer

### merge_inputs
This script is used to merge the input files with cases (features files)

*Input:*
* --input_files - a list of input files to merge in the processing folder of the workspace
* --output_file - the name of output file

*Output:* 
* merged features file

### add_seq_context
This script adds n preceding/proceeding lines as context (copies features) 

*Input:*
* the first parameter is the name of the features csv file to process
* the second parameter is the name of the output csv file
* --prev_cases - the number of preceding lines to add as a context
* --next_cases - the number of proceeding lines to add as a context

*Output:* 
* the name of output file with added features from previous / next lines

### merge_results
This script is used to merge the results provided by different classifiers into a single file.

*Input:*
* --locations_config - path to locations configuration (json). The merger needs to know where
the workspace is located

*Output:* 
* classify-output-ALL.csv - merges all results file found in results folder of the workspace
* classify-output-ALL-\<class>.csv - merges all results file found in results folder of the workspace
but filtered to contain only classification to a given class

### select_features
This scripts allows to perform feature selection.

*Input:*
* the first parameter is the name of the file containing features for training set
* the second parameter is the name of the file containing features for set to classify
* --output_file_prefix - the prefix that will be added to output features files (training and classify) 
* --feature_selectors - a list of feature selection algorithms:
    * VarianceThreshold - variance threshold - useful in eliminating duplicate features (sklearn)
* --feature_selectors_options - a json file with feature selector options. If it contains a key equal to 
the name of the feature selection algorithm its contents will be used to configure the feature selection algorithm

*Output:* 
* <output_file_prefix><first parameter> - reduced training feature file
* <output_file_prefix><second parameter> - reduced classify feature file

### classify
This scripts uses different algorithms to classify lines.

*Input:*
* the first parameter is the name of the file containing features for training set
* the second parameter is the name of the file containing features for set to classify
* --classifiers - a list of classification algorithms to use:
    * CART - CART decision tree (sklearn)
    * KNN - K-nearest neighbours (sklearn)
    * RandomForest - random forest (sklearn)
    * MultinomialNB - multinomial Naive Bayes (sklearn)
    * C50 - C50 decision trees (R C50 package)
* --classifiers_options - a json file with classifiers options. If it contains a key equal to 
the name of the classifier its contents will be used to configure the classification algorithm

*Output:* 
* classify-output-\<classifier>.csv - result of classification stored in results folder of the workspace
* classify-output-\<classifer>-\<class>.csv - results filtered for a given class

