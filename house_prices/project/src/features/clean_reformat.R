library(data.table)

house_dt <- fread("./project/volume/data/raw/Stat_380_housedata.csv")
qc_data <- fread("./project/volume/data/raw/Stat_380_QC_table.csv")
ex_sub <- fread("./project/volume/data/raw/example_sub.csv")

# Create new column vector, house_dt, totaling the half and full baths
house_dt[, total_bathrooms := HalfBath * 0.5 + FullBath]

train <- house_dt[grep("train_", house_dt$Id)]
  
test <- house_dt[grep("test_", house_dt$Id)]

test$sort_col <- gsub("test_", "", test$Id)
test$sort_col<- as.integer(test$sort_col)
ordered_test <- test[order(sort_col)]
  
# find average price by qc_code and total_bathrooms
avg_price_by_group <- train[, .(mean_prices = mean(SalePrice)), by = .(qc_code, total_bathrooms)]

# merge the avg table to the test table, overwrite salesprice house_dt col with prev results.
ordered_test[avg_price_by_group, on = .(qc_code, total_bathrooms), SalePrice := mean_prices]

# take NA cases
na_cases <- ordered_test[is.na(SalePrice)]

# retrieve global_avg for any remaining NAs that were not sorted
global_avg <- mean(ordered_test$SalePrice, na.rm = TRUE)

if (nrow(ordered_test[is.na(SalePrice)]) > 0) {
  global_avg <- mean(ordered_test$SalePrice, na.rm = TRUE)
  ordered_test[is.na(SalePrice), SalePrice := global_avg]
}

# select columns Id and SalePrice from test
submit <- ordered_test[,.(Id, SalePrice)]
# write-out test table to process folder as .csv
fwrite(submit, "./project/volume/data/processed/submit.csv")  

  