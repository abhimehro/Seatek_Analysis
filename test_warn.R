year_tag <- sub("^SS_Y([0-9]{2})\\.txt$", "\\1", basename("random.txt"))
suppressWarnings(year_num <- as.integer(year_tag))
