#' Calculate the leverage images
#'
#' @param clev A \code{"clever"} object.
#' @param timepoints The timepoints or columns for which to compute leverage
#'  images. If \code{NULL} (default), use the outlying timepoints. 
#' @param use_dt If detrended components are available (the "U" matrix of PCA 
#'  or "M" matrix of ICA), should they be used to compute the leverage images?
#'  Default: \code{TRUE}.
#'
#' @return A list of three: \code{idx}, the timepoints for which the leverage images
#'  were computed; \code{mean}, the mean leverage images; and \code{top}, the
#'  top leverage images. The row names of the \code{top} leverage images
#'  matrix give the index of the top component ("V" in PCA and "S" in ICA) at
#'  each timepoint.
#'
#' @export
lev_images <- function(clev, timepoints=NULL, use_dt=TRUE){

  # Check timepoints.
  if (is.null(timepoints)) {
    timepoints <- which(clev$outlier_flag)
    if (!(length(timepoints) > 0)) {
      warning(
        "`timepoints=NULL` will get leverage images for outliers, ",
        "but no outliers were detected."
      )
      return(NULL)
    }
  } else {
    stopifnot(length(timepoints) > 0)
  }

  # Get PCA scores and directions (or ICA mixing and source matrices).
  if ("PCA" %in% names(clev)) {
    U <- clev$PCA$U
    if (!("V" %in% names(clev$PCA))) { 
      stop("No directions. Run `clever` again with `get_dirs=TRUE`.") 
    }
    V <- clev$PCA$V
  } else if ("PCATF" %in% names(clev)) {
    U <- clev$PCATF$U
    if (!("V" %in% names(clev$PCA))) { 
      stop("No directions. Run `clever` again with `get_dirs=TRUE`.")
    }
    V <- clev$PCATF$V
  } else if ("ICA" %in% names(clev)) {
    U <- scale_med(clev$ICA$M)$mat
    V <- clev$ICA$S
  }

  stopifnot(all(timepoints %in% seq(nrow(U))))

  if (is.null(clev$mask)) {
    const_mask = rep(TRUE, nrow(V))
  } else {
    const_mask <- clev$mask > 0
  }
  N_ <- length(const_mask)
  n_imgs <- length(timepoints)

  lev_imgs <- list(
    idx = timepoints,
    mean = matrix(NA, n_imgs, N_),
    top = matrix(NA, n_imgs, N_)
  )

  lev_imgs$mean[,const_mask] <- U[timepoints,,drop=FALSE] %*% t(V)
  dimnames(lev_imgs$mean) <- NULL

  for (ii in seq(length(timepoints))) {
    tt <- timepoints[ii]
    tt_top <- which.max(abs(U[tt,]))[1]
    lev_imgs$top[ii, const_mask] <- V[,tt_top]
  }
  rownames(lev_imgs$top) <- paste("t", as.character(timepoints))
  colnames(lev_imgs$top) <- NULL

  lev_imgs
}

#' Undo a volumetric mask
#' 
#' Un-applies a mask to vectorized data to yield its volumetric representation.
#'  The mask and data should have compatible dimensions: the number of rows in
#'  \code{dat} should equal the number of locations within the \code{mask}.
#' 
#' @param dat Data matrix with locations along the rows and measurements along 
#'  the columns. If only one set of measurements were made, this may be a 
#'  vector.
#' @param mask Volumetric binary mask. \code{TRUE} indicates voxels inside the
#'  mask.
#' @param fill The value for locations outside the mask. Default: \code{NA}.
#'
#' @return The 3D or 4D unflattened volume array
#'
#' @export
#' 
unmask_vol <- function(dat, mask, fill=NA) {

  # Check that dat is a vector or matrix.
  if (is.vector(dat) || is.factor(dat)) { dat <- matrix(dat, ncol=1) }
  stopifnot(length(dim(dat)) == 2)

  # Check that mask is numeric {0, 1} or logical, and is 3D.
  if (is.numeric(mask)) {
    mask_vals <- unique(as.vector(mask))
    stopifnot(length(mask_vals) <= 2)
    stopifnot(all(mask_vals %in% c(0,1)))
    mask <- array(as.logical(mask), dim=dim(mask))
  }
  stopifnot(length(dim(mask)) == 3)

  # Other checks.
  stopifnot(is.vector(fill) && length(fill)==1)
  stopifnot(sum(mask) == nrow(dat))

  # Make volume and fill.
  vol <- array(fill, dim=c(dim(mask), ncol(dat)))
  for (ii in seq_len(ncol(dat))) {
    vol[,,,ii][mask] <- dat[,ii]
  }
  if (ncol(dat)==1) { vol <- vol[,,,1] }

  vol
}