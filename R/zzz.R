.onAttach <- function(libname, pkgname) {
  v <- utils::packageVersion("freqTLS")
  packageStartupMessage(
    "freqTLS ", v, "\n",
    "Please cite: Noble DWA, Arnold PA, Nakagawa S & Pottier P (2026) A flexible\n",
    "  modelling framework for estimating thermal tolerance and sensitivity.\n",
    "  bioRxiv. doi:10.64898/2026.07.16.738378\n",
    "Run  citation(\"freqTLS\")  for all entries.\n\n",
    "Tutorial & online vignette: https://itchyshin.github.io/freqTLS/"
  )
}
