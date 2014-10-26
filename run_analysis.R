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
meanandsd<-data[,c(key(dt), requiredFeatures$code),with=FALSE]

#Uses descriptive activity names to name the activities in the data set
Names <- fread(file.path(pathIn, "activity_labels.txt"))
setnames(Names, names(Names), c("num", "name"))
data <- merge(data, Names, by = "num", all.x = TRUE)
setkey(data, subject, num, name)
data <- data.table(melt(data, key(data), variable.name = "code"))
data <- merge(data, requiredFeatures[, list(featnum, code, featname)], by = "code", all.x = TRUE)
data$activity <- factor(data$name)
data$feature <- factor(data$featname)

grepthis <- function(regex) {
    grepl(regex, data$feature)
	}
	## Features with 2 categories
	n <- 2
	y <- matrix(seq(1, n), nrow = n)
	x <- matrix(c(grepthis("^t"), grepthis("^f")), ncol = nrow(y))
	data$featDomain <- factor(x %*% y, labels = c("Time", "Freq"))
	x <- matrix(c(grepthis("Acc"), grepthis("Gyro")), ncol = nrow(y))
	data$featInstrument <- factor(x %*% y, labels = c("Accelerometer", "Gyroscope"))
	x <- matrix(c(grepthis("BodyAcc"), grepthis("GravityAcc")), ncol = nrow(y))
	data$featAcceleration <- factor(x %*% y, labels = c(NA, "Body", "Gravity"))
	x <- matrix(c(grepthis("mean()"), grepthis("std()")), ncol = nrow(y))
	data$featVariable <- factor(x %*% y, labels = c("Mean", "SD"))
	## Features with 1 category
	data$featJerk <- factor(grepthis("Jerk"), labels = c(NA, "Jerk"))
	data$featMagnitude <- factor(grepthis("Mag"), labels = c(NA, "Magnitude"))
	## Features with 3 categories
	n <- 3
	y <- matrix(seq(1, n), nrow = n)
	x <- matrix(c(grepthis("-X"), grepthis("-Y"), grepthis("-Z")), ncol = nrow(y))
	data$featAxis <- factor(x %*% y, labels = c(NA, "X", "Y", "Z"))

