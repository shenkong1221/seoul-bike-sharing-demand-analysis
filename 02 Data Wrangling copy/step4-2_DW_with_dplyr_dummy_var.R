sapply(seoul_bikesharing_df, class)

# Convert HOUR column into characters
seoul_bikesharing_df <- seoul_bikesharing_df %>%
                        mutate(HOUR=as.character(HOUR))
class(seoul_bikesharing_df$HOUR)

# Convert categorical variables (HOUR/SEASONS/HOLIDAY/FUNCTIONAL_DAY) 
# into indicator variables
unique(seoul_bikesharing_df$FUNCTIONING_DAY)   
# FUNCTIONING_DAY only has one value
seoul_bikesharing_df <- cbind(seoul_bikesharing_df,
                              model.matrix(
                                ~ HOUR + SEASONS + HOLIDAY - 1,
                                data=seoul_bikesharing_df
                              )
  )

summary(seoul_bikesharing_df)
write_csv(seoul_bikesharing_df,
          "/Users/***/Cleaned2_seoul_bike_sharing.csv")




