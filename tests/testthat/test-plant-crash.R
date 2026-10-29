# The plant_crash input of R-CMD-check.yaml names a DLL in
# SUPPLEMENT_PLANT_CRASH. This test then crashes its test process, so the
# run shows what the Windows crash dump steps print for a crash.
test_that("a planted crash stops the test process", {
  dll <- Sys.getenv("SUPPLEMENT_PLANT_CRASH")
  skip_if(dll == "", "no crash is planted")
  dyn.load(dll)
  .C("plant_crash")
})
