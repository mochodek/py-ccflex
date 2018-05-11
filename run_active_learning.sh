#!/bin/sh

LOCATIONS_CONFIG="./locations_mo.json"
CLASSES_CONFIG="./classes.json"
FILES_FORMAT_CONFIG="./files_format.json"
MANUAL_FEATURES_CONFIG="./manual_features.json"
CLASSIFIERS_CONFIG="./classifiers_options.json"
FEATURE_SELECTORS_CONFIG="./feature_selectors_options.json"

active_learning  --input_files "train-manual-bow.csv" "classify-manual-bow.csv" \
    --output_file "active_learning_input.csv" \
    --max_lines 500000 --use_existing_labels  \
    --base_learner "RandomForest" \
    --committee \
    --add_contents \
    --locations_config $LOCATIONS_CONFIG \
    --files_format_config $FILES_FORMAT_CONFIG \
    --classifiers_options $CLASSIFIERS_CONFIG \
    --classes_config $CLASSES_CONFIG



