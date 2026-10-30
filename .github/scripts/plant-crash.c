/* The plant_crash input of R-CMD-check.yaml builds this file, and
   tests/testthat/test-plant-crash.R calls the function. The write through
   a null pointer stops the test process with an access violation. */
void plant_crash(void)
{
    volatile int *p = 0;
    *p = 1;
}
