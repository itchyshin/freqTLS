# Doc-vs-data tripwire (2026-06-25 audit). The bundled datasets must match the
# contract documented in R/data.R: the @format row/variable counts and the key
# columns the workflow relies on. When a dataset is rebuilt, update R/data.R AND
# the `contract` below together. Motivated by the dsuzukii_lethal -> dsuzukii
# drift (a renamed, reshaped dataset the docs lagged behind).
#
# Broader column-presence and grouping-level checks live in test-data.R; this
# file pins the DOCUMENTED counts and, in a dev checkout, cross-checks them
# against the actual @format text in R/data.R.

# Mirror of the R/data.R @format blocks: `rows`/`vars` must equal the shipped
# data, `cols` are the key columns named in @format.
contract <- list(
  aphid_tdt        = list(rows = 3041L, vars = 7L,
                          cols = c("species", "age", "branch", "temp",
                                   "duration_min", "n_total", "n_surv")),
  dsuzukii         = list(rows = 1407L, vars = 9L,
                          cols = c("temp", "time", "sex", "dead")),
  shrimp_lethal    = list(rows = 148L,  vars = 6L,
                          cols = c("Temperature_assay", "Duration_exposure_hours",
                                   "N_individuals_after_trial",
                                   "Mortality_after_trial")),
  shrimp_sublethal = list(rows = 299L,  vars = 5L,
                          cols = c("assay_temp", "time_to_event")),
  zebrafish_lethal = list(rows = 323L,  vars = 7L,
                          cols = c("assay_temp", "duration_h", "n_total",
                                   "n_surv", "life_stage")),
  zebrafish_o2     = list(rows = 905L,  vars = 10L,
                          cols = c("oxygen", "temp", "duration_min",
                                   "n_total", "n_surv"))
)

test_that("each dataset loads under its exact documented name", {
  ns <- asNamespace("freqTLS")
  for (nm in names(contract)) {
    obj <- tryCatch(get(nm, envir = ns), error = function(e) NULL)
    expect_s3_class(obj, "data.frame")
  }
})

test_that("each dataset matches its documented row/variable counts and key columns", {
  ns <- asNamespace("freqTLS")
  for (nm in names(contract)) {
    obj <- get(nm, envir = ns)
    expect_identical(nrow(obj), contract[[nm]]$rows,
                     info = paste(nm, "row count drifted from R/data.R @format"))
    expect_identical(ncol(obj), contract[[nm]]$vars,
                     info = paste(nm, "variable count drifted from R/data.R @format"))
    expect_true(all(contract[[nm]]$cols %in% names(obj)),
                info = paste(nm, "missing key columns:",
                             paste(setdiff(contract[[nm]]$cols, names(obj)),
                                   collapse = ", ")))
  }
})

test_that("dsuzukii ships a 0/1 mortality indicator", {
  d <- get("dsuzukii", envir = asNamespace("freqTLS"))
  expect_true(all(d$dead %in% c(0L, 1L)))
})

# The genuine doc-vs-data tripwire: read the @format text in R/data.R and check
# the stated counts against the actual data. Skipped when R/data.R is absent
# (e.g. running against an installed package under R CMD check), where the
# hard-coded `contract` above still guards the data shape.
test_that("R/data.R @format counts match the actual data (dev checkout only)", {
  data_r <- test_path("..", "..", "R", "data.R")
  skip_if_not(file.exists(data_r), "R/data.R not available (installed package)")
  src <- readLines(data_r, warn = FALSE)
  ns <- asNamespace("freqTLS")
  for (nm in names(contract)) {
    obj_line <- grep(sprintf('^"%s"[[:space:]]*$', nm), src)
    expect_length(obj_line, 1L)
    if (length(obj_line) != 1L) next
    fmt <- grep("@format A data frame with [0-9]+ rows and [0-9]+ variables",
                src[seq_len(obj_line[1L])], value = TRUE)
    expect_gt(length(fmt), 0L)
    if (!length(fmt)) next
    mm <- regmatches(
      fmt[length(fmt)],
      regexec("with ([0-9]+) rows and ([0-9]+) variables", fmt[length(fmt)])
    )[[1]]
    obj <- get(nm, envir = ns)
    expect_identical(as.integer(mm[2L]), nrow(obj),
                     info = paste(nm, "@format rows vs data"))
    expect_identical(as.integer(mm[3L]), ncol(obj),
                     info = paste(nm, "@format variables vs data"))
  }
})
