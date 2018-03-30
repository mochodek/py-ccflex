#!/bin/sh

LOCATIONS_CONFIG="./locations.json"
CLASSES_CONFIG="./classes.json"
FILES_FORMAT_CONFIG="./files_format.json"
MANUAL_FEATURES_CONFIG="./manual_features.json"
CLASSIFIERS_CONFIG="./classifiers_options.json"


# 1. create workspace
create_workspace --locations_config $LOCATIONS_CONFIG

# 2. read codebases, transform them to CSV, and extract features
lines2csv "train" --locations_config $LOCATIONS_CONFIG --classes_config $CLASSES_CONFIG --files_format_config $FILES_FORMAT_CONFIG
lines2csv "classify" --locations_config $LOCATIONS_CONFIG --classes_config $CLASSES_CONFIG --files_format_config $FILES_FORMAT_CONFIG

# manually defined features
predefined_manual_features "train" --add_decision_class --add_contents --locations_config $LOCATIONS_CONFIG --manual_features_config $MANUAL_FEATURES_CONFIG
predefined_manual_features "classify"  --add_contents --locations_config $LOCATIONS_CONFIG --manual_features_config $MANUAL_FEATURES_CONFIG

# bag of words
vocabulary_extractor "train-lines.csv"  "vocabulary.csv" --top_words_threshold 20 --token_signature_for_missing --min_ngrams 1 --max_ngrams 1 --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
bag_of_words "train" "vocabulary.csv" --min_ngrams 1 --max_ngrams 1 --token_signature_for_missing --add_decision_class --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
bag_of_words "classify" "vocabulary.csv" --min_ngrams 1 --max_ngrams 1 --token_signature_for_missing --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG

# 3. run classification algorithms
classify_CART "train-bag-of-words.csv" "classify-bag-of-words.csv" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
#classify_CART "train-basic-manual.csv" "classify-basic-manual.csv" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG

classify_RandomForest "train-bag-of-words.csv" "classify-bag-of-words.csv" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
#classify_RandomForest "train-basic-manual.csv" "classify-basic-manual.csv" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG

classify_KNN "train-bag-of-words.csv" "classify-bag-of-words.csv" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
#classify_KNN "train-basic-manual.csv" "classify-basic-manual.csv" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG

classify_MultinomialNB "train-bag-of-words.csv" "classify-bag-of-words.csv" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
#classify_MultinomialNB "train-basic-manual.csv" "classify-basic-manual.csv" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG

classify_c50_r "train-bag-of-words.csv" "classify-bag-of-words.csv" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
#classify_c50_r "train-basic-manual.csv" "classify-basic-manual.csv" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG

# 4. merge results to a single csv file
merge_results --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG

# 5. generate html reports
generate_html "processing/train-basic-manual.csv" "training-lines-manual-features.html" --all  --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
generate_html "processing/train-bag-of-words.csv" "training-lines-bow-features.html" --all  --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
generate_html "results/classify-output-ALL.csv" "classified-lines-ALL.html" --all --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
generate_html "results/classify-output-ALL-count.csv" "classified-lines-ALL-count.html" --all --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
