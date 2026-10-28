This report describes the sample: the participants' ages and chronotypes,
the number of diary days that each person completed, and the spread of
nightly sleep and daily mood.

<!-- analysis -->

## Participants

```{r}
#| label: participants
people <- read.csv(file.path(site, "data", "participants.csv"))
diary <- read.csv(file.path(site, "data", "diary.csv"))
c(participants = nrow(people), diary_days = nrow(diary))
summary(people$age)
table(people$chronotype)
```

## Completed Diary Days

Each person was asked to complete 14 diary days.

```{r}
#| label: completed-days
completed <- as.vector(table(diary$id))
summary(completed)
sum(completed >= 10)
```

## Sleep and Mood

Sleep is in hours. Mood is a score from 1 (very low) to 7 (very high),
with one decimal place.

```{r}
#| label: sleep-mood
summary(diary[c("sleep_hours", "mood")])
hist(diary$sleep_hours, breaks = 20, main = "Nightly sleep", xlab = "Hours of sleep")
```
