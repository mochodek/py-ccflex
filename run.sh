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

