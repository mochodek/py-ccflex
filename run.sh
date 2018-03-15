#!/bin/sh

CONFIG="./configuration.json"

create-storage --config_file $CONFIG
extract-lines2csv "train" --config_file $CONFIG
basic-manual-features "train" --add_decision_class true --add_contents true --config_file $CONFIG
extract-lines2csv "classify" --config_file $CONFIG
basic-manual-features "classify" --add_decision_class true --add_contents true --config_file $CONFIG