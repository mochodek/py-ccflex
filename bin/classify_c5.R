#!/usr/bin/env Rscript
# script for decision trees for the new CCFlex

rm(list = setdiff(ls(), lsf.str()))


oldw <- getOption("warn")
#options(warn = -1)

# Handle input parameters
args = commandArgs(trailingOnly=TRUE)
if (length(args)==0) {
  stop("Provide at least paths to the: train file, classify file, output file", call.=FALSE)
}
train_file <- args[1]
classify_file <- args[2]
output_file <- args[3]
output_file_count <- args[4]
if (length(args)>4){
  separator <- args[5]
}else{
  separator <- "$"
}

print(">>>> Running for parameters:")
print(paste("train file: ", train_file))
print(paste("classify file: ", classify_file))
print(paste("output file: ", output_file))
print(paste("output count file: ", output_file_count))
print(paste("separator: ", separator))

# Load / install packages
print(">>>> Loading and installing packages")
if (require(readr) == F){
  install.packages("readr", repos='http://cran.us.r-project.org')
  library(readr)
}
#if (require(caret) == F){
#  install.packages("caret", repos='http://cran.us.r-project.org')
#  library(caret)
#}
if (require(dplyr) == F){
  install.packages("dplyr", repos='http://cran.us.r-project.org')
  library(dplyr)
}
if (require(C50) == F){
  install.packages("C50", repos='http://cran.us.r-project.org')
  library(C50)
}

print(">>>> Preparing training data")
trainingData <- read_delim(train_file, separator, escape_double = FALSE, trim_ws = TRUE)
trainDataSmall <- trainingData %>% select(-contents, -id, -class_name)
colnames(trainDataSmall)[colnames(trainDataSmall) == "for"] <- "forloop"
colnames(trainDataSmall)[colnames(trainDataSmall) == "if"] <- "ifcond"
colnames(trainDataSmall)[colnames(trainDataSmall) == "while"] <- "whileloop"
trainDataSmall$class_value <- factor(trainDataSmall$class_value)

print(paste(">>>> Train data set size: ", nrow(trainDataSmall)))

# C5.0 Decision Tree
print(">>>> Building C5.0 classifier model")
model_weights <- ifelse(trainDataSmall$class_value == 1,
                        (1/table(trainDataSmall$class_value)[1]) * 0.5,
                        (1/table(trainDataSmall$class_value)[2]) * 0.5)

# if weigths crashes your computations choose the commented one
fit_tree <- C50::C5.0(class_value ~ ., data=trainDataSmall, rules = TRUE,  weights = model_weights)
#fit_tree <- C50::C5.0(class_value ~ ., data=trainDataSmall, rules = TRUE)
#fit_tree <- C5.0(class_value ~ ., data=trainDataSmall, rules=TRUE)

print(">>>> Trained the followiing model:")
print(summary(fit_tree))

print(">>>> Preparing classify data")
testData <- read_delim(classify_file, separator, escape_double = FALSE, trim_ws = TRUE)
testDataSmall <- testData %>% select(-contents, -id, -class_name, -class_value)
colnames(testDataSmall)[colnames(testDataSmall) == "for"] <- "forloop"
colnames(testDataSmall)[colnames(testDataSmall) == "if"] <- "ifcond"
colnames(testDataSmall)[colnames(testDataSmall) == "while"] <- "whileloop"

print(">>>> Classifying the data")
result_tree <- cbind(testData, data.frame(pred=predict(fit_tree, testDataSmall)))
#result_tree <- result_tree %>% select(-class_value, -class_name)
result_tree <- result_tree %>% select(id, contents, pred)
result_tree_count <- result_tree %>% filter(pred==1)

print(">>>> Saving the results")
write.table(result_tree, file=output_file, row.names=FALSE, sep=separator)
write.table(result_tree_count, file=output_file_count, row.names=FALSE, sep=separator)

options(warn = oldw)
