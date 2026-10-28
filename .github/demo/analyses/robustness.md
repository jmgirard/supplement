This report refits the within-person model of the main analysis under two
other choices: keeping only participants with 10 or more diary days, and
adding the study day and a weekend indicator to the model.

<!-- analysis -->

## Models

Day 1 of the study was a Monday, so days 6, 7, 13, and 14 fell on a
weekend.

```{r}
#| label: models
diary <- read.csv(file.path(site, "data", "diary.csv"))
diary$sleep_within <- diary$sleep_hours - ave(diary$sleep_hours, diary$id)
diary$weekend <- diary$day %% 7 %in% c(6, 0)

within_estimate <- function(formula, data) {
  fit <- lm(formula, data = data)
  c(estimate = coef(fit)[["sleep_within"]], confint(fit)["sleep_within", ])
}

completed <- table(diary$id)
kept <- diary[diary$id %in% names(completed)[completed >= 10], ]
```

## Estimates

Each row gives the change in mood for each hour of sleep above the person's
own average, with its 95% confidence interval.

```{r}
#| label: estimates
round(rbind(
  "Main model" = within_estimate(mood ~ sleep_within + factor(id), diary),
  "10 or more diary days" = within_estimate(mood ~ sleep_within + factor(id), kept),
  "Study day and weekend" = within_estimate(mood ~ sleep_within + day + weekend + factor(id), diary)
), 3)
```
