# Minimal supporting utilities: VCF import, marker harmonisation and coordinate plotting.
# Core population-genetic calculations are taught directly in the RMarkdown.
# Teaching utilities: biallelic, haploid or homozygous diploid-coded genotypes.
read_barcode_vcf <- function(path) {
  lines <- readLines(path, warn = FALSE)
  lines <- lines[!grepl('^##', lines)]
  d <- read.delim(text = paste(lines, collapse = '\n'), check.names = FALSE,
                  stringsAsFactors = FALSE)
  stopifnot(all(c('#CHROM','POS','ID','REF','ALT','FORMAT') %in% names(d)))
  samples <- names(d)[-(1:9)]
  gt <- as.matrix(d[, samples, drop = FALSE]); gt <- sub(':.*$', '', gt)
  parse_gt <- function(z) {
    z <- gsub('\\|', '/', z)
    out <- rep(NA_real_, length(z))
    out[z %in% c('0', '0/0')] <- 0
    out[z %in% c('1', '1/1')] <- 1
    out
  }
  x <- matrix(parse_gt(as.vector(gt)), nrow = nrow(gt), dimnames = list(d$ID, samples))
  mixed <- sum(!is.na(gt) & !(gt %in% c('0','1','0/0','1/1','.','./.','.|.')))
  if (mixed) warning(mixed, ' unsupported/mixed genotype calls treated as missing')
  key <- paste(d[['#CHROM']], d$POS, d$ID, sep = ':')
  if (anyDuplicated(key)) stop('Duplicate marker keys in ', path)
  rownames(x) <- key
  list(x = t(x), variants = data.frame(key = key, chrom = d[['#CHROM']],
       pos = d$POS, id = d$ID, ref = d$REF, alt = d$ALT))
}
# Pairwise mismatch proportion; loci missing in either sample are excluded.
# Restrict to allele-compatible markers, reversing 0/1 if REF and ALT are swapped.
harmonise_vcfs <- function(a, b) {
  common <- intersect(a$variants$key, b$variants$key)
  va <- a$variants[match(common, a$variants$key), ]
  vb <- b$variants[match(common, b$variants$key), ]
  same <- va$ref == vb$ref & va$alt == vb$alt
  flip <- va$ref == vb$alt & va$alt == vb$ref
  keep <- same | flip
  keys <- common[keep]
  xa <- a$x[, keys, drop = FALSE]; xb <- b$x[, keys, drop = FALSE]
  if (any(flip[keep])) xb[, flip[keep]] <- 1 - xb[, flip[keep]]
  if (length(intersect(rownames(xa), rownames(xb)))) stop('Duplicate sample names')
  list(x = rbind(xa, xb), compatible = length(keys), incompatible = sum(!keep),
       swapped = sum(flip[keep]), keys = keys)
}
# Sample-size corrected diversity at each typed biallelic SNP.
# Lightweight schematic geography: coordinate grid + supplied sampling points.
# No external boundary files, geospatial libraries or online requests required.
plot_locations <- function(meta, title, colour_var = 'country') {
  ggplot2::ggplot(meta, ggplot2::aes(x = longitude, y = latitude,
                  colour = .data[[colour_var]])) +
    ggplot2::geom_point(size = 1.8, alpha = .75, position = ggplot2::position_jitter(width = .3, height = .3)) +
    ggplot2::coord_quickmap(xlim = c(-25,115), ylim = c(-30,30), expand = FALSE) +
    ggplot2::theme_minimal() + ggplot2::labs(title = title, x = 'Longitude', y = 'Latitude', colour = colour_var)
}
