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
basic-manual-features "classify" --add_decision_class false --add_contents true --locations_config $LOCATIONS_CONFIG --manual_features_config $MANUAL_FEATURES_CONFIG
vocabulary-extractor "classify-lines.csv" "vocabulary.csv" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG

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
