Getting And Cleaning Data Project
=================================

The code assumes the folder UCI HAR Dataset is in the same folder as the script
and is uncompressed.

you can run it by calling from a R prompt 
source("run_analysis.R")

The files read are:
subject_train.txt
subject_test.txt
y_train.txt
y_test.txt
X_train.txt
X_test.txt
they are all read as a data.table, so to merge everything in a big table I use rbind and cbind fuctions

To extract the mean and sd I read first the features.txt file which tells me the index in which that information is stored,
so that index is extracted using regular expressions and then used to get the mean and sd to form the working table for the rest of the project.

To put the data in a pretty data frame i also use regular expressions to get the name of the feature an put it in a new colum of the main data.table,
there are features of 1, 2 and 3 categories, so they are extracted for each number.

At the end the file tidydata.txt is written to disk using the write.table file as required.
