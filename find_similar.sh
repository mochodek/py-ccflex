#!/bin/sh

FILES_FORMAT_CONFIG="./files_format.json"

find_similar "some features file.csv" \
             --threshold_distance 0 --files_format_config $FILES_FORMAT_CONFIG