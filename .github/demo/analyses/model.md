This report fits the main models of the paper, which ask two questions.
The within-person effect is the change in a person's mood on days after
they sleep more than usual. The between-person effect is the difference in
mood between people who sleep more overall and people who sleep less.

<!-- analysis -->

## Person-Mean Centering

Each night's sleep is split into the person's own average and the night's
difference from it.

```{r}
#| label: centering
diary <- read.csv(file.path(site, "data", "diary.csv"))
diary$sleep_mean <- ave(diary$sleep_hours, diary$id)
diary$sleep_within <- diary$sleep_hours - diary$sleep_mean
diary$mood_within <- diary$mood - ave(diary$mood, diary$id)
```

## Within-Person Effect

A model with one intercept for each participant estimates the change in
mood for each hour of sleep above the person's own average.

```{r}
#| label: within
fit_within <- lm(mood ~ sleep_within + factor(id), data = diary)
round(summary(fit_within)$coefficients["sleep_within", ], 3)
round(confint(fit_within)["sleep_within", ], 3)
```

## Between-Person Effect

A model of each person's average mood on their average sleep estimates the
difference between people.

```{r}
#| label: between
person <- aggregate(cbind(sleep_hours, mood) ~ id, data = diary, FUN = mean)
fit_between <- lm(mood ~ sleep_hours, data = person)
round(summary(fit_between)$coefficients, 3)
```

## Figure 1

Figure 1 of the paper shows the within-person link. The code saves it in
`figures/` for the paper and the page shows the saved file.

```{r}
#| label: figure-1
save_png("figure-1.png", function() {
  plot(diary$sleep_within, diary$mood_within, pch = 16,
       col = adjustcolor("steelblue", 0.4),
       xlab = "Sleep (hours from own average)",
       ylab = "Mood (points from own average)")
  abline(lm(mood_within ~ sleep_within, data = diary), lwd = 2)
})
```

![Figure 1. Daily mood against the night's sleep, each centered on the
person's own average.](../figures/figure-1.png)
