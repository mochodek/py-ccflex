#!/bin/sh

LOCATIONS_CONFIG="./locations.json"
CLASSES_CONFIG="./classes.json"
FILES_FORMAT_CONFIG="./files_format.json"
MANUAL_FEATURES_CONFIG="./manual_features.json"

create-storage --locations_config $LOCATIONS_CONFIG
lines2csv "train" --locations_config $LOCATIONS_CONFIG --classes_config $CLASSES_CONFIG --files_format_config $FILES_FORMAT_CONFIG
basic-manual-features "train" --add_decision_class true --add_contents true --locations_config $LOCATIONS_CONFIG --manual_features_config $MANUAL_FEATURES_CONFIG
lines2csv "classify" --locations_config $LOCATIONS_CONFIG --classes_config $CLASSES_CONFIG --files_format_config $FILES_FORMAT_CONFIG
basic-manual-features "classify" --add_decision_class true --add_contents true --locations_config $LOCATIONS_CONFIG --manual_features_config $MANUAL_FEATURES_CONFIG
classify "train-basic-manual.csv" "classify-basic-manual.csv" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG

