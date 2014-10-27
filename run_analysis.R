library(data.table)
library(reshape2)


#READING THE FILES AND PUTTING THEM IN A NICE TABLE
print("Reading the data...")
path<-getwd()
pathIn <- file.path(path, "UCI HAR Dataset")

subjectTrain <- fread(file.path(pathIn, "train", "subject_train.txt"))
subjectTest <- fread(file.path(pathIn, "test", "subject_test.txt"))

yTrain <- fread(file.path(pathIn, "train", "y_train.txt"))
yTest <- fread(file.path(pathIn, "test", "y_test.txt"))

train<-data.table(read.table(file.path(pathIn, "train", "X_train.txt")))
test<-data.table(read.table(file.path(pathIn, "test", "X_test.txt")))

print("Merging the training and test sets...")
#Merges the training and the test sets to create one data set.
tableSubject<-rbind(subjectTrain,subjectTest)
setnames(tableSubject,"V1","subject")
tableActivity<-rbind(yTrain,yTest)
setnames(tableActivity,"V1","num")

data<-rbind(train,test)

tableSubject<-cbind(tableSubject,tableActivity)
data<-cbind(tableSubject,data)
setkey(data,subject,num)

#READING THE FEATURES
tableFeatures<-fread(file.path(pathIn,"features.txt"))
setnames(tableFeatures,names(tableFeatures),c("featnum","featname"))
requiredFeatures<-tableFeatures[grepl("mean\\(\\)|std\\(\\)",featname)]
requiredFeatures$code<-requiredFeatures[,paste0("V",featnum)]

print("Extracting the means and standard deviations")
#Extracts only the measurements on the mean and standard deviation for each measurement.
data<-data[,c(key(data), requiredFeatures$code),with=FALSE]

#Uses descriptive activity names to name the activities in the data set
print("Puting the names of the activities in apretty way")
Names <- fread(file.path(pathIn, "activity_labels.txt"))
setnames(Names, names(Names), c("num", "name"))
data <- merge(data, Names, by = "num", all.x = TRUE)
setkey(data, subject, num, name)
data <- data.table(melt(data, key(data), variable.name = "code"))
data <- merge(data, requiredFeatures[, list(featnum, code, featname)], by = "code", all.x = TRUE)
data$activity <- factor(data$name)
data$feature <- factor(data$featname)

y <- matrix(seq(1, 2), nrow = 2)
x <- matrix(c(grepl("^t",data$feature), grepl("^f",data$feature)), ncol = nrow(y))
data$featDomain <- factor(x %*% y, labels = c("Time", "Freq"))
x <- matrix(c(grepl("Acc",data$feature), grepl("Gyro",data$feature)), ncol = nrow(y))
data$featInst <- factor(x %*% y, labels = c("Accelerometer", "Gyroscope"))
x <- matrix(c(grepl("BodyAcc",data$feature), grepl("GravityAcc",data$feature)), ncol = nrow(y))
data$featAcc <- factor(x %*% y, labels = c(NA, "Body", "Gravity"))
x <- matrix(c(grepl("mean()",data$feature), grepl("std()",data$feature)), ncol = nrow(y))
data$featVar <- factor(x %*% y, labels = c("mean", "std"))
data$featJerk <- factor(grepl("Jerk",data$feature), labels = c(NA, "Jerk"))
data$featMag <- factor(grepl("Mag",data$feature), labels = c(NA, "Magnitude"))
y <- matrix(seq(1, 3), nrow = 3)
x <- matrix(c(grepl("-X",data$feature), grepl("-Y",data$feature), grepl("-Z",data$feature)), ncol = nrow(y))
data$featAxis <- factor(x %*% y, labels = c(NA, "X", "Y", "Z"))
setkey(data, subject, activity, featDomain, featAcc, featInst, featJerk, featMag, featVar, featAxis)

#Exporting the tidy data
print("Exporting the tidy data")
tidyData<-data[, list(count = .N, average = mean(value)), by = key(data)]
write.table(tidyData,file="tidydata.txt",row.name=FALSE)
