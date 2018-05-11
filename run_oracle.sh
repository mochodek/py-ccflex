#!/bin/sh

LOCATIONS_CONFIG="./locations_mo.json"
CLASSES_CONFIG="./classes.json"
FILES_FORMAT_CONFIG="./files_format.json"
MANUAL_FEATURES_CONFIG="./manual_features.json"
CLASSIFIERS_CONFIG="./classifiers_options.json"
FEATURE_SELECTORS_CONFIG="./feature_selectors_options.json"

RUN_ORACLE=false

$RUN_ORACLE && lines_oracle  "classify-features.csv" "classify-output-oracle.csv"  \
    --oracle "len_max_120chars" \
    --add_contents \
    --locations_config $LOCATIONS_CONFIG \
    --files_format_config $FILES_FORMAT_CONFIG \
    --classes_config $CLASSES_CONFIG

evaluate_accuracy  "classify-output-oracle.csv" "classify-output-CART.csv"  \
    --locations_config $LOCATIONS_CONFIG \
    --files_format_config $FILES_FORMAT_CONFIG \
    --classes_config $CLASSES_CONFIG




