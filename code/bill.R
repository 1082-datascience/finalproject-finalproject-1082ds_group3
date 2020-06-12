# 以下為資料前處理的部份，提供一些功能：
# 假設檢定（用在類別變數上與結果(answers)的關係程度）、移除離群值、分成bins 來 label、視覺化各種變數，包括 box, bar, correlation 
# 以下都有對於各部分程式碼的註解及說明，若有需要調整之處或是改善之處，可以發 issues 或是 tag 我們！
# ===============================================================================================================
# should install hash, ggcorrplot
library(hash)
library(tibble)
library(infotheo)
library(stringr)

# define three part columns
index_column <- c("id")
answer_column <- c("heart_disease")
first_part <- c(index_column, "age", "sex", "chest_pain", "resting_bp", "cholestoral")
second_part <- c(index_column, "cholestoral", "high_sugar", "ecg", "max_rate", "exercise_angina", "st_depression")
third_part <- c(index_column, "slope", "vessels", "thalium_scan")

# define new added column, make sure the length can divided by 2 (numeric data)
first_added <- c("age", "resting_bp", "cholestoral")
second_added <- c("cholestoral", "max_rate", "st_depression")
third_added <- c("thalium_scan")

# define hypothesis column (categorical data)
alpha <- 0.05
first_hypothesis <- c()
second_hypothesis <- c("high_sugar", "ecg", "exercise_angina")
third_hypothesis <- c()

# define plot information, make sure the length is as same as part
plot_kind <- list(a=c("Box", "Box Plot", "Range"), b=c("Bar", "", "Count"))

# define new csv file name
first_csv <- "/../data/first_part/first_part_processed_data_"
second_csv <- "/../data/second_part/second_part_processed_data_"
third_csv <- "/../data/third_part/third_part_processed_data_"

# hash dictionary, define some parameters that we'll actually use
params <- hash()
params[["1"]] <- list(id="first", csv=first_csv, part=first_part, added=first_added, answer=answer_column, ranger=list(a=c(17, 40, 65), b=c(120, 139), c=c(129, 200, 239)))
params[["2"]] <- list(id="second", hypothesis=second_hypothesis, csv=second_csv, part=second_part, added=second_added, answer=answer_column, ranger=list())
params[["3"]] <- list(id="third",  csv=third_csv, part=third_part, added=third_added, answer=answer_column, ranger=list())

# define some function

# make the first word of labels to capital
# use this fcn to create main title name for plotting
CapStr <- function(y) {
    c <- strsplit(y, " ")[[1]]
    string <- paste(toupper(substring(c, 1,1)), substring(c, 2), sep="", collapse=" ")
    return(string)
}

# depend on different situation, plot the data for correlation, bar, box plots
save2img <- function(target, file_name, plot_type, main_title, x_title, y_title) {
    png(filename = paste0(getwd(), file_name))
    
    if (plot_type == "Bar") {
        data_table <- table(target)
        barplot(data_table, main = main_title, xlab = x_title, ylab = y_title) 
    } else if (plot_type == "Box") {
        boxplot(target, main = main_title, xlab = x_title, ylab = y_title)
    } else if (plot_type == "corr") {
        if (!require(ggcorrplot)) {
            install.packages(ggcorrplot)
        }
        library(ggcorrplot)
        corrplot <- ggcorrplot(target, hc.order = TRUE, type = "lower", lab = TRUE)
        print(corrplot)
    }
    
    dev.off()
}

# calculate correlation
do_corr_process <- function(data, headers, id) {
    corr_processed_data <- data
    names(corr_processed_data) <- headers
    corr_matrix <- cor(corr_processed_data)
    save2img(corr_matrix, paste(plot_dir, "/", id, "_part_corr_plot.png", sep=""), "corr", "", "", "")
}

# get headers for correlation and for saving result
get_headers <- function(data, params, mode, headers){
    total_col <- names(data)
    save_header <- c()
    for (i in seq(1, length(total_col), by=1)) {
        ori_colname <- total_col[[i]]
        save_header <- c(save_header, ori_colname)
        current_data <- data[[ori_colname]]
        if (!str_detect(ori_colname, "without_label")){
            headers <- c(headers, ori_colname)
        }
        for (j in seq(1, length(plot_kind), by=1)){
            colname <- str_replace_all(ori_colname, "_", " ")
            Cap_colname <- CapStr(colname)
            if (mode == "train") {
              
                # define others
                type <- plot_kind[[j]][[1]]
                y_title <- plot_kind[[j]][[3]]
                file_name = paste(plot_dir, "/", ori_colname, "_", type, "plot.png", sep="")
                
                # define x title
                x_title <- ""
                
                # not box plot
                if (str_detect(Cap_colname, "With Label") && j == 2){
                    main_title_infix <- str_replace_all(Cap_colname, " With Label", "")
                    main_title <- paste(main_title_infix, type, "Plot With Label", sep=" ")
                    x_title <- str_replace_all(Cap_colname, "With Label", "Label")
                    save2img(current_data, file_name, type, main_title, x_title, y_title)
                
                # interval, bar plot
                }else if (str_detect(Cap_colname, "Without Label") && j == 2){
                    main_title_infix <- str_replace_all(Cap_colname, " Without Label", "")
                    main_title <- paste(main_title_infix, type, "Plot With Interval", sep=" ")
                    x_title <- str_replace_all(Cap_colname, "Without Label", "Range Interval")
                    save2img(current_data, file_name, type, main_title, x_title, y_title)
                    
                # each unit, bar plot
                }else if (!(str_detect(Cap_colname, "Without Label") || str_detect(Cap_colname, "With Label"))){
                    main_title <- paste(Cap_colname, type, "Plot", sep=" ")
                    x_title <- paste(Cap_colname, plot_kind[[j]][[2]], sep=" ")
                    save2img(current_data, file_name, type, main_title, x_title, y_title)
                }
            
            }
        }
    }
    headers <- unique(headers)
    return(list(headers=headers, save_header=save_header))
}

# remove outliers if we don't specify the ranger for bins
# we assume that the ranger is pre-defined because there are not any outliers
# Note-1: Each three part may have different index result, because this function is processed depends on the variables of each part
# Note-2: We just provide some aspects and data insight for our team members to build model
# Note-3: So they can merge all three processed data by common index they have.
remove_outliers <- function(col_data){
    rge <- 0.5
    Q <- quantile(col_data, probs=c(.25, .75), na.rm = FALSE)
    iqr <- IQR(col_data)
    up <-  Q[2] + rge*iqr # Upper Range  
    low <- Q[1] - rge*iqr # Lower Range
    
    # get index
    lower_idx <- col_data < low
    upper_idx <- col_data > up
    inlier_idx <- !(lower_idx & col_data > upper_idx)
    
    # get inliers
    min_inlier <- min(col_data[inlier_idx])
    max_inlier <- max(col_data[inlier_idx])
    
    # reassign to min and max value
    col_data[lower_idx] <- min_inlier
    col_data[upper_idx] <- max_inlier
    
    # all_outlier idx
    lower_idx <- which(lower_idx)
    upper_idx <- which(upper_idx)
    all_outlier <- c(lower_idx, upper_idx)

    return(list(data=col_data, outliers=all_outlier))
}

# check hypothesis if we specify variables for hypothesis
print_hypothesis <- function(hypothesis_data, colname){
    hypothesis_result <- chisq.test(hypothesis_data) 
    
    if (hypothesis_result$p.value <= alpha){
        cat('Variables', colname, ': are associated (reject H0)\n')
    }else {
        cat('Variables', colname, ': are not associated(fail to reject H0)\n')
    }
}

# if we don't specify ranger, we use kmeans to define
kmeans_ranger <- function(data, kmeans_ranger){
    ranger <- list()
    Sum_of_squared_thre = 0.5
    for (i in kmeans_ranger){
        current_data <- data[i]
        best_k <- 0
        last_dst <- 0
        center <- c()
        for (j in 1:10){
            kmeans.cluster <- kmeans(current_data, centers=j) 
            
            # 用組內平方和去看距離
            distance <- kmeans.cluster$tot.withinss
            if (j == 1){
                last_dst <- distance
                best_k <- j
                center <- kmeans.cluster$centers
            }else {
                if(abs(last_dst - distance)/last_dst >= Sum_of_squared_thre && last_dst - distance > 0) {
                    best_k <- j
                    center <- kmeans.cluster$centers
                }
                last_dst <- distance
            }
        }
        center <- sort(center)
        ranger[[i]] <- round(center, digits = 2)
    }
    return(ranger)
}

# main fcn to processing each part of data
doProcessing <- function(data, mode, params, part) {
    
    # define some variables
    add_postfix <- c("_with_label", "_without_label")
    headers <- c()
    current_header <- c()
    ranger_status <- 0
    
    # define current header
    for (i in params$part) {
        if (i != "id") {
            if (i %in% params$added){
                current_header <- c(current_header, i)
                current_header <- c(current_header, paste(i, add_postfix[[1]], sep=""))
                current_header <- c(current_header, paste(i, add_postfix[[2]], sep=""))
            }else {
                current_header <- c(current_header, i)
            }
        }
    }
    
    # missing value
    for (i in params$part){
        current_data <- data[,i]
        na_index <- which(is.na(current_data))
        data[na_index, i] <- median(current_data[which(!is.na(current_data))])
    }
    
    # if not set ranger, set bins before remove outliers, because it's pre-defined
    # and not remove outliers
    if(length(params$ranger) != 0){
        for (i in seq(1, length(params$added), by=1)){
            name = params$added[[i]]
            current_data <- data[[name]]
            params$ranger[[i]] <- c(min(current_data), params$ranger[[i]])
            params$ranger[[i]] <- c(params$ranger[[i]], max(current_data))
        }
    # because we don't define any bins to cut, so remove outliers then
    }else {
        outliers <- c()
        # detect and remove outlier
        for (i in params$added){
            current_data <- data[[i]]
            result <- remove_outliers(current_data)
            data[[i]] <- result$data
            outliers <- c(outliers, result$outliers)
        }
        
        # remove common outliers' row
        n_occur <- data.frame(table(outliers))
        outliers_common_idx <- n_occur$Freq > 1
        if (length(n_occur[outliers_common_idx,])!=0){
            outliers_common <- n_occur[outliers_common_idx,]$outliers
            outliers_common <- as.numeric(as.character(outliers_common))
            data<- data[-outliers_common, ]
        }
    }
    
    # use kmeans to cut bins
    if(length(params$ranger) == 0){
        if (part==2){
            cat("ranger not implemented, use Kmeans to define bins !\n")
            params$ranger <- kmeans_ranger(data, params$added)
            cat("Bins are defined as \n")
            print(params$ranger)
            ranger_status <- 1
        }else {
            cat("ranger do not need to be defined !\n\n")
        }
        # use self defined bins to cut bins
    }else{
        cat("ranger has been defined !\n\n")
    }
    
    # hypothesis
    if (length(params$hypothesis > 0) && mode == "train"){
        
        cat("Check relationship between each categorical data and answer... \n\n")
        for (i in params$hypothesis){
            params$hypothesis <- c(i, answer_column)
            hypothesis_data <- data[params$hypothesis]
            hypothesis_table <- data.frame(table(hypothesis_data))
            hypothesis_freq <- as.numeric(as.character((hypothesis_table$Freq)))
            hypothesis_matrix <- matrix(hypothesis_freq, nrow=2)
            
            # chi square
            print_hypothesis(hypothesis_matrix, i)
            
            # mutual information
            MI <- mutinformation(hypothesis_data[1], hypothesis_data[2])
            cat("Variable", i, ": Mutual Information Value is ", MI, "\n\n")
            
        }
        cat("Finish checking !\n\n")
    }
        
    # go through each numeric data by defined
    for (i in seq(1, length(params$added), by=1)) {
                
        # append min and max to each ranger
        # define rearrange data
        name = params$added[[i]]
        current_data <- data[[name]]
        
        # part three data are not using cut bins
        if (part != 3) {
            ranger <- params$ranger[[i]]
            rearrange_ranger <- c()
            
            if (ranger_status == 1){
                rearrange_ranger <- c(rearrange_ranger, ranger)
                if (!(min(current_data) %in% rearrange_ranger)){
                    rearrange_ranger <- c(min(current_data), rearrange_ranger)
                }
                if (!(max(current_data) %in% rearrange_ranger)){
                    rearrange_ranger <- c(rearrange_ranger, max(current_data))
                }
            }else {
                rearrange_ranger <- ranger
            }
        }

        # rename added columns
        for(j in 1:2) {
            # get new colname
            current_postfix <- add_postfix[[j]]
            add_colname <- paste(name, current_postfix, sep="")

            if (part == 3) {
                
                # revalue
                current_coldata <- sapply(current_data, function(x) {ifelse(x==3, 1,x)})
                current_coldata <- sapply(current_data, function(x) {ifelse(x==6, 2,x)})
                current_coldata <- sapply(current_data, function(x) {ifelse(x==7, 3,x)})

            }else {
                # cut bins
                current_coldata <- cut(current_data, rearrange_ranger, include.lowest=TRUE)
            }
            
            # add new data to specific place
            if (j==1){
                data <- add_column(data, !!(add_colname):=as.numeric(current_coldata), .after = grep(name, colnames(data)))
            }else{
                data <- add_column(data, !!(add_colname):=current_coldata, .after = grep(paste(name, add_postfix[[1]], sep=""), colnames(data)))
            }
        }
    }
    
    # plot 
    if (mode == "train") {
        
        # get headers and plot
        header_result <- get_headers(data[current_header], params, mode, headers)
        headers <- c(header_result$headers, answer_column)
        save_headers <- c(header_result$save_header, answer_column)

        # do correlation
        do_corr_process(data[headers], headers, params$id)
    } else {
        
        # get headers
        header_result <- get_headers(data[current_header], params, mode, headers)
        save_headers <- header_result$save_header
    }
    
    # ready to save new csv
    # add index column
    save_headers <- c(index_column, save_headers)
    first_part_processed_data <- data.frame(data[save_headers])
    names(first_part_processed_data) <- save_headers
    write.table(first_part_processed_data,
                file = paste0(getwd(), params$csv, mode, ".csv"),
                quote = T,
                sep = ",",
                row.names = F)
}

# =====================================================================================
# define which part
part <- 2
plot_dir <- ""

# create dir if  not exists
if (!dir.exists(paste0(getwd(), "/../results/plots_data/"))){
    dir.create(paste0(getwd(),"/../results/plots_data/"))
}
if (part==1){
    plot_dir <- "/../results/plots_data/first_part"
    if (!dir.exists(paste0(getwd(),plot_dir))){
        dir.create(paste0(getwd(),plot_dir))
    }
    if (!dir.exists(paste0(getwd(),"/../data/first_part/"))){
        dir.create(paste0(getwd(), "/../data/first_part/"))
    }
}else if (part==2){
    plot_dir <- "/../results/plots_data/second_part"
    if (!dir.exists(paste0(getwd(),plot_dir))){
        dir.create(paste0(getwd(),plot_dir))
    }
    if (!dir.exists(paste0(getwd(),"/../data/second_part/"))){
        dir.create(paste0(getwd(), "/../data/second_part/"))
    }
}else {
    plot_dir <- "/../results/plots_data/third_part"
    if (!dir.exists(paste0(getwd(),plot_dir))){
        dir.create(paste0(getwd(),plot_dir))
    }
    if (!dir.exists(paste0(getwd(),"/../data/third_part/"))){
        dir.create(paste0(getwd(), "/../data/third_part/"))
    }
}

# log info
cat("Start Processing Training\n\n")

# process training data
data <- read.csv(paste0(getwd(), "/../data/train.csv"))
doProcessing(data, "train", params[[as.character(part)]], part)

cat("Finish Processing Training\n\n")
cat("Start Processing Testing\n\n")

# process testing data
data <- read.csv(paste0(getwd(), "/../data/test.csv"))
doProcessing(data, "test", params[[as.character(part)]], part)

# log info
cat("Finish Processing Testing")