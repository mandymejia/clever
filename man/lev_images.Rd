% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/lev_images.R
\name{lev_images}
\alias{lev_images}
\title{Calculate the leverage images}
\usage{
lev_images(clev, timepoints = NULL, use_dt = TRUE)
}
\arguments{
\item{clev}{A \code{"clever"} object.}

\item{timepoints}{The timepoints or columns for which to compute leverage
images. If \code{NULL} (default), use the outlying timepoints.}

\item{use_dt}{If detrended components are available (the "U" matrix of PCA 
or "M" matrix of ICA), should they be used to compute the leverage images?
Default: \code{TRUE}.}
}
\value{
A list of three: \code{idx}, the timepoints for which the leverage images
 were computed; \code{mean}, the mean leverage images; and \code{top}, the
 top leverage images. The row names of the \code{top} leverage images
 matrix give the index of the top component ("V" in PCA and "S" in ICA) at
 each timepoint.
}
\description{
Calculate the leverage images
}
