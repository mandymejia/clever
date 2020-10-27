#' data: for clever or CompCor
#' 
#' @param X Wide numerical data matrix (\eqn{T observations \times V variables}, \eqn{T << V}).
#'  For example, if \code{X} represents an fMRI run, \eqn{T} should be the number
#'  of timepoints and \eqn{V} should be the number of brainordinate vertices/voxels.
#' 
#'  Or, a 4D array or NIFTI or file path to a NIFTI (\eqn{I \times J \times K \times T} 
#'  observations), in which case \code{ROI_data} must be provided.
#' 
#'  Or, a \code{ciftiTools} code{"xifti"} object or a file path to a CIFTI
#'  (\eqn{V_{left} + V_{right} + V_{subcortical} \times T observations}).
#' @param ROI_data Indicates the data ROI. Can be a logical vector/array or 
#'  \code{"infer"} (default): 
#' 
#'  If \code{X} is a matrix, this must be a length \eqn{V} logical vector, where
#'  the data ROI is indicated by \code{TRUE} values. If \code{"infer"}, all 
#'  columns of \code{X} will be included in the data ROI (all \code{TRUE}).
#' 
#'  If \code{X} is an array or NIFTI, this must be either a vector of values
#'  to expect for out-of-mask voxels in \code{X}, or a (file path to a) 3D NIFTI.
#'  In the latter case, each of the volume dimensions should match the first
#'  three dimension of \code{X}. Voxels in the data ROI should be indicated by
#'  \code{TRUE} and all other voxels by \code{FALSE}. If \code{"infer"},
#'  will be set to \code{c(0, NA, NaN)} (include all voxels which are not constant
#'  \code{0}, \code{NA}, or \code{NaN}).
#' 
#'  If \code{X} is a \code{"xifti"} all data locations will be used and this
#'  should be left as \code{"infer"}.
#'
#'  If \code{NULL}, the data ROI will be empty. This is useful for obtaining just
#'  the noise ROI, if the data and noise are located in separate files.
#' @param ROI_noise Indicates the noise ROIs. Only used if the \code{"CompCor"} 
#'  measure is requested.
#'  
#'  If \code{X} is a matrix, this must be a list of length \eqn{V} logical
#'  vectors, or a list of matrices with \code{T} rows. The names of each entry should
#'  indicate the name of the noise ROI, e.g. \code{"white_matter"} and \code{"csf"}.
#'  In the first case, \code{TRUE} values should indicate the locations of \code{X} 
#'  within that noise ROI. Since the ROIs must not overlap, the masks must be 
#'  mutually exclusive with each other, and with \code{ROI_data}. In the second
#'  case, the rows of the matrix must represent noise brainordinate timecourses,
#'  separate from \code{X}. 
#' 
#'  If \code{X} is an array or NIFTI, this must be a list of (file paths to) 3D 
#'  NIFTIs or arrays, or a list of matrices with \code{T} rows. The names of 
#'  each entry should indicate the name of the noise ROI, e.g. 
#'  \code{"white_matter"} and \code{"csf"}. In the first case, each of the volume 
#'  dimensions should match the first three dimensions of \code{X}. Voxels in 
#'  each noise ROI should be indicated by \code{TRUE} and all other voxels by 
#'  \code{FALSE}. Since the ROIs must not overlap, the masks must be mutually 
#'  exclusive with each other, and with \code{ROI_data}. In the second case,
#'  the rows of the matrix must represent noise brainordinate timecourses,
#'  separate from \code{X}. 
#' 
#'  If \code{X} is a \code{"xifti"}, this must be a list of matrices with 
#'  \code{T} rows. The names of each entry should indicate the name of the noise
#'  ROI, e.g. \code{"white_matter"} and \code{"csf"}. The rows of the matrix 
#'  must represent noise brainordinate timecourses, separate from \code{X}. 
#' @name data_clever_CompCor_Params
NULL

#' noise parameters for CompCor
#' @param noise_nPC The number of principal components to compute for each noise
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
#' @param noise_erosion The number of voxel layers to erode the noise ROIs by. 
#'  Should be a list or numeric vector with the same length as \code{ROI_noise}. 
#'  It will be matched to each ROI based on the name of each entry, or if the 
#'  names are missing, the order of entries. If it is an unnamed vector, its 
#'  elements will be recycled. Default: \code{NULL}, which will use a value of
#'  0 (do not erode the noise ROIs).
#' @name noise_Params
NULL