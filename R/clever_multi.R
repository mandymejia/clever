#' Compare multiple scrubbing measures with \code{clever_multi}
#' 
#' Calculates data-driven scrubbing measures and identifies outliers in 
#'  high-dimensional data.
#'
#' \code{clever_multi} will use all combinations of the requested projections and 
#'  outlyingness measures which make sense. For example, if  
#'  \code{projection=c("PCATF", "PCA_var", "PCA_kurt")} and 
#'  \code{out_meas=c("leverage", "robdist")} then these five
#'  combinations will be used: PCATF with leverage, PCA + variance with 
#'  leverage, PCA + variance with robust distance, PCA + kurtosis with leverage,
#'  and PCA + kurtosis with robust distance. Each method combination will yield 
#'  its own results.
#' 
#' In addition to the measures supported by \code{\link{clever}}, this function
#'  also can perform FD or CompCor.
#' 
#' @inheritParams data_clever_CompCor_Params
#' @param measures Character vector indicating the measures to compute. Choose 
#'  at least one of the following: 
#' 
#'  \describe{
#'    \item{\code{"leverage"}}{PCA leverage (the mean of the squared PC scores)}
#'    \item{\code{"robdist"}}{Robust Mahalanobis-based distance}
#'    \item{\code{"DVARS"}}{traditional DVARS}
#'    \item{\code{"DVARS2"}}{Delta-percent-DVARS and z-score-DVARS (Afyouni and 
#'      Nichols, 2018)}
#'    \item{\code{"FD"}}{Framewise Displacement. \code{X_motion} is required.}
#'    \item{\code{"motion"}}{Translation and rotation realignment parameters. 
#'      \code{X_motion} is required.}
#'    \item{\code{"CompCor"}}{anatomical CompCor based on the ROIs. \code{ROI_data} 
#'      and \code{ROI_noise} are required.}
#'    \item{\code{"GSR"}}{Global Signal of the data.}
#'  }
#' 
#'  Use \code{"all"} to select all available measures. (CompCor will
#'  only be computed if the ROIs are provided, and FD and motion will only be 
#'  computed if the motion realignment parameters are provided.) Default: 
#'  \code{"leverage", "DVARS2"}.
#'
#'  Note that motion, CompCor and GSR are not direct measures of outlyingness,
#'  so they do not have corresponding \code{outlier_cutoffs}.
#' @param X_motion Only used if the \code{"FD"} measure is requested. An 
#'  \eqn{N \times 6} matrix in which the first three columns represent the
#'  translational realignment parameters (mm), and the second three columns represent
#'  the rotational realignment parameters in (radians). To convert radians to mm,
#'  the displacement on a sphere of radius 50 mm will be computed.
#'
#'  Alternatively, this can be the file path to an \eqn{N \times 6} matrix which can be
#'  read with \code{\link{read.table}} (fields separated by white-space; no
#'  header).
#' @param projections Only applies to the \code{"leverage"} and \code{"robdist"} 
#'  measures. These work by projecting the data onto directions likely to 
#'  contain outlier information. Choose at least one of the following:
#' 
#'  \describe{
#'    \item{\code{"PCA_var"}}{PCA using the PCs of above-average variance/chosen by PESEL. Compatible with both leverage and robust distance.}
#'    \item{\code{"PCA_kurt"}}{PCA using the PCs of high kurtosis and above-average variance/chosen by PESEL. Compatible with both leverage and robust distance.}
#'    \item{\code{"PCATF"}}{PCATF using the trend-filtered PCs of above-average variance/chosen by PESEL. Compatible with only leverage.}
#'    \item{\code{"ICA_var"}}{ICA using the ICs of above-average variance/chosen by PESEL. Compatible with both leverage and robust distance.}
#'    \item{\code{"ICA_kurt"}}{ICA using the ICs of high kurtosis and above-average variance/chosen by PESEL. Compatible with both leverage and robust distance.}
#'  }
#'  
#'  Use \code{"all"} to use all projection methods. Default: \code{"PCA_kurt"}.
#'  
#'  Each compatible measure + projection combination will yield its own result.
#'  For example, if all PCA-related projections are used and both leverage and robust distance
#'  are requested, the results will be: leverage of high-variance PCs, leverage
#'  of high-kurtosis PCs, leverage of trend-filtered PCs, robust distance of
#'  high-variance PCs, and robust distance of high-kurtosis PCs.
#' @param solve_PC_dirs Only applies to the \code{"leverage"} and \code{"robdist"} 
#'  measures. Should the PCA and PCATF principal directions be computed? 
#'  Default: \code{FALSE} (conserves memory). Required to use \code{leverage_images}
#'  for PCA.
#' @param center_X,scale_X Center the columns of the data by median, and scale the
#'  columns of the data by MAD? Default: \code{TRUE}. Centering is necessary
#'  for detrending and for computing PCA/ICA, so if this is set to \code{FALSE}, 
#'  the input data must already be centered. Also affects noise ROI data for 
#'  CompCor..
#' @param detrend_X Detrend the columns of the data using the DCT? Use an integer
#'  to indicate the number of cosine bases to use for detrending (default: \code{4}).
#'  Or, use \code{0} to forgo detrending. 
#' 
#'  The data must be centered, either before input or with \code{center_X}.
#' 
#'  Detrending is highly recommended for time-series data, especially if there 
#'  are many time points or evolving circumstances affecting the data. Additionally,
#'  for the kurtosis-based projection, trends can induce positive or negative kurtosis,
#'  contaminating the connection between high kurtosis and outlier presence. 
#'  
#'  Detrending should not be used with non-time-series data because the 
#'  observations are not temporally related.
#' @param PCATF_kwargs Options for the \code{"PCATF"} projection. Valid entries 
#'  are: 
#'  
#'  \describe{
#'    \item{K}{Maximum number of PCs to compute. Default: \code{100}. Cannot be set above 100.}
#'    \item{lambda}{Trend-filtering parameter. Default: \code{0.05}.}
#'    \item{niter_max}{Maximum number of iterations. Default: \code{1000}.}
#'    \item{verbose}{Print updates? Default: \code{FALSE}.}
#'  }
#' @param kurt_quantile Only applies to the \code{"PCA_kurt"} and \code{"ICA_kurt"} projections. 
#'  What cutoff quantile for kurtosis should be used to select the PCs? 
#'  Default: \code{0.95}.
#' @param noise_nPC Only applies to the CompCor measure.
#'  The number of principal components to compute for each noise
#'  ROI. Alternatively, values between 0 and 1, in which case they will 
#'  represent the minimum proportion of variance explained by the PCs used for
#'  each noise ROI. The smallest number of PCs will be used to achieve this 
#'  proportion of variance explained. 
#' 
#'  Should be a list or numeric vector with the same length as \code{ROI_noise}. 
#'  It will be matched to each ROI based on the name of each entry, or if the 
#'  names are missing, the order of entries. If it is an unnamed vector, its
#'  elements will be recycled. Default: \code{5} (compute the top 5 PCs for 
#'  each noise ROI).
#' @param noise_erosion Only applies to the CompCor measure.
#'  The number of voxel layers to erode the noise ROIs by. 
#'  Should be a list or numeric vector with the same length as \code{ROI_noise}. 
#'  It will be matched to each ROI based on the name of each entry, or if the 
#'  names are missing, the order of entries. If it is an unnamed vector, its 
#'  elements will be recycled. Default: \code{NULL}, which will use a value of
#'  0 (do not erode the noise ROIs).
#' @param get_outliers Should outliers be flagged based on cutoffs? Default: \code{TRUE}.
#' @param outlier_cutoffs Named list indicating the cutoff for each outlyingness measure.
#'  Only used if \code{get_outliers}. Each cutoff is specified in a particular way:
#' 
#'  \describe{
#'    \item{\code{"leverage"}}{Minimum leverage value, in multiples of the median leverage. Default: \code{4} (will flag leverage scores more than four times the median).}
#'    \item{\code{"robdist"}}{Minimum robust distance quantile, based on the estimated F distribution. Default: \code{.9999} (will flag robust distance scores above the 99.99th percentile).}
#'    \item{\code{"DVARS"}}{Minimum traditional-DVARS value. Default: \code{5}}
#'    \item{\code{"DVARS2"}}{A length-2 numeric vector representing a dual 
#'      Delta-percent-DVARS and z-score-DVARS cutoff. Both must be met for a 
#'      timepoint to be flagged. The Delta-percent-DVARS cutoff should be given
#'      in percentages; the z-score-DVARS cutoff should be given as a z-score. 
#'      Or, set this to "Afyouni-Nichols" (default) to require a
#'      Delta-percent-DVARS of more than 5\% and a z-score-DVARS greater than
#'      the right-tail 5\% significance level with Bonferroni FWER correction).}
#'    \item{\code{"FD"}}{Minimum FD. Default: 0.5 mm (will flag FD scores greater than 0.5 mm).}
#'  }
# @param R_true The N x N correlation matrix, if known. Used for the bootstrap
#  robust distance measure.
#' @param full_PCA Return the full SVD? Default: \code{FALSE} (return
#'  only the components used to compute the measures).
#' @param verbose Should occasional updates be printed? Default: \code{FALSE}.
#'
#' @return A \code{"clever_multi"} object, i.e. a list with components
#' \describe{
#'  \item{measures}{
#'    A data.frame of the measures (only those requested will be included):
#'    \describe{
#'      \item{leverage__PCA_var}{Leverage values of the "PCA_var" projection.}
#'      \item{leverage__PCA_kurt}{Leverage values of the "PCA_kurt" projection.}
#'      \item{leverage__PCATF}{Leverage values of the "PCATF" projection.}
#'      \item{leverage__ICA_var}{Leverage values of the "ICA_var" projection.}
#'      \item{leverage__ICA_kurt}{Leverage values of the "ICA_kurt" projection.}
#'      \item{robdist__PCA_var}{Robust distance values of the "PCA_var" projection.}
#'      \item{robdist__PCA_kurt}{Robust distance values of the "PCA_kurt" projection.}
#'      \item{robdist__ICA_var}{Robust distance values of the "ICA_var" projection.}
#'      \item{robdist__ICA_kurt}{Robust distance values of the "ICA_kurt" projection.}
#'      \item{DVARS}{Traditional DVARS values.}
#'      \item{DVARS__DPD}{Delta-percent-DVARS values.}
#'      \item{DVARS_ZD}{z-score-DVARS values.}
#'      \item{FD}{Framewise Displacement values}
#'      \item{motion_t1}{First translation realignment parameter.}
#'      \item{motion_t2}{Second translation realignment parameter.}
#'      \item{motion_t3}{Third translation realignment parameter.}
#'      \item{motion_r1}{First rotation realignment parameter.}
#'      \item{motion_r2}{Second rotation realignment parameter.}
#'      \item{motion_r3}{Third rotation realignment parameter.}
#'      \item{GSR}{The global signal of the data.}
#'    }
#'  }
#'  \item{outlier_cutoffs}{
#'    A vector of the outlier cutoffs for each outlyingness measure (see the 
#'    \code{outlier_cutoffs} argument; only those requested will be included):
#'    \describe{
#'      \item{leverage__PCA_var}{Minimum leverage.}
#'      \item{leverage__PCA_kurt}{Minimum leverage.}
#'      \item{leverage__PCATF}{Minimum leverage.}
#'      \item{leverage__ICA_var}{Minimum leverage.}
#'      \item{leverage__ICA_kurt}{Minimum leverage.}
#'      \item{robdist__PCA_var}{Minimum robust distance.}
#'      \item{robdist__PCA_kurt}{Minimum robust distance.}
#'      \item{robdist__ICA_var}{Minimum robust distance.}
#'      \item{robdist__ICA_kurt}{Minimum robust distance.}
#'      \item{DVARS}{Minimum traditional DVARS.}
#'      \item{DVARS__DPD}{Minimum Delta-percent-DVARS.}
#'      \item{DVARS_ZD}{Minimum z-score-DVARS.}
#'      \item{FD}{Minimum Framewise Displacement.}
#'    }
#'  }
#'  \item{outlier_flags}{
#'    Applies \code{outlier_cutoffs} to \code{measures}: a logical data.frame with
#'    \eqn{T} rows where \code{TRUE} values indicate suspected outlier presence. The DVARS2 flag indicates where both DPDVARS and ZDVARS exceeded their cutoffs.
#'  }
#'  \item{ROIs}{
#'    \describe{
#'      \item{data}{The mask of locations in the data ROI.}
#'      \item{[Noise1]}{The mask of locations in the first noise ROI, if it was relative to \code{X}.}
#'      \item{...}{...}
#'      \item{[Noisek]}{The mask of locations in the kth (last) noise ROI, if it was relative to \code{X}.}
#'    }
#'  }
#'  \item{PCA}{
#'    If the "PCA_var" or "PCA_kurt" projections were used, this will be a list with components:
#'    \describe{
#'      \item{U}{The \eqn{N x Q} PC score matrix. Only PCs with above-average variance/chosen by PESEL will be included.}
#'      \item{D}{The standard deviation of each PC. Only PCs with above-average variance/chosen by PESEL will be included.}
#'      \item{V}{The \eqn{P x Q} PC directions matrix. Included only if \code{solve_PC_dirs}}
#'      \item{kurt_idx}{The length \code{Q} kurtosis rankings, with 1 indicating the highest-kurtosis PC 
#'        (among those of above-average variance/chosen by PESEL) and \code{NA} indicating a PC with kurtosis below
#'        the quantile cutoff. Only included if the "PCA_kurt" projection was used.}
#'    }
#'  }
#'  \item{PCATF}{
#'    If the "PCATF" projection was used, this will be a list with components:
#'    \describe{
#'      \item{U}{The \eqn{N x Q} PC score matrix. Only PCs with above-average variance/chosen by PESEL will be included.}
#'      \item{D}{The standard deviation of each PC. Only PCs with above-average variance/chosen by PESEL will be included.}
#'      \item{V}{The \eqn{P x Q} PC directions matrix. Included only if \code{solve_PC_dirs}}
#'    }
#'  }
#'  \item{ICA}{
#'    If the "ICA_var" or "ICA_kurt" projections were used, this will be a list with components:
#'    \describe{
#'      \item{S}{The \eqn{P x Q} source signals matrix.} 
#'      \item{M}{The \eqn{N x Q} mixing matrix. Only ICs with above-average variance/chosen by PESEL will be included.}
#'      \item{M_dt}{The \eqn{N x Q} detrended mixing matrix. Included only if \code{detrend_X > 0}}
#'      \item{kurt_idx}{The length \code{Q} kurtosis rankings, with 1 indicating the highest-kurtosis IC 
#'        (among those of above-average variance/chosen by PESEL) and \code{NA} indicating an IC with kurtosis below
#'        the quantile cutoff. Only included if the "ICA_kurt" projection was used.}
#'    }
#'  }
#'  \item{CompCor}{
#'    If CompCor is computed, this will be a list with components: 
#'    \describe{
#'      \item{[Noise1]}{
#'        \describe{
#'          \item{U}{The \eqn{N x Q} PC score matrix for Noise1.}
#'          \item{D}{The standard deviation of each PC for Noise1.}
#'          \item{Dsq_total}{The sum of squared D values (total variance).}
#'        }
#'      }
#'      \item{...}{...}
#'      \item{[Noisek]}{
#'        \describe{
#'          \item{U}{The \eqn{N x Q} PC score matrix for Noisek.}
#'          \item{D}{The standard deviation of each PC for Noisek.}
#'          \item{Dsq_total}{The sum of squared D values (total variance).}
#'        }
#'      }
#'    }
#'  }
#'  \item{robdist_info}{
#'    If the "robdist" measure was used, this will be a list with components:
#'    \describe{
#'      \item{PCA_var}{
#'      If the "PCA_var" projection was used, this will be a list with components:
#'        \describe{
#'          \item{inMCD}{Logical vector indicating whether each observation was in the MCD estimate.}
#'          \item{outMCD_scale}{The scale for out-of-MCD observations.}
#'          \item{Fparam}{Named numeric vector: \code{c}, \code{m}, \code{df1}, and \code{df2}.}
#'        }
#'      }
#'      \item{PCA_kurt}{
#'      If the "PCA_kurt" projection was used, this will be a list with components:
#'        \describe{
#'          \item{inMCD}{Logical vector indicating whether each observation was in the MCD estimate.}
#'          \item{outMCD_scale}{The scale for out-of-MCD observations.}
#'          \item{Fparam}{Named numeric vector: \code{c}, \code{m}, \code{df1}, and \code{df2}.}
#'        }
#'      }
#'      \item{ICA_var}{
#'      If the "ICA_var" projection was used, this will be a list with components:
#'        \describe{
#'          \item{inMCD}{Logical vector indicating whether each observation was in the MCD estimate.}
#'          \item{outMCD_scale}{The scale for out-of-MCD observations.}
#'          \item{Fparam}{Named numeric vector: \code{c}, \code{m}, \code{df1}, and \code{df2}.}
#'        }
#'      }
#'      \item{ICA_kurt}{
#'      If the "ICA_kurt" projection was used, this will be a list with components:
#'        \describe{
#'          \item{inMCD}{Logical vector indicating whether each observation was in the MCD estimate.}
#'          \item{outMCD_scale}{The scale for out-of-MCD observations.}
#'          \item{Fparam}{Named numeric vector: \code{c}, \code{m}, \code{df1}, and \code{df2}.}
#'        }
#'      }
#'    }
#'  }
#' }
#'
#' @importFrom pesel pesel
#' @importFrom robustbase rowMedians
#' @importFrom stats mad qnorm var setNames
#'
#' @examples
#' n_voxels = 1e4
#' n_timepoints = 100
#' X = matrix(rnorm(n_timepoints*n_voxels), ncol = n_voxels)
#'
#' clev = clever_multi(X)
clever_multi = function(
  X,
  measures=c("leverage", "DVARS2"),
  ROI_data="infer", ROI_noise=NULL, X_motion=NULL,
  projections = "PCA_kurt", solve_PC_dirs=FALSE,
  center_X=TRUE, scale_X=TRUE, detrend_X=4,
  noise_nPC=5, noise_erosion=NULL,
  PCATF_kwargs=NULL, kurt_quantile=.95,
  get_outliers=TRUE, 
  outlier_cutoffs=list(leverage=4, robdist=.9999, DVARS=5, DVARS2="Afyouni-Nichols", FD=.5),
  full_PCA=FALSE,
  verbose=FALSE){

  # Define the cutoff value for detecting zero variance/MAD voxels
  TOL <- 1e-8

  # ----------------------------------------------------------------------------
  # Check arguments. -----------------------------------------------------------
  # ----------------------------------------------------------------------------

  # Measures and projections ---------------------------------------------------

  measures0 <- measures
  valid_measures0 <- c(
    "leverage", "robdist", "DVARS", "DVARS2", "FD", # robdist_bootstrap
    "motion", "CompCor", "GSR" 
  ) 
  if ("all" %in% measures0) {
    measures0 <- c("leverage", "robdist", "DVARS", "DVARS2", "GSR")
    if (!is.null(ROI_data) && !is.null(ROI_noise)) { measures0 <- c(measures0, "CompCor") }
    if (!is.null(X_motion)) { measures0 <- c(measures0, "FD", "motion") }
  } else {
    measures0 <- unique(match.arg(measures0, valid_measures0, several.ok=TRUE))
  }

  valid_projections <- c(
    "PCA_var", "PCA_kurt", "PCA2_var", "PCA2_kurt", "PCATF", 
    "ICA_var", "ICA_kurt", "ICA2_var", "ICA2_kurt"
  )
  if ("PCA" %in% projections) {
    projections <- c(projections, c("PCA_var", "PCA_kurt"))
    projections <- projections[projections == "PCA"]
  }
  if ("ICA" %in% projections) {
    projections <- c(projections, c("ICA_var", "ICA_kurt"))
    projections <- projections[projections == "ICA"]
  }

  # [TEMPORARY]
  if (any(grepl("ICA", projections))) { stopifnot(any(grepl("PCA", projections))) }

  if ("all" %in% projections) {
    projections <- valid_projections
  } else {
    projections <- unique(match.arg(projections, valid_projections, several.ok=TRUE))
  }

  if ("CompCor" %in% measures) {
    if (is.null(ROI_noise)) { stop("`CompCor` requires the noise ROIs.") }
  }


  # Data -----------------------------------------------------------------------
  temp <- format_data(
    X=X, ROI_data=ROI_data, ROI_noise=ROI_noise, 
    noise_nPC=noise_nPC, noise_erosion=noise_erosion
  )
  X <- temp$X; X_noise <- temp$X_noise
  ROI_data <- temp$ROI_data; ROI_noise <- temp$ROI_noise
  noise_nPC <- temp$noise_nPC; noise_erosion <- temp$noise_erosion
  rm(temp)

  # Get data dimensions.
  Vpre_ <- ncol(X); T_ <- nrow(X)
  if(Vpre_ < T_){
    warning(
      "Data matrix has more rows than columns. Check that observations\
      are in rows and variables are in columns."
    )
  }

  # Full enumeration of measures -----------------------------------------------

  measures <- measures0
  use_PCA <- use_PCATF <- use_ICA <- FALSE
  if ("leverage" %in% measures) {
    if (any(grepl("PCA", projections, fixed=TRUE))) { use_PCA <- TRUE }
    if (any(grepl("ICA", projections, fixed=TRUE))) { use_ICA <- TRUE }
    if ("PCATF" %in% projections) { use_PCATF <- TRUE }
    measures <- measures[measures != "leverage"]
    measures <- c(measures, paste0("leverage__", projections))
  }
  if ("robdist" %in% measures) {
    if (any(grepl("PCA", projections, fixed=TRUE))) { use_PCA <- TRUE }
    if (any(grepl("ICA", projections, fixed=TRUE))) { use_ICA <- TRUE }
    measures <- measures[measures != "robdist"]
    measures <- c(measures, paste0("robdist__", projections))
    measures <- measures[measures != "robdist__PCATF"] # not compatible
  }
  if ("DVARS" %in% measures) {
    measures[measures == "DVARS"] <- "DVARS__traditional"
  }
  if ("DVARS2" %in% measures) {
    measures <- measures[measures != "DVARS2"]
    measures <- c(measures, "DVARS__DPD", "DVARS__ZD")
  }
  if ("motion" %in% measures) {
    measures <- measures[measures != "motion"]
    measures <- c(measures, paste0("motion_t", 1:3), paste0("motion_r", 1:3))
  }

  # Format output --------------------------------------------------------------

  out <- list(
    measures = list(), 
    ROIs=c(list(data=ROI_data), ROI_noise), 
    outlier_cutoffs=list(), outlier_flags=list()
  )
  
  if (use_PCA) { out <- c(out, list(PCA=NULL)) }
  if (use_PCATF) { out <- c(out, list(PCATF=NULL)) }
  if (use_ICA) { out <- c(out, list(ICA=NULL)) }

  if ("CompCor" %in% measures) {
    out$CompCor <- setNames(vector("list", length(X_noise)), names(X_noise))
  }
  
  with_robdist <- grepl("robdist", measures, fixed=TRUE)
  if (any(with_robdist)) {
    with_robdist <- gsub("robdist__", "", measures[with_robdist], fixed=TRUE)
    out <- c(
      out, list(robdist_info=setNames(vector("list", length(with_robdist)), with_robdist))
    )
  }

  # Cutoffs --------------------------------------------------------------------

  outlier_cutoffs <- as.list(outlier_cutoffs)
  # Use default values for each cutoff not specified.
  outlier_cutoffs_defaults <- list(
    leverage=4, robdist=.9999, DVARS=5, DVARS2="Afyouni-Nichols", FD=.5
  )
  for (meas in names(outlier_cutoffs_defaults)) {
    if (!(meas %in% names(outlier_cutoffs))) { 
      outlier_cutoffs[[meas]] <- outlier_cutoffs_defaults[[meas]]
    }
  }
  # Check validity.
  stopifnot(all(sapply(outlier_cutoffs[names(outlier_cutoffs)!="DVARS2"], length) == 1))
  stopifnot(is.numeric(outlier_cutoffs$leverage) & outlier_cutoffs$leverage > 0)
  stopifnot(is.numeric(outlier_cutoffs$robdist))
  stopifnot((outlier_cutoffs$robdist > 0) & (outlier_cutoffs$robdist < 1))
  stopifnot(is.numeric(outlier_cutoffs$DVARS))
  if (is.character(outlier_cutoffs$DVARS2)) { 
    stopifnot(outlier_cutoffs$DVARS2 == "Afyouni-Nichols")
    outlier_cutoffs$DVARS2 <- c(5, qnorm(1-.05/T_))
  }
  stopifnot(is.numeric(outlier_cutoffs$DVARS2) && length(outlier_cutoffs$DVARS2) == 2)
  stopifnot(all(outlier_cutoffs$DVARS2 > 0))
  outlier_cutoffs$DVARS__DPD <- outlier_cutoffs$DVARS2[1]
  outlier_cutoffs$DVARS__ZD <- outlier_cutoffs$DVARS2[2]
  outlier_cutoffs$DVARS2 <- NULL
  names(outlier_cutoffs)[names(outlier_cutoffs)=="DVARS"] <- "DVARS__traditional"
  stopifnot(is.numeric(outlier_cutoffs$FD) & outlier_cutoffs$FD > 0)

  for (meas in names(outlier_cutoffs_defaults)) {
    if (!any(grepl(meas, measures, fixed=TRUE))) { outlier_cutoffs[[meas]] <- NULL }
  }

  # Other arguments ------------------------------------------------------------

  is.TRUEorFALSE <- function(x) { length(x)==1 && is.logical(x) }
  stopifnot(is.TRUEorFALSE(solve_PC_dirs))
  stopifnot(is.TRUEorFALSE(get_outliers))
  stopifnot(is.TRUEorFALSE(verbose))
  stopifnot(is.TRUEorFALSE(center_X))
  stopifnot(is.TRUEorFALSE(scale_X))
  

  if (identical(detrend_X, TRUE)) {
    cat("Note: `detrend_X` was `TRUE`, but expected a number. Using 4 cosine bases.")
    do_detrend_X <- TRUE
  } else if (identical(detrend_X, FALSE)) {
    detrend_X <- 0
    do_detrend_X <- FALSE
  } else {
    stopifnot(is.numeric(detrend_X))
    do_detrend_X <- detrend_X > 0
  }
  stopifnot(is.TRUEorFALSE(do_detrend_X))

  if(!identical(PCATF_kwargs, NULL)){
    names(PCATF_kwargs) <- match.arg(
      names(PCATF_kwargs), c("K", "lambda", "niter_max", "TOL", "verbose"),
      several.ok=TRUE)
    if(length(names(PCATF_kwargs)) != length(unique(names(PCATF_kwargs)))){
      stop("Duplicate PCATF_kwargs were given.")
    }
  }

  stopifnot((kurt_quantile < 1) & (kurt_quantile > 0))

  # ----------------------------------------------------------------------------
  # Compute GSR. ---------------------------------------------------------------
  # ----------------------------------------------------------------------------

  if ("GSR" %in% measures) {
    if (verbose) { cat("Computing GSR.\n") }
    out$measures$GSR <- apply(X, 1, mean)
  }

  # ----------------------------------------------------------------------------
  # Compute Motion and FD. -----------------------------------------------------
  # ----------------------------------------------------------------------------

  if ("motion" %in% measures | "FD" %in% measures) {
    if (verbose) {
      what <- c("motion", "FD", "motion and FD")[
        ("motion" %in% measures)*1 + ("FD" %in% measures)*2
      ]
      cat(paste0("Computing ", what, ".\n"))
    }

    stopifnot(!is.null(X_motion))
    X_motion <- FD(X_motion)
    stopifnot(nrow(X_motion) == T_)
  }

  if ("motion" %in% measures) {
    out$measures[c(paste0("motion_t", 1:3), paste0("motion_r", 1:3))] <- X_motion
  }

  if ("FD" %in% measures) {
    if (verbose) { cat("Computing FD.\n") }
    out$measures$FD <- X_motion
    if (get_outliers) {
      out$outlier_cutoffs$FD <- outlier_cutoffs$FD
      out$outlier_flags$FD <- X_motion > out$outlier_cutoffs$FD
    }
  }

  # ----------------------------------------------------------------------------
  # Center, scale, and detrend the data. ---------------------------------------
  # Do it here instead of calling `scale_med` to save memory. ------------------
  # ----------------------------------------------------------------------------
  
  # [TO-DO: Skip if only Motion/FD/GSR requested.]
  if (verbose) { 
    action <- c(
      "Centering",
      "Scaling",
      "Centering and scaling",
      "Detrending",
      "Centering and detrending",
      "Scaling and detrending",
      "Centering, scaling, and detrending"
    )[1*center_X + 2*scale_X + 4*do_detrend_X]
    cat(action, "the data matrix.\n")
  }
  # Transpose.
  X <- t(X)
  #	Center.
  if (center_X) { X <- X - c(rowMedians(X, na.rm=TRUE)) }
  # Detrend.
  if (do_detrend_X) {
    B <- dct_bases(T_, detrend_X) / sqrt((T_+1)/2)
    X <- t((diag(T_) - (B %*% t(B))) %*% t(X))
  }
  #	Center again for good measure.
  if (do_detrend_X && center_X) { X <- X - c(rowMedians(X, na.rm=TRUE)) }
  # Compute MADs.
  mad <- 1.4826 * rowMedians(abs(X), na.rm=TRUE)
  X_constant <- mad < TOL
  if (any(X_constant)) {
    if (all(X_constant)) {
    stop("All data locations are zero-variance.\n")
    } else {
      warning(paste0("Warning: ", sum(X_constant),
      " constant data locations (out of ", length(X_constant),
      "). These will be removed for estimation of the covariance.\n"))
    }

    ROI_constant <- out$ROIs$data
    ROI_constant[ROI_constant][!X_constant] <- FALSE
    out$ROIs$data[out$ROIs$data][X_constant] <- FALSE
    out$ROIs <- c(out$ROIs["data"], list(constant=ROI_constant), out$ROIs[names(out$ROIs) != "data"])
  }
  mad <- mad[!X_constant]; X <- X[!X_constant,]; V_ <- ncol(X)
  # Scale.
  if (scale_X) { X <- X/c(mad) }
  # Revert transpose.
  X <- t(X)

  # ----------------------------------------------------------------------------
  # Compute DVARS. -------------------------------------------------------------
  # ----------------------------------------------------------------------------

  if (any(grepl("DVARS", measures))) {
    if (verbose) { cat("Computing DVARS.\n") }
    X_DVARS <- DVARS(X, normalize=FALSE, norm_I=100, verbose=verbose)

    if ("DVARS__traditional" %in% measures) {
      out$measures["DVARS__traditional"] <- X_DVARS["DVARS"]
    }

    if ("DVARS__DPD" %in% measures) {
      out$measures[c("DVARS__DPD", "DVARS__ZD")] <- X_DVARS[c("DPD", "ZD")]
    }

    if(get_outliers){
      if ("DVARS__traditional" %in% measures) {
        out$outlier_cutoffs["DVARS__traditional"] <- outlier_cutoffs["DVARS__traditional"]
        out$outlier_flags$DVARS__traditional <- out$measures$DVARS__traditional > out$outlier_cutoffs$DVARS__traditional
      }

      if ("DVARS__DPD" %in% measures) {
        out$outlier_cutoffs[c("DVARS__DPD", "DVARS__ZD")] <- outlier_cutoffs[c("DVARS__DPD", "DVARS__ZD")]
        DVARS__dual1 <- out$measures$DVARS__DPD > out$outlier_cutoffs$DVARS__DPD
        DVARS__dual2 <- out$measures$DVARS__ZD > out$outlier_cutoffs$DVARS__ZD
        out$outlier_flags$DVARS__dual <- DVARS__dual1 & DVARS__dual2
        rm(DVARS__dual1, DVARS__dual2)
      }
    }
  }

  # ----------------------------------------------------------------------------
  # Compute CompCor. -----------------------------------------------------------
  # ----------------------------------------------------------------------------

  if (any(grepl("CompCor", measures, fixed=TRUE))) {
    if (verbose) { cat("Computing CompCor.\n") }
    X_CompCor <- CompCor.noise_comps(X_noise, center_X,scale_X,detrend_X, noise_nPC)
    for (ii in seq_len(length(X_CompCor$noise_comps))) {
      out$CompCor[[names(X_noise)[ii]]] <- list(
        U = X_CompCor$noise_comps[[ii]],
        D = sqrt(X_CompCor$noise_var[[ii]]),
        Dsq_total = X_CompCor$noise_vartotal[[ii]]
      )
      names(out$CompCor[[names(X_noise)[ii]]]$Dsq_total) <- NULL
    }
  }

  # ----------------------------------------------------------------------------
  # Make projections. ----------------------------------------------------------
  # ----------------------------------------------------------------------------

  nComps <- NULL

  # Compute the PC scores (and directions, if leverage images or PCATF are desired).
  if (any(grepl("PCA", measures, fixed=TRUE))) {
    if ("PCATF" %in% projections) { solve_PC_dirs <- TRUE }
    if (verbose) {
      cat(paste0(
        "Computing the",
        ifelse(
          ("PCA_var" %in% projections) | ("PCA_kurt" %in% projections),
          ifelse("PCATF" %in% projections, " normal and trend-filtered", ""),
          ifelse("PCATF" %in% projections, " trend-filtered", "INTERNAL ERROR")
        ),
        " PC scores",
        ifelse(solve_PC_dirs, " and directions", ""), ".\n"
      ))
    }

    if (solve_PC_dirs) {
      out$PCA <- svd(X)
      names(out$PCA) <- toupper(names(out$PCA))
    } else {
      # Conserve memory by using `XXt`.
      XXt <- tcrossprod(X)
      out$PCA <- svd(XXt)
      names(out$PCA) <- toupper(names(out$PCA))
      rm(XXt)
      out$PCA$D <- sqrt(out$PCA$D)
      out$PCA$V <- NULL
    }

    # Keep only the above-average variance/chosen by PESEL PCs (whichever is greater).
    out$PCA$nPCs_avgvar <- max(1, sum(out$PCA$D^2 > mean(out$PCA$D^2)))
    out$PCA$nPCs_PESEL <- pesel::pesel(t(X), npc.max=ceiling(T_/2), method="homogenous")$nPCs
    nComps <- max(1, out$PCA$nPCs_avgvar, out$PCA$nPCs_PESEL)

    # Compute PCATF, if requested.
    if("PCATF" %in% projections){
      if (verbose) { cat("Computing PCATF.\n") }
      out$PCATF <- do.call(
        PCATF_cppcore, 
        c(
          list(
            X=X, X.svd=out$PCA[c("U", "D", "V")], 
            K=out$PCA$nPCs_PESEL, solve_directions=solve_PC_dirs
          ), 
          PCATF_kwargs
        )
      )
      if(!solve_PC_dirs){ out$PCA$V <- NULL }

      tf_zero_var <- apply(out$PCATF$u, 2, var) < TOL
      if(any(tf_zero_var)){
        if(all(tf_zero_var)){
          stop("Error: All trend-filtered PC scores are zero-variance.")
        }
        warning(paste(
          "Warning:", sum(tf_zero_var), "trend-filtered PC scores are zero-variance.\n"
        ))
      }
      names(out$PCATF) <- toupper(names(out$PCATF))
    }

    if (any(grepl("PCA_kurt|PCA2_kurt", measures))) {
      out$PCA$highkurt <- high_kurtosis(
        out$PCA$U, kurt_quantile=kurt_quantile
      )
    }

    if (!full_PCA) {
      out$PCA$U <- out$PCA$U[, seq_len(nComps), drop=FALSE]
      out$PCA$D <- out$PCA$D[seq_len(nComps), drop=FALSE]
      if (solve_PC_dirs) { 
        out$PCA$V <- out$PCA$V[, seq_len(nComps), drop=FALSE]
      }
    }
  }

  # Compute ICA
  if (any(grepl("ICA", measures, fixed=TRUE))) {
    if (verbose) { cat(paste0( "Computing ICA.\n" )) }

    if (!requireNamespace("ica", quietly = TRUE)) {
      stop("Package \"ica\" needed to compute the ICA. Please install it.", call. = FALSE)
    }

    # [TEMPORARY] PCA was required, so `nComps` exists
    if (is.null(nComps)) { 
      stop("nComps was NULL.")
    }
    out$ICA <- ica::icaimax(t(X), nComps, center=FALSE)[c("S", "M")]
    # Issue due to rank.
    if (ncol(out$ICA$M) != nComps) {
      # [TEMPORARY]
      cat("Rank issue with ICA.\n")
      nComps_missing <- nComps - ncol(out$ICA$M)
      out$ICA$M <- cbind(out$ICA$M, matrix(0, nrow=nrow(out$ICA$M), ncol=nComps_missing) )
    }

    if (any(grepl("ICA_kurt|ICA2_kurt", measures))) {
      out$ICA$highkurt <- high_kurtosis(
        out$ICA$M, kurt_quantile=kurt_quantile
      )
    }
  }

  rm(X); gc()

  # ----------------------------------------------------------------------------
  # Compute projection-based measures. -----------------------------------------
  # ----------------------------------------------------------------------------

  measures_proj <- measures[grepl("PCA", measures, fixed=TRUE) | grepl("ICA", measures, fixed=TRUE)]
  for (ii in seq_len(length(measures_proj))) {
    meas_ii <- unlist(strsplit(measures_proj[ii], "__"))
    proj_ii <- meas_ii[2]; meas_ii <- meas_ii[1]

    if (verbose) { 
      cat(paste("Computing", meas_ii, "with", proj_ii, "projection."))
    }

    # [TEMPORARY] PCA was required, so `out$PCA` exists
    Comps_ii <- switch(proj_ii,
      PCA_var = seq_len(out$PCA$nPCs_avgvar),
      PCA_kurt = seq_len(out$PCA$nPCs_avgvar)[out$PCA$highkurt[seq_len(out$PCA$nPCs_avgvar)]],
      PCA2_var = seq_len(out$PCA$nPCs_PESEL),
      PCA2_kurt = seq_len(out$PCA$nPCs_PESEL)[out$PCA$highkurt[seq_len(out$PCA$nPCs_PESEL)]],
      PCATF = NULL,
      ICA_var = seq_len(out$PCA$nPCs_avgvar),
      ICA_kurt = seq_len(out$PCA$nPCs_avgvar)[out$ICA$highkurt[seq_len(out$PCA$nPCs_avgvar)]],
      ICA2_var = seq_len(out$PCA$nPCs_PESEL),
      ICA2_kurt = seq_len(out$PCA$nPCs_PESEL)[out$ICA$highkurt[seq_len(out$PCA$nPCs_PESEL)]],
    )

    # [TO DO]: Fix this in high_kurtosis
    if (length(Comps_ii) == 0 && grepl("2_", proj_ii, fixed=FALSE)) {
      cat(" (Temporary notice: using single highest-kurtosis PC in smaller PC subset.)")
      Comps_ii <- switch(proj_ii,
        PCA2_var = seq_len(out$PCA$nPCs_avgvar)[high_kurtosis(out$PCA$U[,seq(out$PCA$nPCs_avgvar),drop=FALSE], kurt_quantile=kurt_quantile)],
        PCA2_kurt = seq_len(out$PCA$nPCs_PESEL)[high_kurtosis(out$PCA$U[,seq(out$PCA$nPCs_PESEL),drop=FALSE], kurt_quantile=kurt_quantile)],
        ICA2_var = seq_len(out$PCA$nPCs_avgvar)[high_kurtosis(out$ICA$M[,seq(out$PCA$nPCs_avgvar),drop=FALSE], kurt_quantile=kurt_quantile)],
        ICA2_kurt = seq_len(out$PCA$nPCs_PESEL)[high_kurtosis(out$ICA$M[,seq(out$PCA$nPCs_PESEL),drop=FALSE], kurt_quantile=kurt_quantile)]
      )
    }

    Comps_ii <- switch(proj_ii,
      PCA_var = out$PCA$U[, Comps_ii, drop=FALSE],
      PCA_kurt = out$PCA$U[, Comps_ii, drop=FALSE],
      PCA2_var = out$PCA$U[, Comps_ii, drop=FALSE],
      PCA2_kurt = out$PCA$U[, Comps_ii, drop=FALSE],
      PCATF = out$PCATF$U,
      ICA_var = out$ICA$M[, Comps_ii, drop=FALSE],
      ICA_kurt = out$ICA$M[, Comps_ii, drop=FALSE],
      ICA2_var = out$ICA$M[, Comps_ii, drop=FALSE],
      ICA2_kurt = out$ICA$M[, Comps_ii, drop=FALSE]
    )
    
    # Adjust PC number if using robust distance.
    if (meas_ii %in% c("robdist", "robdist_bootstrap")) {
      # Let q <- N_/T_ (ncol(U)/nrow(U)). robustbase::covMcd()
      #  requires q <= approx. 1/2 for computation of the MCD covariance estimate.
      #  Higher q will use more components for estimation, thus retaining a
      #  higher resolution of information. Lower q will have higher breakdown
      #  points, thus being more resistant to outliers. (The maximal breakdown
      #  value is (N_ - T_ + 2)/2.) Here, we select q = 1/3 to yield a breakdown
      #  value of approx. 1/3. 
      #
      # For computational feasibility, we also limit the total number of PCs to 
      # 100.
      q <- 1/3
      max_keep = min(100, ceiling(T_*q))
      if (max_keep < ncol(Comps_ii)) {
        cat(paste0(
          " Reducing number of components from ", ncol(Comps_ii), " to ", max_keep, "."
        ))
        Comps_ii <- Comps_ii[,seq_len(max_keep),drop=FALSE]
      }
    }

    # Compute the outlyingness measure.
    result_ii <- switch(meas_ii,
      leverage = out_measures.leverage(Comps=Comps_ii, median_cutoff=outlier_cutoffs$leverage),
      robdist = out_measures.robdist(Comps=Comps_ii, quantile_cutoff=outlier_cutoffs$robdist)
    )
    
    out$measures[[measures_proj[ii]]] <- result_ii$meas
    if (get_outliers) {
      out$outlier_cutoffs[[measures_proj[ii]]] <- result_ii$cut
      out$outlier_flags[[measures_proj[ii]]] <- result_ii$flag
    }
    if (meas_ii == "robdist") {
      out$robdist_info[[proj_ii]] <- result_ii$info
    }
    if (verbose) { cat("\n") }
  }

  # ----------------------------------------------------------------------------
  # Done. ----------------------------------------------------------------------
  # ----------------------------------------------------------------------------

  out$measures <- as.data.frame(out$measures)
  if (get_outliers) {
    out$outlier_flags <- as.data.frame(out$outlier_flags)
    out$outlier_cutoffs <- do.call(c, out$outlier_cutoffs)
  }
  structure(out, class="clever_multi")
}