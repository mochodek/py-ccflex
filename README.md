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

Decision classes are defined in the classes.json file (all the names of json configuration files can be changed). 
Below is an example of the file defining two classes - count and ignore.

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

The _labeled_ key contains definitions of the classes that you would like to manually label 
in the code. In this example, it is the *count* class. The _line_prefix_ property is used to define a sequence 
of characters used to label a line of code. 
The prefix should be placed at the beginning of line without any following spaces. 
The _default_ key defines a decision class that should
be used if a line does not start from any of the predefined prefixes.  
 

The training sample is a piece of code with labeled lines. We use a json file
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
* feature_selectors_options.json - defines parameters of feature selection algorithms.

An important concept is the _workspace_ directory. Since py-ccflex produces intermediary
files they need to be stored somewhere. We call this directory workspace. There is a 
script that creates the directory that you will usually put at the beginning of the 
processing chain. The workspace directory has the following structure:
* processing - all intermediary files regarding the code and features are stored in this folder
* results - all classification results are stored there
* reports - final reports like html files are stored in this folder


Finally, you can compose your own sequence of filters and run them. 
The easiest way is to create a bash script, like one below:

run.sh:
```
#!/bin/sh

LOCATIONS_CONFIG="./locations.json"
CLASSES_CONFIG="./classes.json"
BLOCK_CLASSES_CONFIG="./block_classes.json"
FILES_FORMAT_CONFIG="./files_format.json"
MANUAL_FEATURES_CONFIG="./manual_features.json"
CLASSIFIERS_CONFIG="./classifiers_options.json"
FEATURE_SELECTORS_CONFIG="./feature_selectors_options.json"

TRAIN_LOCATION="train"
CLASSIFY_LOCATION="classify"

# Processing options
CREATE_WORKSPACE=true
LINES=true
FEATURES=true
CONTEXT=true
CLASSIFY=true
REPORT=true
TEAR_DOWN=true

# MAX_GRAM could be 1, 2 or 3 used for bag of words
MIN_NGRAM=1
MAX_NGRAM=3

# If CONTEXT set to true how many lines
CONTEXT_LINES_PREV=1
CONTEXT_LINES_FRWD=1

# Available extractors "PatternSubstringExctractor PatternWordExtractor WholeLineCommentFeatureExtraction CommentStringExtractor NoWordsExtractor NoCharsExtractor"
MANUAL_FEATURE_EXTRACTORS="PatternSubstringExctractor PatternWordExtractor WholeLineCommentFeatureExtraction NoWordsExtractor NoCharsExtractor"

CLASSIFIERS=( "CART" "RandomForest")



# === Create workspace ===
$CREATE_WORKSPACE && create_workspace --locations_config $LOCATIONS_CONFIG

# === Copy vocabulary files ===
$FEATURES && copy_builtin_training_file "base-cpp-vocabulary.csv" --locations_config $LOCATIONS_CONFIG

# === TRAINING ===

# === Read training code ===
$LINES && lines2csv "${TRAIN_LOCATION}" \
	--locations_config $LOCATIONS_CONFIG \
	--classes_config $CLASSES_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG

# === Feature exctraction for training set ===

$FEATURES  && vocabulary_extractor "${TRAIN_LOCATION}-lines.csv"  "cpp-vocabulary.csv" \
	--skip_generating_base_vocabulary \
	--top_words_threshold 200 \
	--token_signature_for_missing \
	--min_ngrams $MIN_NGRAM --max_ngrams $MAX_NGRAM \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG

# Manual features
$FEATURES  && predefined_manual_features "$TRAIN_LOCATION" \
	--extractors $MANUAL_FEATURE_EXTRACTORS \
	--add_decision_class \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--manual_features_config $MANUAL_FEATURES_CONFIG

# Bag of words
$FEATURES && bag_of_words "${TRAIN_LOCATION}" "cpp-vocabulary.csv" \
	--min_ngrams $MIN_NGRAM --max_ngrams $MAX_NGRAM \
	--token_signature_for_missing \
	--add_decision_class --add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG \
	--chunk_size 10000

$FEATURES && merge_inputs --input_files "${TRAIN_LOCATION}-bag-of-words.csv" "${TRAIN_LOCATION}-manual.csv" \
	--output_file "${TRAIN_LOCATION}-features.csv" \
	--add_decision_class \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG
$FEATURES && copy_feature_file "${TRAIN_LOCATION}-features.csv" "${TRAIN_LOCATION}-features-tmp.csv"

# Block comments
$FEATURES && extract_block_features_from_features "${TRAIN_LOCATION}-features.csv" "${TRAIN_LOCATION}-comments.csv" "block_comment" --feature_start "/ *"  --feature_end "* /"  \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG

$FEATURES && merge_inputs --input_files "${TRAIN_LOCATION}-features-tmp.csv" "${TRAIN_LOCATION}-comments.csv" \
	--output_file "${TRAIN_LOCATION}-features.csv" \
	--add_decision_class \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG
$FEATURES && copy_feature_file "${TRAIN_LOCATION}-features.csv" "${TRAIN_LOCATION}-features-tmp.csv"

# Enums
$FEATURES && extract_block_features_from_features "${TRAIN_LOCATION}-features.csv" "${TRAIN_LOCATION}-enum.csv" "in_enum" --feature_start "enum  "  --feature_end ";" "} ;"  \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--forbidding_features "block_comment" "whole_line_comment" \
	--files_format_config $FILES_FORMAT_CONFIG

$FEATURES && merge_inputs --input_files "${TRAIN_LOCATION}-features-tmp.csv" "${TRAIN_LOCATION}-enum.csv" \
	--output_file "${TRAIN_LOCATION}-features.csv" \
	--add_decision_class \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG
$FEATURES && copy_feature_file "${TRAIN_LOCATION}-features.csv" "${TRAIN_LOCATION}-features-tmp.csv"

# Feature selection low variance
$FEATURES && select_features "${TRAIN_LOCATION}-features.csv" "low_var_features.csv" \
	--feature_selector "VarianceThreshold" \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG \
	--feature_selectors_options $FEATURE_SELECTORS_CONFIG \
	--classifiers_options $CLASSIFIERS_CONFIG

$FEATURES && apply_features_selection "${TRAIN_LOCATION}-features-tmp.csv" "${TRAIN_LOCATION}-features.csv" "low_var_features.csv" \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG \
	--chunk_size 10000
$FEATURES && copy_feature_file "${TRAIN_LOCATION}-features.csv" "${TRAIN_LOCATION}-features-tmp.csv"

# Feature selection
$FEATURES && select_features "${TRAIN_LOCATION}-features.csv" "selected_features.csv" \
	--feature_selector "SelectFpr" \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG \
	--feature_selectors_options $FEATURE_SELECTORS_CONFIG \
	--classifiers_options $CLASSIFIERS_CONFIG

$FEATURES && apply_features_selection "${TRAIN_LOCATION}-features-tmp.csv" "${TRAIN_LOCATION}-features.csv" "selected_features.csv" \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG \
	--chunk_size 10000
$FEATURES && copy_feature_file "${TRAIN_LOCATION}-features.csv" "${TRAIN_LOCATION}-features-tmp.csv"

# Conext
$FEATURES && $CONTEXT && add_seq_context  "${TRAIN_LOCATION}-features-tmp.csv" "${TRAIN_LOCATION}-features.csv" \
	--prev_cases $CONTEXT_LINES_PREV --next_cases $CONTEXT_LINES_FRWD \
	--add_decision_class \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG
$FEATURES && $CONTEXT && copy_feature_file "${TRAIN_LOCATION}-features.csv" "${TRAIN_LOCATION}-features-tmp.csv"

$FEATURES && $CONTEXT && select_features "${TRAIN_LOCATION}-features.csv" "ctx_selected_features.csv" \
	--feature_selector "SelectFpr" \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG \
	--feature_selectors_options $FEATURE_SELECTORS_CONFIG \
	--classifiers_options $CLASSIFIERS_CONFIG

$FEATURES && $CONTEXT && apply_features_selection "${TRAIN_LOCATION}-features-tmp.csv" "${TRAIN_LOCATION}-features.csv" "ctx_selected_features.csv" \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG \
	--chunk_size 10000
$FEATURES && $CONTEXT && copy_feature_file "${TRAIN_LOCATION}-features.csv" "${TRAIN_LOCATION}-features-tmp.csv"


# === PREPARE CLASSIFY ===

# === Read training code ===
$LINES && lines2csv "${CLASSIFY_LOCATION}" \
	--locations_config $LOCATIONS_CONFIG \
	--classes_config $CLASSES_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG


# === Feature exctraction for training set ===

# Manual features
$FEATURES  && predefined_manual_features "$CLASSIFY_LOCATION" \
	--extractors $MANUAL_FEATURE_EXTRACTORS \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--manual_features_config $MANUAL_FEATURES_CONFIG

# Bag of words
$FEATURES && bag_of_words "${CLASSIFY_LOCATION}" "cpp-vocabulary.csv" \
	--min_ngrams $MIN_NGRAM --max_ngrams $MAX_NGRAM \
	--token_signature_for_missing \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG \
	--chunk_size 10000

$FEATURES && merge_inputs --input_files "${CLASSIFY_LOCATION}-bag-of-words.csv" "${CLASSIFY_LOCATION}-manual.csv" \
	--output_file "${CLASSIFY_LOCATION}-features.csv" \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG
$FEATURES && copy_feature_file "${CLASSIFY_LOCATION}-features.csv" "${CLASSIFY_LOCATION}-features-tmp.csv"

# Block comments
$FEATURES && extract_block_features_from_features "${CLASSIFY_LOCATION}-features.csv" "${CLASSIFY_LOCATION}-comments.csv" "block_comment" --feature_start "/ *"  --feature_end "* /"  \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG

$FEATURES && merge_inputs --input_files "${CLASSIFY_LOCATION}-features-tmp.csv" "${CLASSIFY_LOCATION}-comments.csv" \
	--output_file "${CLASSIFY_LOCATION}-features.csv" \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG
$FEATURES && copy_feature_file "${CLASSIFY_LOCATION}-features.csv" "${CLASSIFY_LOCATION}-features-tmp.csv"

# Enums
$FEATURES && extract_block_features_from_features "${CLASSIFY_LOCATION}-features.csv" "${CLASSIFY_LOCATION}-enum.csv" "in_enum" --feature_start "enum  "  --feature_end ";" "} ;"  \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--forbidding_features "block_comment" "whole_line_comment" \
	--files_format_config $FILES_FORMAT_CONFIG

$FEATURES && merge_inputs --input_files "${CLASSIFY_LOCATION}-features-tmp.csv" "${CLASSIFY_LOCATION}-enum.csv" \
	--output_file "${CLASSIFY_LOCATION}-features.csv" \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG
$FEATURES && copy_feature_file "${CLASSIFY_LOCATION}-features.csv" "${CLASSIFY_LOCATION}-features-tmp.csv"

# Feature selection low variance
$FEATURES && apply_features_selection "${CLASSIFY_LOCATION}-features-tmp.csv" "${CLASSIFY_LOCATION}-features.csv" "low_var_features.csv" \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG \
	--chunk_size 10000
$FEATURES && copy_feature_file "${CLASSIFY_LOCATION}-features.csv" "${CLASSIFY_LOCATION}-features-tmp.csv"

# Feature selection
$FEATURES && apply_features_selection "${CLASSIFY_LOCATION}-features-tmp.csv" "${CLASSIFY_LOCATION}-features.csv" "selected_features.csv" \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG \
	--chunk_size 10000
$FEATURES && copy_feature_file "${CLASSIFY_LOCATION}-features.csv" "${CLASSIFY_LOCATION}-features-tmp.csv"

# Conext
$FEATURES && $CONTEXT && add_seq_context  "${CLASSIFY_LOCATION}-features-tmp.csv" "${CLASSIFY_LOCATION}-features.csv" \
	--prev_cases $CONTEXT_LINES_PREV --next_cases $CONTEXT_LINES_FRWD \
	--add_decision_class \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG
$FEATURES && $CONTEXT && copy_feature_file "${CLASSIFY_LOCATION}-features.csv" "${CLASSIFY_LOCATION}-features-tmp.csv"

$FEATURES && $CONTEXT && apply_features_selection "${CLASSIFY_LOCATION}-features-tmp.csv" "${CLASSIFY_LOCATION}-features.csv" "ctx_selected_features.csv" \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG \
	--chunk_size 10000
$FEATURES && $CONTEXT && copy_feature_file "${CLASSIFY_LOCATION}-features.csv" "${CLASSIFY_LOCATION}-features-tmp.csv"


# === REMOVING FEATURE EXTRACTION TEMPORARY FILES ===
# This should be always at the end of feature selection
$TEAR_DOWN && $FEATURES && delete_processing_file "${TRAIN_LOCATION}-features-tmp.csv"
$TEAR_DOWN && $FEATURES && delete_processing_file "${CLASSIFY_LOCATION}-features-tmp.csv"


# === CLASSIFY ====
for CLASSIFIER in "${CLASSIFIERS[@]}"
do
	$CLASSIFY && classify "${TRAIN_LOCATION}-features.csv" "${CLASSIFY_LOCATION}-features.csv" \
	--classifier "${CLASSIFIER}" \
	--chunk_size 20000 \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG \
	--classifiers_options $CLASSIFIERS_CONFIG \
	--classes_config $CLASSES_CONFIG
done

# merge results to a single csv file
$CLASSIFY && merge_results --locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG \
	--classifiers_options $CLASSIFIERS_CONFIG \
	--classes_config $CLASSES_CONFIG


# === REPORT ====
# generate reports
$REPORT && generate_html "results/classify-output-ALL.csv" "classified-lines-ALL.html" \
	--all --split_files --chunk_size 20000 \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG

$REPORT && generate_html "results/classify-output-ALL-count.csv" "classified-lines-ALL-count.html" \
	--all --split_files --chunk_size 20000 \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG

```

Briefly summarizing the steps in the run.sh file above:
1. Create a workspace directory - it will store all intermediary and output files.
1. Read train and classify code bases and extract all lines and features.
1. Run different classifiers, each will produce csv files with classification as 
an output (also separate files for each decision class).
1. Merge results of all classifiers into a single file for easier analysis.
1. Generate simple HTML reports.

*NOTE*: Currently, most of the scripts assumes that the provided data is correct. Therefore, in case of providing wrong
input (e.g., trying to merge csv files with different number of rows) you will most likely see the Python exception
trace instead of nicely formatted message.

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
The script extracts cases from your source code. It traverse through the folder structure, reads
files and extracts cases (lines) to a csv file. Later, this file is used by other tools without the 
need of accessing the code.

*Input:* 
* the first parameter is the *key* of location defined in the locations json file that is going to be 
scanned for the code
* --locations_config - path to locations configuration (json). 
* --classes_config - a json file containing definitions of decision classes. The tool needs to know what are
the decision classes and how to identify them in the code
* --files_format_config - a json file with configuration of file format (e.g., the separator
used in csv files)

*Output:* 
* \<location key>-lines.csv is produced in the processing folder of the workspace


### copy_builtin_training_file
Copies one of the built-in training files into the workspace.

*Input:*
* the first parameter is the name of the file to be copied (files in data subdirectory of pyccflex)
* --locations_config - path to locations configuration (json). The file shall contain
 the "workspace_dir" key that defines path to the workspace folder. There is also the *erase* option
 which if set to true will clear the folder each time the script is executed 

*Output:* the file is copied into the workspace processing directory.


### delete_processing_file
Removes a given file in the procssing subfolder of the workspace.

*Input:*
* the first parameter is the name of the file to be removed
* --locations_config - path to locations configuration (json). The file shall contain
 the "workspace_dir" key that defines path to the workspace folder. There is also the *erase* option
 which if set to true will clear the folder each time the script is executed 

*Output:* the file is removed from the workspace processing directory.

### copy_feature_file
Makes a copy of a given feature file.

*Input:*
* the first parameter is the name of the features file to be copied
* the second parameter is the name of the output file 
* --locations_config - path to locations configuration (json). The file shall contain
 the "workspace_dir" key that defines path to the workspace folder. There is also the *erase* option
 which if set to true will clear the folder each time the script is executed 

*Output:* the feature file is copied.

### predefined_manual_features
This script analyses the lines.csv file to extract manually crafted features, e.g., presence of some 
substring in a line. The definition of the features is provide in a json file (e.g., manual_features.json).

*Input:* 
* the first parameter is the *key* of location defined in the locations json file that is going to be 
scanned for the code.
* --locations_config - path to locations configuration (json). 
* --manual_features_config - a json file containing names of features and patterns to be found (see example 
in the code)
* --files_format_config - a json file with configuration of file format (e.g., the separator
used in csv files).
* --add_decision_class - the flag is used without parameters; if present two columns will be added
to the output csv file - class_value and class_name.
* --add_contents -  the flag is used without parameters; if present a column 'contents'
will be added to the output file with the original text of the line.
* --extractors - a list of feature extractors names (or all if not provided):
    * PatternSubstringExctractor - looks for substrings in defined under the manual_string_counting_features
    key in manual_features.json file.
    * PatternWordExtractor - looks for the whole words matching patterns in defined under the 
    manual_whole_word_counting_features key in manual_features.json file.
    * CommentStringExtractor - look for //, /*, and \*.
    * NoWordsExtractor - the number of words.
    * NoCharsExtractor - the number of characters.

*Output:* 
* \<location key>--manual.csv - a file containing extracted features that could be used to train a classifer

### vocabulary_extractor
This script can be used to build a vocabulary of "words" present in the code. Later, 
such a vocabulary can be used to automatically extract features (bag of words).

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
* --locations_config - path to locations configuration (json). 
* --files_format_config - a json file with configuration of file format (e.g., the separator
used in csv files).
* --include_statistics - the flag is used without parameters; if used, the output csv vocabulary file
will contain additional columns with statistics for each word in the vocabulary (frequency).

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
* --locations_config - path to locations configuration (json). 
* --files_format_config - a json file with configuration of file format (e.g., the separator
used in csv files).
* --add_decision_class - the flag is used without parameters; if present two columns will be added
to the output csv file - class_value and class_name.
* --add_contents -  the flag is used without parameters; if present a column 'contents'
will be added to the output file with the original text of the line.

*Output:* 
* \<location key>-bag-of-words.csv - a file containing extracted features that could be used to train a classifer


### extract_block_features_from_class
This scripts can be used to add a new "block" feature based on previously classified code. To do that, you need to first
classify the code using three classes:
* start - a line that is the beginning of the block
* end - a line that ends the block
* start_end - a line that contains the whole block
You can see an example of how to define such classes in the block_classes.json file.

The script will create a new feature file with a single feature (1 if within a block, otherwise 0).

*Input:* 
* the first parameter is the path to the file containing classified code
* the second parameter is a new feature file containing the block feature
* the third parameter is the name of the feature to create
* --locations_config - path to locations configuration (json). 
* --files_format_config - a json file with configuration of file format (e.g., the separator
used in csv files).
* --add_decision_class - the flag is used without parameters; if present two columns will be added
to the output csv file - class_value and class_name.
* --add_contents -  the flag is used without parameters; if present a column 'contents'
will be added to the output file with the original text of the line.
* --block_classes_config - a json file containing definitions of decision classes for finding the blocks. 

*Output:* 
* \<the second paramter>- - a file containing the new feature

### extract_block_features_from_features
This scripts can be used to add a new "block: feature based on a combination of existing features
that are used to determine start and end of a block.
 
The script will create a new feature file with a single feature (1 if within a block, otherwise 0).

*Input:* 
* the first parameter is the path to the file containing classified code
* the second parameter is a new feature file containing the block feature
* the third parameter is the name of the feature to create
* --feature_start - a list of feature names; if any of them is greater than 0 the line is treated 
as the beginning of a block
* --feature_end - a list of feature names; if any of them is greater than 0 the line is treated 
as the ending of a block
* --forbidding_features - a list of feature names; if any of them is greater than 0 it prevents from
treating the line as a beginning or ending of a block
* --locations_config - path to locations configuration (json). 
* --files_format_config - a json file with configuration of file format (e.g., the separator
used in csv files).
* --add_decision_class - the flag is used without parameters; if present two columns will be added
to the output csv file - class_value and class_name.
* --add_contents -  the flag is used without parameters; if present a column 'contents'
will be added to the output file with the original text of the line.


*Output:* 
* \<the second paramter>- - a file containing the new feature


### merge_inputs
This script is used to merge the input files with cases (features files)

*Input:*
* --input_files - a list of input files to merge in the processing folder of the workspace
* --output_file - the name of output file
* --locations_config - path to locations configuration (json). 
* --files_format_config - a json file with configuration of file format (e.g., the separator
used in csv files).
* --add_decision_class - the flag is used without parameters; if present two columns will be added
to the output csv file - class_value and class_name.
* --add_contents -  the flag is used without parameters; if present a column 'contents'
will be added to the output file with the original text of the line.
* --chunk_size - the size of the batch of lines that will be read and processed (allows to read big files).  

*Output:* 
* merged features file

### add_seq_context
This script adds n preceding/proceeding lines as context (copies the features). 

*Input:*
* the first parameter is the name of the features csv file to process.
* the second parameter is the name of the output csv file.
* --prev_cases - the number of preceding lines to add as a context.
* --next_cases - the number of proceeding lines to add as a context.
* --locations_config - path to locations configuration (json). 
* --files_format_config - a json file with configuration of file format (e.g., the separator
used in csv files).
* --add_decision_class - the flag is used without parameters; if present two columns will be added
to the output csv file - class_value and class_name.
* --add_contents -  the flag is used without parameters; if present a column 'contents'
will be added to the output file with the original text of the line.
* --chunk_size - the size of the batch of lines that will be read and processed (allows to read big files).

*Output:* 
* the name of output file with added features from previous / next lines

### select_features
Selects the most promising features and stores their names in a file.

*Input:*
* the first parameter is the name of the file containing features for training set
* the second parameter is the name of the output file containing the list of feature to preserve
* --feature_selector - a feature selection algorithms:
    * VarianceThreshold - variance threshold - useful in eliminating duplicate features (sklearn)
    * SelectPercentile - selects features according to a percentile of the highest scores (sklearn)
    * SelectFpr - selects the pvalues below alpha based on a FPR test (sklearn)
* --feature_selectors_options - a json file with feature selector options. If it contains a key equal to 
the name of the feature selection algorithm its contents will be used to configure the feature selection algorithm
* --locations_config - path to locations configuration (json). 
* --files_format_config - a json file with configuration of file format (e.g., the separator
used in csv files).
* --classifiers_options - a json file with classifiers options. 
* --chunk_size - the size of the batch of lines that will be read and processed (allows to read big files).

*Output:* 
* <second parameter> - a csv file with names of features to preserve 


### apply_feature_selection
Reads a feature file and select columns based on the output file produced by the select_features script.  

*Input:*
* the first parameter is the name of the input feature file
* the second parameter is the name of the output feature file
* the thirds parameter is the name of the csv file containing list of selected features
* --locations_config - path to locations configuration (json). 
* --files_format_config - a json file with configuration of file format (e.g., the separator
used in csv files).
* --chunk_size - the size of the batch of lines that will be read and processed (allows to read big files).

*Output:* 
* <the second parameter> - a reduced training feature file

### classify
This scripts uses different algorithms to classify lines.

*Input:*
* the first parameter is the name of the file containing features for training set
* the second parameter is the name of the file containing features for set to classify
* --classifier - a classification algorithm to use:
    * CART - CART decision tree (sklearn)
    * KNN - K-nearest neighbours (sklearn)
    * RandomForest - random forest (sklearn)
    * MultinomialNB - multinomial Naive Bayes (sklearn)
    * C50 - C50 decision trees (R C50 package)
* --classifiers_options - a json file with classifiers options. If it contains a key equal to 
the name of the classifier its contents will be used to configure the classification algorithm
* --locations_config - path to locations configuration (json). 
* --files_format_config - a json file with configuration of file format (e.g., the separator
used in csv files).
* --chunk_size - the size of the batch of lines that will be read and processed (allows to read big files).

*Output:* 
* classify-output-\<classifier>.csv - result of classification stored in results folder of the workspace
* classify-output-\<classifer>-\<class>.csv - results filtered for a given class

### merge_results
This script is used to merge the results provided by different classifiers into a single file.

*Input:*
* --locations_config - path to locations configuration (json). The merger needs to know where
the workspace is located.
* --files_format_config - a json file with configuration of file format (e.g., the separator
used in csv files).
* --classifiers_options - a json file with classifiers options.
* --classes_config - a json file containing definitions of decision classes. 
* --chunk_size - the size of the batch of lines that will be read and processed (allows to read big files).

*Output:* 
* classify-output-ALL.csv - merges all results file found in results folder of the workspace
* classify-output-ALL-\<class>.csv - merges all results file found in results folder of the workspace
but filtered to contain only classification to a given class.

### generate_html
This script generates a simple html report from a given csv file.

*Input:*
* the first parameter is the name of the csv file that will be converted to html.
* the second paramter is the name of the output html file.
* --locations_config - path to locations configuration (json). The merger needs to know where
the workspace is located.
* --files_format_config - a json file with configuration of file format (e.g., the separator
used in csv files).
* --all - the flag is used without parameters; if present all the columns will be stored in
the output file, otherwise only 'id', 'contents',  and 'class_name'
* --chunk_size - the size of the batch of lines that will be read and processed (allows to read big files).
* --split_files - the flag is used without parameters; when used a separate html file will be generated 
for each chunk of lines (see --chunk_size).

*Output:* 
* <output file name> - a html file will be stored in reports folder in the workspace 

### active_learning

This script is a little bit different than the others and should be used a standalone tool to help
labeling the data. Once it is run, it will work interactively and ask the user to classify 
given lines (following the  Uncertainty Sampling strategy). 

```
Please, label the following lines:
src/common/enumiterator.h:
    10004      }
    10005      /* @} */
    10006  
>>> 10007   public:
    10008  
    10009      /** Creates a singular iterator. */
# Choose: [1]-count, [enter]-ignore, [q] to finish: 
```
*Input:*
* --input_files - the list of input files. These should be feautres csv files - all of them 
having exactly the same sets of features. They could have class_value column.
* --output_file - the resulting "training" file with labeled lines only.
* --base_learner - many active learning strategies use classifier to train it on the already 
labeled data and use it to predict which unlabeled data would be worth to label. The name
of the classifier should be the one of the available classifiers in py-ccflex (see 
classifiers_option.json file). Currently the supported ones are:
    * CART (sklearn)
    * RandomForest (sklearn)
* --locations_config - path to locations configuration (json). The merger needs to know where
the workspace is located.
* --files_format_config - a json file with configuration of file format (e.g., the separator
used in csv files).
* --classifiers_options - a json file with classifiers options.
* --add_contents -  the flag is used without parameters; if present a column 'contents'
will be added to the output file with the original text of the line.
* --classes_config - a json file containing definitions of decision classes.
* --max_lines - the maximum number of lines read from each of input files. 

*Output:* 
* <output file name> - a csv file stored in the processing folder of the workspace. 

### find_similar
This can be used to find inconsistencies in your training set (the same or very similar
lines labeled differently).

*Input:*
* the first parameter is the path to a feature file.
* --threshold_distance - a minimum Manhattan distance to treat a pair of lines as similar
(default 0)
* --tsne - if given, a t-SNE plot will be generated
* --files_format_config - a json file with configuration of file format (e.g., the separator
used in csv files).


*Output:* 
* <the first paramter>-similar.csv - file containing similar lines
* <the first paramter>-similar-dendr.csv - file containing a dendrogram tree showing similarities
* <the first paramter>-similar-tsne.csv - file containing a 2D t-SNE plot 