#!/bin/sh

LOCATIONS_CONFIG="./locations.json"
CLASSES_CONFIG="./classes.json"
BLOCK_CLASSES_CONFIG="./block_classes.json"
FILES_FORMAT_CONFIG="./files_format.json"
MANUAL_FEATURES_CONFIG="./manual_features.json"
CLASSIFIERS_CONFIG="./classifiers_options.json"
FEATURE_SELECTORS_CONFIG="./feature_selectors_options.json"

CREATE_WORKSPACE=true
LINES=true
LEARN_COMMENT_FEATURE=true
FEATURES=true
MANUAL_FEATURES=false
CTX_FEATURES=false
BOW_FEATURES=true
CLASSIFY=true
REPORT=true

MANUAL_FEATURE_EXTRACTORS="PatternSubstringExctractor PatternWordExtractor CommentStringExtractor NoWordsExtractor NoCharsExtractor"

TRAIN_LOCATION="train"
COMMENTS_TRAIN_LOCATION="comments-train"

# Create workspace directory
$CREATE_WORKSPACE && create_workspace --locations_config $LOCATIONS_CONFIG

# Copy comments training file into the workspace
$FEATURES && $LEARN_COMMENT_FEATURE  && copy_builtin_training_file "comments-train-lines.csv" --locations_config $LOCATIONS_CONFIG

# Prepare vocabulary for bag of words
$LINES && lines2csv "${TRAIN_LOCATION}" --locations_config $LOCATIONS_CONFIG --classes_config $CLASSES_CONFIG --files_format_config $FILES_FORMAT_CONFIG
$FEATURES && $BOW_FEATURES  && vocabulary_extractor "${TRAIN_LOCATION}-lines.csv"  "vocabulary.csv" --top_words_threshold 10 --token_signature_for_missing --min_ngrams 1 --max_ngrams 2 --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG

# Prepare dataset to train a classifier for adding block comment feature (blocks and one-line comments)
$FEATURES && $LEARN_COMMENT_FEATURE && $MANUAL_FEATURES  && predefined_manual_features "$COMMENTS_TRAIN_LOCATION" --extractors $MANUAL_FEATURE_EXTRACTORS --add_decision_class --add_contents --locations_config $LOCATIONS_CONFIG --manual_features_config $MANUAL_FEATURES_CONFIG
$FEATURES && $LEARN_COMMENT_FEATURE && $CTX_FEATURES && $MANUAL_FEATURES && add_seq_context  "${COMMENTS_TRAIN_LOCATION}-manual.csv" "${COMMENTS_TRAIN_LOCATION}-manual-ctx.csv" --prev_cases 1 --next_cases 1 --add_decision_class --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
$FEATURES && $LEARN_COMMENT_FEATURE && $BOW_FEATURES && bag_of_words "${COMMENTS_TRAIN_LOCATION}" "vocabulary.csv" --min_ngrams 1 --max_ngrams 2 --token_signature_for_missing --add_decision_class --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG

$FEATURES && $LEARN_COMMENT_FEATURE && ! $CTX_FEATURES && $MANUAL_FEATURES && $BOW_FEATURES && merge_inputs --input_files "${COMMENTS_TRAIN_LOCATION}-manual.csv" "${COMMENTS_TRAIN_LOCATION}-bag-of-words.csv" --output_file "${COMMENTS_TRAIN_LOCATION}-manual-bow.csv" --add_decision_class --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
$FEATURES && $LEARN_COMMENT_FEATURE && $CTX_FEATURES && $MANUAL_FEATURES && $BOW_FEATURES && merge_inputs --input_files "${COMMENTS_TRAIN_LOCATION}-manual-ctx.csv" "${COMMENTS_TRAIN_LOCATION}-bag-of-words.csv" --output_file "${COMMENTS_TRAIN_LOCATION}-manual-ctx-bow.csv" --add_decision_class --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG


# Prepare a training set
$FEATURES && $MANUAL_FEATURES  && predefined_manual_features "${TRAIN_LOCATION}" --extractors $MANUAL_FEATURE_EXTRACTORS --add_decision_class --add_contents --locations_config $LOCATIONS_CONFIG --manual_features_config $MANUAL_FEATURES_CONFIG
$FEATURES && $CTX_FEATURES && $MANUAL_FEATURES && add_seq_context  "${TRAIN_LOCATION}-manual.csv" "${TRAIN_LOCATION}-manual-ctx.csv" --prev_cases 1 --next_cases 1 --add_decision_class --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
$FEATURES && $BOW_FEATURES && bag_of_words "${TRAIN_LOCATION}" "vocabulary.csv" --min_ngrams 1 --max_ngrams 2 --token_signature_for_missing --add_decision_class --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG

$FEATURES && ! $CTX_FEATURES && $MANUAL_FEATURES && $BOW_FEATURES && merge_inputs --input_files "${TRAIN_LOCATION}-manual.csv" "${TRAIN_LOCATION}-bag-of-words.csv" --output_file "${TRAIN_LOCATION}-manual-bow.csv" --add_decision_class --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
$FEATURES && $CTX_FEATURES && $MANUAL_FEATURES && $BOW_FEATURES && merge_inputs --input_files "${TRAIN_LOCATION}-manual-ctx.csv" "${TRAIN_LOCATION}-bag-of-words.csv" --output_file "${TRAIN_LOCATION}-manual-ctx-bow.csv" --add_decision_class --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG

$FEATURES && $LEARN_COMMENT_FEATURE && $MANUAL_FEATURES && ! $CTX_FEATURES && ! $BOW_FEATURES && classify "${COMMENTS_TRAIN_LOCATION}-manual.csv" "${TRAIN_LOCATION}-manual.csv" --classifier "CART" --output_prefix "comments-${TRAIN_LOCATION}-" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $BLOCK_CLASSES_CONFIG
$FEATURES && $LEARN_COMMENT_FEATURE && $MANUAL_FEATURES && $CTX_FEATURES && ! $BOW_FEATURES && classify "${COMMENTS_TRAIN_LOCATION}-manual-ctx.csv" "${TRAIN_LOCATION}-manual-ctx.csv" --classifier "CART" --output_prefix "comments-${TRAIN_LOCATION}-" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $BLOCK_CLASSES_CONFIG
$FEATURES && $LEARN_COMMENT_FEATURE && ! $MANUAL_FEATURES && ! $CTX_FEATURES && $BOW_FEATURES && classify "${COMMENTS_TRAIN_LOCATION}-bag-of-words.csv" "${TRAIN_LOCATION}-bag-of-words.csv" --classifier "CART" --output_prefix "comments-${TRAIN_LOCATION}-" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $BLOCK_CLASSES_CONFIG
$FEATURES && $LEARN_COMMENT_FEATURE && $MANUAL_FEATURES && ! $CTX_FEATURES && $BOW_FEATURES && classify "${COMMENTS_TRAIN_LOCATION}-manual-bow.csv" "${TRAIN_LOCATION}-manual-bow.csv" --classifier "CART" --output_prefix "comments-${TRAIN_LOCATION}-" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $BLOCK_CLASSES_CONFIG
$FEATURES && $LEARN_COMMENT_FEATURE && $MANUAL_FEATURES && $CTX_FEATURES && $BOW_FEATURES && classify "${COMMENTS_TRAIN_LOCATION}-manual-ctx-bow.csv" "${TRAIN_LOCATION}-manual-ctx-bow.csv" --classifier "CART" --output_prefix "comments-${TRAIN_LOCATION}-" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $BLOCK_CLASSES_CONFIG

$FEATURES && $LEARN_COMMENT_FEATURE && extract_block_features "comments-${TRAIN_LOCATION}-classify-output-CART.csv" "${TRAIN_LOCATION}-comments.csv" "full_comment" --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --block_classes_config $BLOCK_CLASSES_CONFIG

$FEATURES && $LEARN_COMMENT_FEATURE && $MANUAL_FEATURES && ! $CTX_FEATURES && ! $BOW_FEATURES && merge_inputs --input_files "${TRAIN_LOCATION}-manual.csv" "${TRAIN_LOCATION}-comments.csv" --output_file "${TRAIN_LOCATION}-merge-comments.csv" --add_decision_class --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
$FEATURES && $LEARN_COMMENT_FEATURE && $MANUAL_FEATURES && $CTX_FEATURES && ! $BOW_FEATURES && merge_inputs --input_files "${TRAIN_LOCATION}-manual-ctx.csv" "${TRAIN_LOCATION}-comments.csv" --output_file "${TRAIN_LOCATION}-merge-comments.csv" --add_decision_class --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
$FEATURES && $LEARN_COMMENT_FEATURE && ! $MANUAL_FEATURES && ! $CTX_FEATURES && $BOW_FEATURES && merge_inputs --input_files "${TRAIN_LOCATION}-bag-of-words.csv" "${TRAIN_LOCATION}-comments.csv" --output_file "${TRAIN_LOCATION}-merge-comments.csv" --add_decision_class --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
$FEATURES && $LEARN_COMMENT_FEATURE && $MANUAL_FEATURES && ! $CTX_FEATURES && $BOW_FEATURES && merge_inputs --input_files "${TRAIN_LOCATION}-manual-bow.csv" "${TRAIN_LOCATION}-comments.csv" --output_file "${TRAIN_LOCATION}-merge-comments.csv" --add_decision_class --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
$FEATURES && $LEARN_COMMENT_FEATURE && $MANUAL_FEATURES && $CTX_FEATURES && $BOW_FEATURES && merge_inputs --input_files "${TRAIN_LOCATION}-manual-ctx-bow.csv" "${TRAIN_LOCATION}-comments.csv" --output_file "${TRAIN_LOCATION}-merge-comments.csv" --add_decision_class --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG

# Classify location  (if you have more locations defined, copy the whole part and change CLASSIFY_LOCATION)
CLASSIFY_LOCATION="classify"
$LINES && lines2csv "${CLASSIFY_LOCATION}" --locations_config $LOCATIONS_CONFIG --classes_config $CLASSES_CONFIG --files_format_config $FILES_FORMAT_CONFIG

$FEATURES && $MANUAL_FEATURES  && predefined_manual_features "${CLASSIFY_LOCATION}"  --extractors $MANUAL_FEATURE_EXTRACTORS --add_contents --locations_config $LOCATIONS_CONFIG --manual_features_config $MANUAL_FEATURES_CONFIG
$FEATURES && $CTX_FEATURES && $MANUAL_FEATURES && add_seq_context  "${CLASSIFY_LOCATION}-manual.csv" "${CLASSIFY_LOCATION}-manual-ctx.csv" --prev_cases 1 --next_cases 1  --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
$FEATURES && $BOW_FEATURES && bag_of_words "${CLASSIFY_LOCATION}" "vocabulary.csv" --min_ngrams 1 --max_ngrams 2 --token_signature_for_missing  --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG

$FEATURES && ! $CTX_FEATURES && $MANUAL_FEATURES && $BOW_FEATURES && merge_inputs --input_files "${CLASSIFY_LOCATION}-manual.csv" "${CLASSIFY_LOCATION}-bag-of-words.csv" --output_file "${CLASSIFY_LOCATION}-manual-bow.csv"  --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
$FEATURES && $CTX_FEATURES && $MANUAL_FEATURES && $BOW_FEATURES && merge_inputs --input_files "${CLASSIFY_LOCATION}-manual-ctx.csv" "${CLASSIFY_LOCATION}-bag-of-words.csv" --output_file "${CLASSIFY_LOCATION}-manual-ctx-bow.csv"  --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG

$FEATURES && $LEARN_COMMENT_FEATURE && $MANUAL_FEATURES && ! $CTX_FEATURES && ! $BOW_FEATURES && classify "${COMMENTS_TRAIN_LOCATION}-manual.csv" "${CLASSIFY_LOCATION}-manual.csv" --classifier "CART" --output_prefix "comments-${CLASSIFY_LOCATION}-" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $BLOCK_CLASSES_CONFIG
$FEATURES && $LEARN_COMMENT_FEATURE && $MANUAL_FEATURES && $CTX_FEATURES && ! $BOW_FEATURES && classify "${COMMENTS_TRAIN_LOCATION}-manual-ctx.csv" "${CLASSIFY_LOCATION}-manual-ctx.csv" --classifier "CART" --output_prefix "comments-${CLASSIFY_LOCATION}-" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $BLOCK_CLASSES_CONFIG
$FEATURES && $LEARN_COMMENT_FEATURE && ! $MANUAL_FEATURES && ! $CTX_FEATURES && $BOW_FEATURES && classify "${COMMENTS_TRAIN_LOCATION}-bag-of-words.csv" "${CLASSIFY_LOCATION}-bag-of-words.csv" --classifier "CART" --output_prefix "comments-${CLASSIFY_LOCATION}-" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $BLOCK_CLASSES_CONFIG
$FEATURES && $LEARN_COMMENT_FEATURE && $MANUAL_FEATURES && ! $CTX_FEATURES && $BOW_FEATURES && classify "${COMMENTS_TRAIN_LOCATION}-manual-bow.csv" "${CLASSIFY_LOCATION}-manual-bow.csv" --classifier "CART" --output_prefix "comments-${CLASSIFY_LOCATION}-" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $BLOCK_CLASSES_CONFIG
$FEATURES && $LEARN_COMMENT_FEATURE && $MANUAL_FEATURES && $CTX_FEATURES && $BOW_FEATURES && classify "${COMMENTS_TRAIN_LOCATION}-manual-ctx-bow.csv"  "${CLASSIFY_LOCATION}-manual-ctx-bow.csv" --classifier "CART" --output_prefix "comments-${CLASSIFY_LOCATION}-" --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $BLOCK_CLASSES_CONFIG

$FEATURES && $LEARN_COMMENT_FEATURE && extract_block_features "comments-${CLASSIFY_LOCATION}-classify-output-CART.csv" "${CLASSIFY_LOCATION}-comments.csv" "full_comment" --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --block_classes_config $BLOCK_CLASSES_CONFIG

$FEATURES && $LEARN_COMMENT_FEATURE && $MANUAL_FEATURES && ! $CTX_FEATURES && ! $BOW_FEATURES && merge_inputs --input_files "${CLASSIFY_LOCATION}-manual.csv" "${CLASSIFY_LOCATION}-comments.csv" --output_file "${CLASSIFY_LOCATION}-merge-comments.csv"  --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
$FEATURES && $LEARN_COMMENT_FEATURE && $MANUAL_FEATURES && $CTX_FEATURES && ! $BOW_FEATURES && merge_inputs --input_files "${CLASSIFY_LOCATION}-manual-ctx.csv" "${CLASSIFY_LOCATION}-comments.csv" --output_file "${CLASSIFY_LOCATION}-merge-comments.csv"  --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
$FEATURES && $LEARN_COMMENT_FEATURE && ! $MANUAL_FEATURES && ! $CTX_FEATURES && $BOW_FEATURES && merge_inputs --input_files "${CLASSIFY_LOCATION}-bag-of-words.csv" "${CLASSIFY_LOCATION}-comments.csv" --output_file "${CLASSIFY_LOCATION}-merge-comments.csv"  --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
$FEATURES && $LEARN_COMMENT_FEATURE && $MANUAL_FEATURES && ! $CTX_FEATURES && $BOW_FEATURES && merge_inputs --input_files "${CLASSIFY_LOCATION}-manual-bow.csv" "${CLASSIFY_LOCATION}-comments.csv" --output_file "${CLASSIFY_LOCATION}-merge-comments.csv"  --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
$FEATURES && $LEARN_COMMENT_FEATURE && $MANUAL_FEATURES && $CTX_FEATURES && $BOW_FEATURES && merge_inputs --input_files "${CLASSIFY_LOCATION}-manual-ctx-bow.csv" "${CLASSIFY_LOCATION}-comments.csv" --output_file "${CLASSIFY_LOCATION}-merge-comments.csv"  --add_contents --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG

# Classifying using a single classifier (to have more copy these line and change the classifier)
$CLASSIFY && $LEARN_COMMENT_FEATURE && classify "${TRAIN_LOCATION}-merge-comments.csv" "${CLASSIFY_LOCATION}-merge-comments.csv" --classifier "CART" --chunk_size 20000 --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
$CLASSIFY && ! $LEARN_COMMENT_FEATURE && $MANUAL_FEATURES && ! $CTX_FEATURES && ! $BOW_FEATURES && classify "${TRAIN_LOCATION}-manual.csv" "${CLASSIFY_LOCATION}-manual.csv" --classifier "CART" --chunk_size 20000 --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
$CLASSIFY && ! $LEARN_COMMENT_FEATURE && $MANUAL_FEATURES && $CTX_FEATURES && ! $BOW_FEATURES && classify "${TRAIN_LOCATION}-manual-ctx.csv" "${CLASSIFY_LOCATION}-manual-ctx.csv" --classifier "CART" --chunk_size 20000 --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
$CLASSIFY && ! $LEARN_COMMENT_FEATURE && ! $MANUAL_FEATURES && ! $CTX_FEATURES && $BOW_FEATURES && classify "${TRAIN_LOCATION}-bag-of-words.csv" "${CLASSIFY_LOCATION}-bag-of-words.csv" --classifier "CART" --chunk_size 20000 --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
$CLASSIFY && ! $LEARN_COMMENT_FEATURE && $MANUAL_FEATURES && ! $CTX_FEATURES && $BOW_FEATURES && classify "${TRAIN_LOCATION}-manual-bow.csv" "${CLASSIFY_LOCATION}-manual-bow.csv" --classifier "CART" --chunk_size 20000 --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG
$CLASSIFY && ! $LEARN_COMMENT_FEATURE && $MANUAL_FEATURES && $CTX_FEATURES && $BOW_FEATURES && classify "${TRAIN_LOCATION}-manual-ctx-bow.csv" "${CLASSIFY_LOCATION}-manual-ctx-bow.csv" --classifier "CART" --chunk_size 20000 --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG


# merge results to a single csv file
$CLASSIFY && merge_results --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG --classifiers_options $CLASSIFIERS_CONFIG --classes_config $CLASSES_CONFIG

# generate reports
$REPORT && generate_html "results/classify-output-ALL.csv" "classified-lines-ALL.html" --all --split_files --chunk_size 20000 --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
$REPORT && generate_html "results/classify-output-ALL-count.csv" "classified-lines-ALL-count.html" --all --split_files --chunk_size 20000 --locations_config $LOCATIONS_CONFIG --files_format_config $FILES_FORMAT_CONFIG
