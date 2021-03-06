#!/bin/sh

LOCATIONS_CONFIG="./locations.json"
CLASSES_CONFIG="./classes.json"
BLOCK_CLASSES_CONFIG="./block_classes.json"
FILES_FORMAT_CONFIG="./files_format.json"
MANUAL_FEATURES_CONFIG="./manual_features.json"
CLASSIFIERS_CONFIG="./classifiers_options.json"
FEATURE_SELECTORS_CONFIG="./feature_selectors_options.json"

TRAIN_LOCATION="train"
CLASSIFY_LOCATION="classify"

# Processing options
CREATE_WORKSPACE=true
LINES=true
FEATURES=true
FEATURE_SELECTION=false
CONTEXT=false
CLASSIFY=true
REPORT=true
TEAR_DOWN=true

# To sample lines from classification output (could be used to label and train)
SAMPLE_LINES=true
LINES_PER_FILE_TO_SAMPLE=50

# Shall the codebase to classify be preprocess - sometimes it is not
# required and codebase is big so you want to skip it and manually copy the files that would generate for hours
PREPROCESS_CLASSIFY=true

# To evaluate accuracy you have to edit these two variables
EVALUATE_ACCURACY=true
# available oracles: "braces_compound" "ifdefine" "define" "enum_class"
#       "one_statement_in_line" "len_max_120chars"
#        "named_constants"
#        "func_lower_camel_case"
ORACLE="define"

# True if you want to remove duplicates from a training set
REMOVE_DUPLICATES_FROM_TRAINING=false

# MAX_GRAM could be 1, 2 or 3 used for bag of words
MIN_NGRAM=1
MAX_NGRAM=3

# If CONTEXT set to true how many lines
CONTEXT_LINES_PREV=1
CONTEXT_LINES_FRWD=1

# Available extractors "PatternSubstringExctractor PatternWordExtractor WholeLineCommentFeatureExtraction CommentStringExtractor NoWordsExtractor NoCharsExtractor"
MANUAL_FEATURE_EXTRACTORS="PatternSubstringExctractor PatternWordExtractor WholeLineCommentFeatureExtraction NoWordsExtractor NoCharsExtractor"

CLASSIFIERS=( "CART" "RandomForest")


if $REMOVE_DUPLICATES_FROM_TRAINING
then
    REMOVE_DUPLICATE_PARAM="--remove_duplicates"
else
    REMOVE_DUPLICATE_PARAM=""
fi

# === Create workspace ===
$CREATE_WORKSPACE && create_workspace --locations_config $LOCATIONS_CONFIG

# === Copy vocabulary files ===
$FEATURES && copy_builtin_training_file "base-cpp-vocabulary.csv" --locations_config $LOCATIONS_CONFIG

# === TRAINING ===

# === Read training code ===
$LINES && lines2csv "${TRAIN_LOCATION}" $REMOVE_DUPLICATE_PARAM \
	--locations_config $LOCATIONS_CONFIG \
	--classes_config $CLASSES_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG

# === Feature exctraction for training set ===

$FEATURES  && vocabulary_extractor "${TRAIN_LOCATION}-lines.csv"  "cpp-vocabulary.csv" \
	--skip_generating_base_vocabulary \
	--top_words_threshold 200 \
	--token_signature_for_missing \
	--min_ngrams $MIN_NGRAM --max_ngrams $MAX_NGRAM \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG

# Manual features
$FEATURES  && predefined_manual_features "$TRAIN_LOCATION" \
	--extractors $MANUAL_FEATURE_EXTRACTORS \
	--add_decision_class \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--manual_features_config $MANUAL_FEATURES_CONFIG

# Bag of words
$FEATURES && bag_of_words "${TRAIN_LOCATION}" "cpp-vocabulary.csv" \
	--min_ngrams $MIN_NGRAM --max_ngrams $MAX_NGRAM \
	--token_signature_for_missing \
	--add_decision_class --add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG \
	--chunk_size 10000

$FEATURES && merge_inputs --input_files "${TRAIN_LOCATION}-bag-of-words.csv" "${TRAIN_LOCATION}-manual.csv" \
	--output_file "${TRAIN_LOCATION}-features.csv" \
	--add_decision_class \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG
$FEATURES && copy_feature_file "${TRAIN_LOCATION}-features.csv" "${TRAIN_LOCATION}-features-tmp.csv" \
    --locations_config $LOCATIONS_CONFIG

# Block comments
$FEATURES && extract_block_features_from_features "${TRAIN_LOCATION}-features.csv" "${TRAIN_LOCATION}-comments.csv" "block_comment" --feature_start "/ *"  --feature_end "* /"  \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG

$FEATURES && merge_inputs --input_files "${TRAIN_LOCATION}-features-tmp.csv" "${TRAIN_LOCATION}-comments.csv" \
	--output_file "${TRAIN_LOCATION}-features.csv" \
	--add_decision_class \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG
$FEATURES && copy_feature_file "${TRAIN_LOCATION}-features.csv" "${TRAIN_LOCATION}-features-tmp.csv" \
    --locations_config $LOCATIONS_CONFIG

# Blocks
$FEATURES && extract_block_features_from_features "${TRAIN_LOCATION}-features.csv" "${TRAIN_LOCATION}-blocks.csv" "block_code" --feature_start "{"  --feature_end "}"  \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--forbidding_features "block_comment" "whole_line_comment" \
	--files_format_config $FILES_FORMAT_CONFIG

$FEATURES && merge_inputs --input_files "${TRAIN_LOCATION}-features-tmp.csv" "${TRAIN_LOCATION}-blocks.csv" \
	--output_file "${TRAIN_LOCATION}-features.csv" \
	--add_decision_class \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG
$FEATURES && copy_feature_file "${TRAIN_LOCATION}-features.csv" "${TRAIN_LOCATION}-features-tmp.csv" \
    --locations_config $LOCATIONS_CONFIG

# Enums
$FEATURES && extract_block_features_from_features "${TRAIN_LOCATION}-features.csv" "${TRAIN_LOCATION}-enum.csv" "in_enum" --feature_start "enum  "  --feature_end ";" "} ;"  \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--forbidding_features "block_comment" "whole_line_comment" \
	--files_format_config $FILES_FORMAT_CONFIG

$FEATURES && merge_inputs --input_files "${TRAIN_LOCATION}-features-tmp.csv" "${TRAIN_LOCATION}-enum.csv" \
	--output_file "${TRAIN_LOCATION}-features.csv" \
	--add_decision_class \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG
$FEATURES && copy_feature_file "${TRAIN_LOCATION}-features.csv" "${TRAIN_LOCATION}-features-tmp.csv" \
    --locations_config $LOCATIONS_CONFIG

# Feature selection low variance
$FEATURE_SELECTION && $FEATURES && select_features "${TRAIN_LOCATION}-features.csv" "low_var_features.csv" \
	--feature_selector "VarianceThreshold" \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG \
	--feature_selectors_options $FEATURE_SELECTORS_CONFIG \
	--classifiers_options $CLASSIFIERS_CONFIG

$FEATURE_SELECTION && $FEATURES && apply_features_selection "${TRAIN_LOCATION}-features-tmp.csv" "${TRAIN_LOCATION}-features.csv" "low_var_features.csv" \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG \
	--chunk_size 10000
$FEATURE_SELECTION &&  $FEATURES && copy_feature_file "${TRAIN_LOCATION}-features.csv" "${TRAIN_LOCATION}-features-tmp.csv" \
    --locations_config $LOCATIONS_CONFIG

# Feature selection
$FEATURE_SELECTION && $FEATURES && ! $CONTEXT && select_features "${TRAIN_LOCATION}-features.csv" "selected_features.csv" \
	--feature_selector "SelectFpr" \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG \
	--feature_selectors_options $FEATURE_SELECTORS_CONFIG \
	--classifiers_options $CLASSIFIERS_CONFIG

$FEATURE_SELECTION && $FEATURES && ! $CONTEXT && apply_features_selection "${TRAIN_LOCATION}-features-tmp.csv" "${TRAIN_LOCATION}-features.csv" "selected_features.csv" \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG \
	--chunk_size 10000
$FEATURE_SELECTION && $FEATURES && ! $CONTEXT && copy_feature_file "${TRAIN_LOCATION}-features.csv" "${TRAIN_LOCATION}-features-tmp.csv" \
    --locations_config $LOCATIONS_CONFIG

# Conext
$FEATURES && $CONTEXT && add_seq_context  "${TRAIN_LOCATION}-features-tmp.csv" "${TRAIN_LOCATION}-features.csv" \
	--prev_cases $CONTEXT_LINES_PREV --next_cases $CONTEXT_LINES_FRWD \
	--add_decision_class \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG
$FEATURES && $CONTEXT && copy_feature_file "${TRAIN_LOCATION}-features.csv" "${TRAIN_LOCATION}-features-tmp.csv" \
    --locations_config $LOCATIONS_CONFIG

$FEATURE_SELECTION && $FEATURES && $CONTEXT && select_features "${TRAIN_LOCATION}-features.csv" "ctx_selected_features.csv" \
	--feature_selector "SelectFpr" \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG \
	--feature_selectors_options $FEATURE_SELECTORS_CONFIG \
	--classifiers_options $CLASSIFIERS_CONFIG

$FEATURE_SELECTION && $FEATURES && $CONTEXT && apply_features_selection "${TRAIN_LOCATION}-features-tmp.csv" "${TRAIN_LOCATION}-features.csv" "ctx_selected_features.csv" \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG \
	--chunk_size 10000
$FEATURE_SELECTION && $FEATURES && $CONTEXT && copy_feature_file "${TRAIN_LOCATION}-features.csv" "${TRAIN_LOCATION}-features-tmp.csv" \
    --locations_config $LOCATIONS_CONFIG


# === PREPARE CLASSIFY ===

if $PREPROCESS_CLASSIFY
then

# === Read training code ===
$LINES && lines2csv "${CLASSIFY_LOCATION}" \
	--locations_config $LOCATIONS_CONFIG \
	--classes_config $CLASSES_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG


# === Feature exctraction for training set ===

# Manual features
$FEATURES  && predefined_manual_features "$CLASSIFY_LOCATION" \
	--extractors $MANUAL_FEATURE_EXTRACTORS \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--manual_features_config $MANUAL_FEATURES_CONFIG

# Bag of words
$FEATURES && bag_of_words "${CLASSIFY_LOCATION}" "cpp-vocabulary.csv" \
	--min_ngrams $MIN_NGRAM --max_ngrams $MAX_NGRAM \
	--token_signature_for_missing \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG \
	--chunk_size 10000

$FEATURES && merge_inputs --input_files "${CLASSIFY_LOCATION}-bag-of-words.csv" "${CLASSIFY_LOCATION}-manual.csv" \
	--output_file "${CLASSIFY_LOCATION}-features.csv" \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG
$FEATURES && copy_feature_file "${CLASSIFY_LOCATION}-features.csv" "${CLASSIFY_LOCATION}-features-tmp.csv" \
    --locations_config $LOCATIONS_CONFIG

# Block comments
$FEATURES && extract_block_features_from_features "${CLASSIFY_LOCATION}-features.csv" "${CLASSIFY_LOCATION}-comments.csv" "block_comment" --feature_start "/ *"  --feature_end "* /"  \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG

$FEATURES && merge_inputs --input_files "${CLASSIFY_LOCATION}-features-tmp.csv" "${CLASSIFY_LOCATION}-comments.csv" \
	--output_file "${CLASSIFY_LOCATION}-features.csv" \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG
$FEATURES && copy_feature_file "${CLASSIFY_LOCATION}-features.csv" "${CLASSIFY_LOCATION}-features-tmp.csv" \
    --locations_config $LOCATIONS_CONFIG

# Blocks
$FEATURES && extract_block_features_from_features "${CLASSIFY_LOCATION}-features.csv" "${CLASSIFY_LOCATION}-blocks.csv" "block_code" --feature_start "{"  --feature_end "}"  \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--forbidding_features "block_comment" "whole_line_comment" \
	--files_format_config $FILES_FORMAT_CONFIG

$FEATURES && merge_inputs --input_files "${CLASSIFY_LOCATION}-features-tmp.csv" "${CLASSIFY_LOCATION}-blocks.csv" \
	--output_file "${CLASSIFY_LOCATION}-features.csv" \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG
$FEATURES && copy_feature_file "${CLASSIFY_LOCATION}-features.csv" "${CLASSIFY_LOCATION}-features-tmp.csv" \
    --locations_config $LOCATIONS_CONFIG

# Enums
$FEATURES && extract_block_features_from_features "${CLASSIFY_LOCATION}-features.csv" "${CLASSIFY_LOCATION}-enum.csv" "in_enum" --feature_start "enum  "  --feature_end ";" "} ;"  \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--forbidding_features "block_comment" "whole_line_comment" \
	--files_format_config $FILES_FORMAT_CONFIG

$FEATURES && merge_inputs --input_files "${CLASSIFY_LOCATION}-features-tmp.csv" "${CLASSIFY_LOCATION}-enum.csv" \
	--output_file "${CLASSIFY_LOCATION}-features.csv" \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG
$FEATURES && copy_feature_file "${CLASSIFY_LOCATION}-features.csv" "${CLASSIFY_LOCATION}-features-tmp.csv" \
    --locations_config $LOCATIONS_CONFIG

# Feature selection low variance
$FEATURE_SELECTION && $FEATURES && apply_features_selection "${CLASSIFY_LOCATION}-features-tmp.csv" "${CLASSIFY_LOCATION}-features.csv" "low_var_features.csv" \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG \
	--chunk_size 10000
$FEATURE_SELECTION && $FEATURES && copy_feature_file "${CLASSIFY_LOCATION}-features.csv" "${CLASSIFY_LOCATION}-features-tmp.csv" \
    --locations_config $LOCATIONS_CONFIG

# Feature selection
$FEATURE_SELECTION && $FEATURES && ! $CONTEXT && apply_features_selection "${CLASSIFY_LOCATION}-features-tmp.csv" "${CLASSIFY_LOCATION}-features.csv" "selected_features.csv" \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG \
	--chunk_size 10000
$FEATURE_SELECTION && $FEATURES && ! $CONTEXT && copy_feature_file "${CLASSIFY_LOCATION}-features.csv" "${CLASSIFY_LOCATION}-features-tmp.csv" \
    --locations_config $LOCATIONS_CONFIG

# Conext
$FEATURES && $CONTEXT && add_seq_context  "${CLASSIFY_LOCATION}-features-tmp.csv" "${CLASSIFY_LOCATION}-features.csv" \
	--prev_cases $CONTEXT_LINES_PREV --next_cases $CONTEXT_LINES_FRWD \
	--add_decision_class \
	--add_contents \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG
$FEATURES && $CONTEXT && copy_feature_file "${CLASSIFY_LOCATION}-features.csv" "${CLASSIFY_LOCATION}-features-tmp.csv" \
    --locations_config $LOCATIONS_CONFIG

$FEATURE_SELECTION && $FEATURES && $CONTEXT && apply_features_selection "${CLASSIFY_LOCATION}-features-tmp.csv" "${CLASSIFY_LOCATION}-features.csv" "ctx_selected_features.csv" \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG \
	--chunk_size 10000
$FEATURE_SELECTION && $FEATURES && $CONTEXT && copy_feature_file "${CLASSIFY_LOCATION}-features.csv" "${CLASSIFY_LOCATION}-features-tmp.csv" \
    --locations_config $LOCATIONS_CONFIG


# === REMOVING FEATURE EXTRACTION TEMPORARY FILES ===
# This should be always at the end of feature selection
$TEAR_DOWN && $FEATURES && delete_processing_file "${TRAIN_LOCATION}-features-tmp.csv" --locations_config $LOCATIONS_CONFIG
$TEAR_DOWN && $FEATURES && delete_processing_file "${CLASSIFY_LOCATION}-features-tmp.csv" --locations_config $LOCATIONS_CONFIG

fi

# === CLASSIFY ====
for CLASSIFIER in "${CLASSIFIERS[@]}"
do
	$CLASSIFY && classify "${TRAIN_LOCATION}-features.csv" "${CLASSIFY_LOCATION}-features.csv" \
	--classifier "${CLASSIFIER}" \
	--chunk_size 20000 \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG \
	--classifiers_options $CLASSIFIERS_CONFIG \
	--classes_config $CLASSES_CONFIG
done

# merge results to a single csv file
$CLASSIFY && merge_results --locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG \
	--classifiers_options $CLASSIFIERS_CONFIG \
	--classes_config $CLASSES_CONFIG


# === REPORT ====
# generate reports
$REPORT && generate_html "results/classify-output-ALL.csv" "classified-lines-ALL.html" \
	--all --split_files --chunk_size 20000 \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG

$REPORT && generate_html "results/classify-output-ALL-count.csv" "classified-lines-ALL-count.html" \
	--all --split_files --chunk_size 20000 \
	--locations_config $LOCATIONS_CONFIG \
	--files_format_config $FILES_FORMAT_CONFIG


# ===== SAMPLE LINES ====
$SAMPLE_LINES &&  sample_lines sample_lines.txt --files "classify-output-ALL-ignore.csv" "classify-output-ALL-count.csv"  \
    --lines $LINES_PER_FILE_TO_SAMPLE \
    --locations_config $LOCATIONS_CONFIG \
    --files_format_config $FILES_FORMAT_CONFIG


#==== EVALUATE ACCURACY ===

$EVALUATE_ACCURACY && lines_oracle  "classify-features.csv" "classify-output-oracle.csv"  \
    --oracle $ORACLE \
    --add_contents \
    --locations_config $LOCATIONS_CONFIG \
    --files_format_config $FILES_FORMAT_CONFIG \
    --classes_config $CLASSES_CONFIG

for CLASSIFIER in "${CLASSIFIERS[@]}"
do
$EVALUATE_ACCURACY && evaluate_accuracy  "classify-output-oracle.csv" "classify-output-${CLASSIFIER}.csv"  \
    --locations_config $LOCATIONS_CONFIG \
    --files_format_config $FILES_FORMAT_CONFIG \
    --classes_config $CLASSES_CONFIG
done



