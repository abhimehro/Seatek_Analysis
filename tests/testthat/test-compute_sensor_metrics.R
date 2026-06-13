test_that("compute_sensor_metrics computes correctly on > 10 rows", {
  library(data.table)
  df <- data.table(
    Time = 1:15,
    Sensor1 = c(rep(10, 10), rep(20, 5)),
    Sensor2 = c(rep(0, 10), rep(5, 5))
  )
  res <- compute_sensor_metrics(df, "SS_Y01.txt")

  expect_equal(res$sheet_name, "1995")
  expect_equal(res$dt$Sensor, c("Sensor1", "Sensor2"))
  expect_equal(res$dt$first10, c(10, NaN))
  expect_equal(res$dt$last5, c(20, 5))
  expect_equal(res$dt$full, c(13.3333333, 5), tolerance = 1e-6)
  expect_equal(res$dt$within_diff, c(3.3333333, NaN), tolerance = 1e-6)
})

test_that("compute_sensor_metrics handles < 10 rows", {
  library(data.table)
  df <- data.table(
    Time = 1:4,
    Sensor1 = c(1, 2, 3, 4)
  )
  res <- compute_sensor_metrics(df, "SS_Y20.txt")

  expect_equal(res$sheet_name, "2014")
  expect_equal(res$dt$first10, 2.5)
  expect_equal(res$dt$last5, 2.5)
})

test_that("compute_sensor_metrics handles invalid year filenames", {
  library(data.table)
  df <- data.table(Time = 1, Sensor1 = 1)

  res1 <- compute_sensor_metrics(df, "SS_Y99.txt")
  expect_equal(res1$sheet_name, "SS_Y99.txt")

  res2 <- suppressWarnings(compute_sensor_metrics(df, "random.txt"))
  expect_equal(res2$sheet_name, "random.txt")
})
