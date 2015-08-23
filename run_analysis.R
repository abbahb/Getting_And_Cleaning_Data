library(plyr)
library(dplyr)
library(reshape2)
library(stringr)
setwd("C:/ARCHIVE/DATA_SCIENTIST/WEEK3_MODULE3/ASSIGNMENT1/UCI HAR Dataset")
list.dirs()
list.files()
## read features file and assigned to features
features <- read.table("./features.txt")
## display internal structure of Features 
str(features)
## read test data
test_X <- read.table("./test/X_test.txt")
test_Y <- read.table("./test/Y_test.txt")
test_subject <- read.table("./test/subject_test.txt")
## read train data
train_X <- read.table("./train/X_train.txt")
train_Y <- read.table("./train/Y_train.txt")
train_subject <- read.table("./train/subject_train.txt")
## (1) Combine Test and Training data to Create one data set.
combine_data_X <- rbind(test_X,train_X)
combine_data_Y <- rbind(test_Y,train_Y)
combine_subject <- rbind(test_subject,train_subject)
## display internal structure of combine_subject
str(combine_subject)
## user features dataframe , V2 variable as a Column header for Combine data set(train&test)
list_of_header <- as.character(features$V2)
## display internal structure of list_of_header
str(list_of_header)
## use function make.name i.e character vector to be coerced to syntactically valid names
list_of_header <- make.names(list_of_header, unique = TRUE)
## set names to object combine_data_X & Y
names(combine_data_X) <- list_of_header
## add combine_Y data frame to combine_data i.e column merge 
combine_data_X <- cbind(combine_data_Y,combine_data_X)
## assign name of variable in combine_subject data frame to "subject"
names(combine_subject) <- c("subject")
## display internal structure of combine_subject
str(combine_subject)
## combine both data frame "combine subject" and "combine_data_X" By column
combine_data <- cbind(combine_subject,combine_data_X)
##(2) Extracts only the measurements on the mean and standard deviation for each measurement and assign to 
## data_std_mean data frame
data_std_mean <- select(combine_data,subject,V1,contains(".mean."), contains(".std."))
str(data_std_mean)
## convert the subject columns to factors
data_std_mean$subject <- as.factor(data_std_mean$subject)
## (3) Uses descriptive activity names to name the activities in the data set , replace specified value in Factor 
## V1 to new value i.e , function use mapvalues in package 'plyr'
data_std_mean$V1 <- mapvalues(data_std_mean$V1, from=c(1, 2, 3, 4, 5, 6), to=c("Walking", "WalkingUpStairs", "WalkingDownStairs", "Sitting", "Standing", "Lying"))
# 4) appropriately label the data set with descriptive variable names
names(data_std_mean) <- str_replace_all(names(data_std_mean), "[.][.]", "")
names(data_std_mean) <- str_replace_all(names(data_std_mean), "BodyBody", "Body")
names(data_std_mean) <- str_replace_all(names(data_std_mean), "tBody", "Body")
names(data_std_mean) <- str_replace_all(names(data_std_mean), "fBody", "FFTBody")
names(data_std_mean) <- str_replace_all(names(data_std_mean), "tGravity", "Gravity")
names(data_std_mean) <- str_replace_all(names(data_std_mean), "fGravity", "FFTGravity")
names(data_std_mean) <- str_replace_all(names(data_std_mean), "Acc", "Acceleration")
names(data_std_mean) <- str_replace_all(names(data_std_mean), "Gyro", "AngularVelocity")
names(data_std_mean) <- str_replace_all(names(data_std_mean), "Mag", "Magnitude")
for(i in 3:68) {if (str_detect(names(data_std_mean)[i], "[.]std")) 
{names(data_std_mean)[i] <- paste0("StandardDeviation", str_replace(names(data_std_mean)[i], "[.]std", ""))}}
for(i in 3:68) {if (str_detect(names(data_std_mean)[i], "[.]mean")) 
{names(data_std_mean)[i] <- paste0("Mean", str_replace(names(data_std_mean)[i], "[.]mean", ""))}}
names(data_std_mean) <- str_replace_all(names(data_std_mean), "[.]X", "XAxis")
names(data_std_mean) <- str_replace_all(names(data_std_mean), "[.]Y", "YAxis")
names(data_std_mean) <- str_replace_all(names(data_std_mean), "[.]Z", "ZAxis")
# 5) from the data set in step 4, create a second, independent tidy data set 
#    with the average of each variable for each activity and each subject.
# Use a split/apply/combine method. First, split the data by the subject and activity factors.
split_set <- split(select(data_std_mean, 3:67), list(data_std_mean$subject, data_std_mean$V1))
# Next, use lapply to iterate over each item in the resulting list, and use apply to calculate the mean of each column.
mean_set <- lapply(split_set, function(x) apply(x, 2, mean, na.rm=TRUE))
# The output from lapply is a list. Convert this back to a data frame.
tidy_set <- data.frame(t(sapply(mean_set,c)))
# The subject and activity factors are still combined, and are now row names instead of columns. Split them 
# using strsplit, then add them to a separate data frame that can be combined with the tidy data set using cbind.
factors <- data.frame(t(sapply(strsplit(rownames(tidy_set), "[.]"),c)))
tidy_set <- cbind(factors, tidy_set)
# Give the subject and activity columns friendly names, and convert them to factors.
tidy_set <- dplyr::rename(tidy_set,TestSubject = X1, Activity = X2)
tidy_set$TestSubject <- as.factor(tidy_set$TestSubject)
tidy_set$Activity <- as.factor(tidy_set$Activity)
rownames(tidy_set) <- NULL
# DATA VERIFICATION - "manually" generate a couple test variables to verify that the calculated average values are correct.
# pull all of the data for subject = 1, activity = walking, variable = tBodyAcc.mean...X
test_set <- select(filter(data_std_mean, V1=="Walking" & subject==1), MeanBodyAccelerationXAxis)
# calculate the mean, and compare it to the same calculation from the result set.
tidy_set_val <- select(filter(tidy_set, TestSubject==1 & Activity=="Walking"), MeanBodyAccelerationXAxis)$MeanBodyAccelerationXAxis
result <- all.equal(mean(test_set$MeanBodyAccelerationXAxis), tidy_set_val)
print("Data calculation verification--TRUE indicates the verification passed:")
print(result)
# second verification, with data from the middle of the matrix
test_set <- select(filter(data_std_mean, V1=="Sitting" & subject==5), StandardDeviationFFTBodyAccelerationXAxis)
tidy_set_val <- select(filter(tidy_set, TestSubject==5 & Activity=="Sitting"), StandardDeviationFFTBodyAccelerationXAxis)$StandardDeviationFFTBodyAccelerationXAxis
result <- all.equal(mean(test_set$StandardDeviationFFTBodyAccelerationXAxis), tidy_set_val)
print(result)
# write the tidy data set to a file for project submission
write.table(tidy_set, "tidy_data_set.txt", row.names=FALSE)
# check if the 2nd tidy data - file name "tidy_data_set.txt" exists
list.files()
