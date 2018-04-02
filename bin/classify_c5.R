#!/usr/bin/env Rscript
# script for decision trees for the new CCFlex

rm(list = setdiff(ls(), lsf.str()))

oldw <- getOption("warn")
options(warn = -1)

CLASSIFIER_NAME <- "C50"

# Handle input parameters
args = commandArgs(trailingOnly=TRUE)
if (length(args)==0) {
  stop("Provide at least paths to the: train file, classify file, output file", call.=FALSE)
}
train_file <- args[1]
classify_file <- args[2]
output_file_prefix <- args[3]
classifiers_options_file_path <- ifelse(length(args)>3, args[4], "./classifiers_options.json")
classes_file_path <- ifelse(length(args)>4, args[5], "./classes.json")
separator <- ifelse(length(args)>5, args[6], "$")


print(">>> C50: running for parameters:")
print(paste("train file: ", train_file))
print(paste("classify file: ", classify_file))
print(paste("output file prefix: ", output_file_prefix))
print(paste("classifiers options: ", classifiers_options_file_path))
print(paste("classes info: ", classes_file_path))
print(paste("separator: ", separator))


# Load / install packages
print(">>>> Loading and installing packages")
if (require(readr) == F){
  install.packages("readr", repos='http://cran.us.r-project.org')
  library(readr)
}
if (require(dplyr) == F){
  install.packages("dplyr", repos='http://cran.us.r-project.org')
  library(dplyr)
}
if (require(C50) == F){
  install.packages("C50", repos='http://cran.us.r-project.org')
  library(C50)
}
if (require(jsonlite) == F){
  install.packages("jsonlite", repos='http://cran.us.r-project.org')
  library(jsonlite)
}

# load classifier options
classifiers_options <- fromJSON(classifiers_options_file_path)
classifier_options <- classifiers_options[[CLASSIFIER_NAME]]

# load definition of classes
classes_config =  fromJSON(classes_file_path)

print(">>> C50: preparing training data")
suppressMessages(trainingData <- read_delim(train_file, separator, escape_double = FALSE, trim_ws = TRUE))
trainDataSmall <- trainingData %>% select(-contents, -id, -class_name)

print(paste(">>> C50: train data set size: ", nrow(trainDataSmall)))



# C5.0 Decision Tree
print(">>> C50: training classifier")

# TODO: procedure of weigthing cases should be improved to support multiclass problem and not to rely on order of
# what table() returns
if (classifier_options$weights == T){
  model_weights <- ifelse(trainDataSmall$class_value == 1,
                          (1/table(trainDataSmall$class_value)[0]) * 0.5,
                          (1/table(trainDataSmall$class_value)[1]) * 0.5)
}else{
  model_weights <- NULL
}

X <- trainDataSmall %>% select(-class_value)
feature_names <- colnames(X)
colnames(X)  <- paste(rep("f",length(colnames(X))), seq(length(colnames(X))), sep="_")

print(paste(">>> C50: rules = ", classifier_options$rules, sep=""))
print(paste(">>> C50: trials = ", classifier_options$trials, sep=""))
Y <- factor((trainDataSmall %>% select(class_value))$class_value)

control <- C50::C5.0Control(label="class_value", earlyStopping=T)
fit_tree <- C50::C5.0(X, Y, data=trainDataSmall, rules = classifier_options$rules,
                      trials = classifier_options$trials,
                      weights = model_weights, control=control)

print(">>> C50: trained the following model:")
summary_fit_tree <- summary(fit_tree)
print(summary_fit_tree)
print(data.frame(f=colnames(X), feature=feature_names))

print(">>> C50: preparing classify data")
suppressMessages(testData <- read_delim(classify_file, separator, escape_double = FALSE, trim_ws = TRUE))
testDataSmall <- testData %>% select(-id)

print(">>> C50: classifying instances")
X_pred <- testDataSmall
colnames(X_pred)  <- paste(rep("f",length(colnames(X_pred))), seq(length(colnames(X_pred))), sep="_")

result_tree <- cbind(testData, data.frame(pred_class=predict(fit_tree, X_pred, type="class")))
result_tree <- result_tree %>% select(id, contents, pred_class)

print(paste(">>> C50: results saved to ",  paste(output_file_prefix, ".csv", sep=""), sep=""))
write.table(result_tree, file=paste(output_file_prefix, ".csv", sep=""),
            row.names=FALSE, sep=separator)

cat(as.character(summary_fit_tree), file=paste(output_file_prefix, "-model.txt", sep="") ,sep="\n")
a <- data.frame(f=colnames(X), feature=feature_names)
b <- capture.output(a)
c <- paste(b, "\n", sep="")
cat("\n The features mapping is as follows:\n", c, "\n", file=paste(output_file_prefix, "-model.txt", sep=""), append=T)

options(warn = oldw)
