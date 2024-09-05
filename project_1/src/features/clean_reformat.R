library(data.table)

house_dt <- fread("./volume/data/raw/Stat_380_housedata.csv")
qc_data <- fread("./volume/data/raw/Stat_380_QC_table.csv")
ex_sub <- fread("./volume/data/raw/example_sub.csv")

# average of houses that share the same value, local averages
house_dt[, total_bathrooms := HalfBath * 0.5 + FullBath]

train <- house_dt[grep("train_", house_dt$Id)]
  
test <- house_dt[grep("test_", house_dt$Id)]

# g sub function (gsub(find and replace) and grepl)
  #- find "test_" replace with "" put in new col (mutate)
# create new columns that are numeric (test_xxx)
# put rows in order (ascending order on test vals)
# ordered_train <- train[order(Id)]
test$sort_col <- gsub("test_", "", test$Id)
test$sort_col<- as.integer(test$sort_col)
ordered_test <- test[order(sort_col)]
  
# after rows are in order, group the train by something, get average saleprice in group
# Note: train has values. Test does not.
# Create new column, average salesprice column
avg_price_by_group <- train[, .(mean_prices = mean(SalePrice)), by = .(qc_code, total_bathrooms)]

# merge the avg table to the test table, overwrite salesprice house_dt col with prev results.
ordered_test[avg_price_by_group, on = .(qc_code, total_bathrooms), SalePrice := mean_prices]
global_avg <- mean(ordered_test$SalePrice, na.rm = TRUE)

# select columns Id and SalePrice from test
submit <- test[,.(Id, SalePrice)]
# write-out test table to process folder as .csv
fwrite(submit, "./volume/data/processed/submit.csv")  

  