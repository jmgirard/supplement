# Simulates the data of the demo's made-up study: 60 people who kept a
# sleep and mood diary for 14 days. build-demo.R sources this file and calls
# simulate_demo_data() with a folder outside the demo site, then adds the
# two files to the site with add_data().

simulate_demo_data <- function(dir) {
  set.seed(2026)
  n <- 60
  days <- 14
  people <- data.frame(
    id = seq_len(n),
    age = sample(18:64, n, replace = TRUE),
    chronotype = sample(c("morning", "intermediate", "evening"), n, replace = TRUE,
                        prob = c(0.3, 0.45, 0.25))
  )

  # Each person has their own usual sleep and mood. Mood rises on days after
  # a person sleeps more than usual (0.3 points per hour) and is a little
  # higher in people who sleep more overall (0.15 points per hour).
  usual_sleep <- rnorm(n, 7, 0.6)
  usual_mood <- rnorm(n, 0, 0.6)
  diary <- expand.grid(day = seq_len(days), id = seq_len(n))[c("id", "day")]
  diary$sleep_hours <- round(usual_sleep[diary$id] + rnorm(nrow(diary), 0, 0.9), 1)
  mood <- 4 + 0.3 * (diary$sleep_hours - usual_sleep[diary$id]) +
    0.15 * (usual_sleep[diary$id] - 7) + usual_mood[diary$id] + rnorm(nrow(diary), 0, 0.8)
  diary$mood <- round(pmin(pmax(mood, 1), 7), 1)
  # About 1 in 12 diary days are missed.
  diary <- diary[runif(nrow(diary)) > 1 / 12, ]

  files <- file.path(dir, c("participants.csv", "diary.csv"))
  write.csv(people, files[[1]], row.names = FALSE)
  write.csv(diary, files[[2]], row.names = FALSE)
  files
}
