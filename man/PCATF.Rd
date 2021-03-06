% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/PCATF.R
\name{PCATF}
\alias{PCATF}
\title{PCA Trend Filtering (C++ core)}
\usage{
PCATF(
  X,
  X.svd = NULL,
  solve_directions = TRUE,
  K = NULL,
  lambda = 5,
  niter_max = 1000,
  TOL = 1e-08,
  verbose = FALSE
)
}
\arguments{
\item{X}{A numerical data matrix (observations x variables).}

\item{X.svd}{(Optional) The svd decomposition of X. Save time by providing
this argument if the svd has already been computed. Default NULL.}

\item{solve_directions}{Should the principal directions be solved for? These
will be needed to display the leverage images for outlying observations.}

\item{K}{(Optional) The number of trend-filtered PCs to solve for. If not
 provided, it will be set to the number of regular PCs with variance above
the mean, up to 100 PCs.}

\item{lambda}{The trend filtering parameter; roughly, the filtering intensity.
Default is 5.}

\item{niter_max}{The number of iterations to use for approximating the PC.}

\item{TOL}{The maximum 2-norm between iterations to accept as convergence.}

\item{verbose}{Print statements about convergence?}
}
\value{
SVD The trend-filtered SVD decomposition of X (list with u, d, v).
}
\description{
From: https://github.com/Lei-D/PCATF and 
 https://github.com/glmgen/glmgen/blob/master/c_lib/glmgen/src/tf/tf_dp.c .
}
\details{
Inheriting from \code{glmgen}, this code is under the GNU Lesser General 
 Public License: http://www.gnu.org/licenses/ .
}
