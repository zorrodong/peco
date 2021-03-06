#' @title Compute proportation of variance explained by cyclic trends
#' in the gene expression levels for each gene.
#'
#' @description We applied quadratic (second order) trend filtering
#' using the trendfilter function in the genlasso package (Tibshirani,
#' 2014). The trendfilter function implements a nonparametric
#' smoothing method which chooses the smoothing parameter by
#' cross-validation and fits a piecewise polynomial regression. In
#' more specifics: The trendfilter method determines the folds in
#' cross-validation in a nonrandom manner. Every k-th data point in
#' the ordered sample is placed in the k-th fold, so the folds contain
#' ordered subsamples. We applied five-fold cross-validation and chose
#' the smoothing penalty using the option lambda.1se: among all
#' possible values of the penalty term, the largest value such that
#' the cross-validation standard error is within one standard error of
#' the minimum. Furthermore, we desired that the estimated expression
#' trend be cyclical. To encourage this, we concatenated the ordered
#' gene expression data three times, with one added after another. The
#' quadratic trend filtering was applied to the concatenated data
#' series of each gene.
#'
#' @param Y A matrix (gene by sample) of gene expression values.  The
#' expression values are assumed to have been normalized and
#' transformed to standard normal distribution.
#' 
#' @param theta A vector of cell cycle phase (angles) for single-cell
#' samples.
#' 
#' @param polyorder We estimate cyclic trends of gene expression
#' levels using nonparamtric trend filtering. The default fits second
#' degree polynomials.
#' 
#' @param ncores mclapply from the parallel package is used to perform
#' parallel computing to reduce computational time.
#'
#' @return A vector of proportion of variance explained for each gene.
#'
#' @author Joyce Hsiao
#'
#' @importFrom assertthat assert_that
#' @importFrom parallel mclapply
#' 
#' @export
#' 
fit_cyclical_many <- function(Y, theta, polyorder=2, ncores=4) {
  G <- nrow(Y)
  N <- ncol(Y)

  if (!assert_that(all.equal(names(theta), colnames(Y)))) {
    Y_ordered <- Y[,match(names(theta), colnames(Y))]
    ord <- order(theta)
    theta_ordered <- theta[ord]
    Y_ordered <- Y_ordered[,ord]
  } else {
    ord <- order(theta)
    theta_ordered <- theta[ord]
    Y_ordered <- Y[,ord]
  }

  # For each gene, estimate the cyclical pattern of gene expression
  # conditioned on the given cell times.
  fit <- mclapply(1:G, function(g) {
    y_g <- Y_ordered[g,]
    fit_g <- fit_trendfilter_generic(yy=y_g, polyorder = polyorder)
    return(fit_g$pve)
  }, mc.cores = ncores)

  out <- do.call(rbind, fit)
  out <- as.data.frame(out)
  colnames(out) <- "pve"
  rownames(out) <- rownames(Y_ordered)

  return(out)
}
