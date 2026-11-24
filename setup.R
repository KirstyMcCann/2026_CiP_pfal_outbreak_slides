# Population Genomics Workshop - run once before opening the RMarkdown.
# CRAN-only; no Bioconductor, sf, ggtree, dartR.base or SNPRelate.
options(repos = c(CRAN = 'https://cloud.r-project.org'))
packages <- c('rmarkdown', 'knitr', 'ggplot2', 'ape', 'adegenet')
# Use the standard user-writable R library rather than an administrator library.
user_lib <- Sys.getenv('R_LIBS_USER')
if (!nzchar(user_lib)) user_lib <- file.path(path.expand('~'), 'R',
                                            paste0(R.version$platform, '-library'),
                                            paste(R.version$major, strsplit(R.version$minor, '\\.')[[1]][1], sep = '.'))
dir.create(user_lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(user_lib, .libPaths()))
missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  message('Installing missing packages: ', paste(missing, collapse = ', '))
  tryCatch(install.packages(missing, lib = user_lib, dependencies = c('Depends','Imports','LinkingTo')),
           error = function(e) message('Installation issue: ', conditionMessage(e)))
}
status <- vapply(packages, requireNamespace, logical(1), quietly = TRUE)
print(data.frame(package = packages, available = status), row.names = FALSE)
if (all(status)) {
  message("SUCCESS: All workshop packages are available.")
} else {
  message(
    "ACTION REQUIRED: Package(s) unavailable: ",
    paste(packages[!status], collapse = ", ")
  )
}
