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
merge_inputs --input_files "train-basic-manual.csv" "train-bag-of-words.csv" --output_file "train-manual-and-bow.csv" --add_decision_class --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
merge_inputs --input_files "classify-basic-manual.csv" "classify-bag-of-words.csv" --output_file "classify-manual-and-bow.csv"  --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG

# add context +/- lines
add_seq_context  "train-manual-and-bow.csv" "train-manual-and-bow-ctx.csv" --prev_cases 1 --next_cases 1 --add_decision_class --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
add_seq_context  "classify-manual-and-bow.csv" "classify-manual-and-bow-ctx.csv" --prev_cases 1 --next_cases 1 --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG

# perform feature selection - remove duplicated features
select_features  "train-manual-and-bow-ctx.csv" "classify-manual-and-bow-ctx.csv" --output_file_prefix "min-" --feature_selector "VarianceThreshold" --add_decision_class --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --feature_selectors_options $FEATURE_SELECTORS_CONFIG

# 3. run classification algorithms
# train and classify using bag-of-words feature
#classify "train-bag-of-words.csv" "classify-bag-of-words.csv" --classifier "CART"  --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
#classify "train-bag-of-words.csv" "classify-bag-of-words.csv" --classifier "RandomForest"  --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
#classify "train-bag-of-words.csv" "classify-bag-of-words.csv" --classifier "C50"  --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
#classify "train-bag-of-words.csv" "classify-bag-of-words.csv" --classifier "MultinomialNB"  --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
#classify "train-bag-of-words.csv" "classify-bag-of-words.csv" --classifier "KNN"  --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG

# train and classify using manually defined features
#classify "train-basic-manual.csv" "classify-basic-manual.csv" --classifier "CART" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
#classify "train-basic-manual.csv" "classify-basic-manual.csv" --classifier "RandomForest" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
#classify "train-basic-manual.csv" "classify-basic-manual.csv" --classifier "C50" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
#classify "train-basic-manual.csv" "classify-basic-manual.csv" --classifier "MultinomialNB" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
#classify "train-basic-manual.csv" "classify-basic-manual.csv" --classifier "KNN"  --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG


# train and classify using both manually defined and bag-of-words feature
#classify "train-manual-and-bow.csv" "classify-manual-and-bow.csv" --classifier "CART" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
#classify "train-manual-and-bow.csv" "classify-manual-and-bow.csv" --classifier "RandomForest" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
#classify "train-manual-and-bow.csv" "classify-manual-and-bow.csv" --classifier "C50" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
#classify "train-manual-and-bow.csv" "classify-manual-and-bow.csv" --classifier "MultinomialNB" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
#classify "train-manual-and-bow.csv" "classify-manual-and-bow.csv" --classifier "KNN" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG

# train and classify using both manually defined and bag-of-words feature with +/- context lines
classify "min-train-manual-and-bow-ctx.csv" "min-classify-manual-and-bow-ctx.csv" --classifier "CART" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
classify "min-train-manual-and-bow-ctx.csv" "min-classify-manual-and-bow-ctx.csv" --classifier "RandomForest" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
classify "min-train-manual-and-bow-ctx.csv" "min-classify-manual-and-bow-ctx.csv" --classifier "C50" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
classify "min-train-manual-and-bow-ctx.csv" "min-classify-manual-and-bow-ctx.csv" --classifier "MultinomialNB" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
classify "min-train-manual-and-bow-ctx.csv" "min-classify-manual-and-bow-ctx.csv" --classifier "KNN" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG

# 4. merge results to a single csv file
merge_results --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG

# 5. generate html reports
generate_html "processing/train-basic-manual.csv" "training-lines-manual-features.html" --all  --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
generate_html "processing/train-bag-of-words.csv" "training-lines-bow-features.html" --all  --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
generate_html "results/classify-output-ALL.csv" "classified-lines-ALL.html" --all --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
generate_html "results/classify-output-ALL-count.csv" "classified-lines-ALL-count.html" --all --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
generate_html "results/classify-output-C50-count.csv" "classified-lines-C50-count.html" --all --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG



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
* \<location key>-basic-manual.csv - a file containing extracted features that could be used to train a classifer

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
This scripts allows to perform feature selection.

*Input:*
* the first parameter is the name of the file containing features for training set
* the second parameter is the name of the file containing features for set to classify
* --output_file_prefix - the prefix that will be added to output features files (training and classify) 
* --feature_selector - a feature selection algorithms:
    * VarianceThreshold - variance threshold - useful in eliminating duplicate features (sklearn)
* --feature_selectors_options - a json file with feature selector options. If it contains a key equal to 
the name of the feature selection algorithm its contents will be used to configure the feature selection algorithm
* --locations_config - path to locations configuration (json). 
* --files_format_config - a json file with configuration of file format (e.g., the separator
used in csv files).
* --add_decision_class - the flag is used without parameters; if present two columns will be added
to the output csv file - class_value and class_name.
* --add_contents -  the flag is used without parameters; if present a column 'contents'
will be added to the output file with the original text of the line.
* --classifiers_options - a json file with classifiers options. 
* --chunk_size - the size of the batch of lines that will be read and processed (allows to read big files).

*Output:* 
* <output_file_prefix><first parameter> - reduced training feature file
* <output_file_prefix><second parameter> - reduced classify feature file

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