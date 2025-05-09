#21.01.25
#This script contains the code for distSimMatch, and the main documentation
#block for distance_functions.Rd, which is the documentation page for
#all three help pages together.
#distGDM2.R contains code for distGDM2 and .projectIntofx
#distGower.R contains code for distGower, .ChooseVarDists, .ScaleVarSpecific,
# .delta, .distGower_mixedType and .distGower_SingleTypeNoNAs.

#' Distance Functions for K-Centroids Clustering of (Ordinal) Categorical/Mixed Data
#'
#' @description
#'
#' Functions to calculate the distance between a matrix `x` and a
#' matrix `c`, which can be used for K-centroids clustering via
#' [flexclust::kcca()].
#' 
#' `distSimMatch` implements Simple Matching Distance (most frequently
#' used for categorical, or symmetric binary data) for K-centroids
#' clustering.
#' 
#' `distGower` implements Gower's Distance after Gower (1971) and
#' Kaufman & Rousseeuw (1990) for mixed-type data with missings for K-centroids
#' clustering.
#' 
#' `distGDM2` implements GDM2 distance for ordinal data introduced by
#' Walesiak et al. (1993) and adapted to K-centroids clustering by
#' Ernst et al. (2025).
#' 
#' These functions are designed for use with [flexclust::kcca()] or
#' functions that are built upon it. Their use is easiest via the
#' wrapper [kccaExtendedFamily()].  However, they can also easily be
#' used to obtain a distance matrix of `x`, see Examples.
#' 
#' @details
#'
#' * `distSimMatch`: Simple Matching Distance between two observations
#'   is calculated as the proportion of disagreements acros all
#'   variables. Described, e.g., in Kaufman & Rousseeuw (1990), p. 24.
#'   If this is used in K-centroids analysis in combination with mode
#'   centroids (as implemented in `centMode`), this results in the
#'   **kModes** algorithm.  A wrapper for this algorithm is obtained
#'   with `kccaExtendedFamily(which='kModes')`.
#' 
#' * `distGower`: Distances are calculated for each column (Euclidean
#'   distance, `distEuclidean`, is recommended for numeric, Manhattan
#'   distance, `distManhattan` for ordinal, Simple Matching Distance,
#'   `distSimMatch` for categorical, and Jaccard distance,
#'   `distJaccard` for asymmetric binary variables), and they are
#'   summed up as:
#' 
#'   \deqn{d(x_i, x_k) = \frac{\sum_{j=1}^p \delta_{ikj} d(x_{ij},
#'   x_{kj})}{\sum_{j=1}^p \delta_{ikj}}}
#' 
#'   where \eqn{p} is the number of variables and with the weight
#'   \eqn{\delta_{ikj}} being 1 if both values \eqn{x_{ij}} and
#'   \eqn{x_{kj}} are not missing, and in the case of asymmetric
#'   binary variables, at least one of them is not 0.  Please note
#'   that for calculating Gower's distance, scaling of numeric/ordered
#'   variables is required (as f.i. by `.ScaleVarSpecific`).  A
#'   wrapper for K-centroids analysis using Gower's distance in
#'   combination with a numerically optimized centroid is found in
#'   `kccaExtendedFamily(which='kGower')`.
#'
#' * `distGDM2`: GDM2 distance for ordinal variables conducts only
#'    relational operations on the variables, such as \eqn{\leq},
#'    \eqn{\geq} and \eqn{=}. By translating \eqn{x} to its relative
#'    frequencies and empirical cumulative distributions, we are able
#'    to extend this principle to compare two arbitrary values, and
#'    thus use it within K-centroids clustering. For more details, see
#'    Ernst et al. (2025).  A wrapper for this algorithm in
#'    combination with a numerically optimized centroid is found in
#'    `kccaExtendedFamily(which='kGDM2')`.
#'    
#' The distances functions presented here can also be used in clustering algorithms that
#' rely on distance matrices (such as hierarchical clustering and PAM), if applied
#' accordingly, see Examples.
#'   
#'
#' @param x A numeric matrix or data frame.
#' @param centers A numeric matrix with `ncol(centers)` equal to
#'     `ncol(x)` and `nrow(centers)` smaller or equal to `row(x)`.
#' @param genDist Additional information on `x` required for distance
#'     calculation.  Filled automatically if used within
#'     [flexclust::kcca()].
#'
#' * For `distGower`: A character vector of variable specific
#'   distances to be used with length equal to `ncol(x)`. The
#'   following options are possible:
#' 
#'   - `distEuclidean`: Euclidean distance between the scaled variables.
#' 
#'   - `distManhattan`: absolute distance between the scaled variables.
#'
#'   - `distJaccard`: counts of zero if both binary variables are
#'      equal to 1, and 1 otherwise.
#' 
#'   - `distSimMatch`: Simple Matching Distance, i.e. the number of
#'      agreements between variables.
#' 
#' * For `distGDM2`: Function creating a distance function that will
#'   be primed on `x`.
#' 
#' * For `distSimMatch`: not used.
#' @param xrange Range specification for the variables. Currently only
#'     used for `distGDM2` (as `distGower` expects `x` to be already
#'     scaled). Possible values are:
#' 
#' - `NULL` (default): defaults to `"all"`.
#'
#' - `"all"`: uses the same minimum and maximum value for each column
#'     of `x` by determining the whole range of values in the data
#'     object `x`.
#' 
#' - `"columnwise"`: uses different minimum and maximum values for
#'     each column of `x` by determining the columnwise ranges of
#'     values in the data object `x`.
#'
#' - A vector of `c(min, max)`: specifies the same minimum and maximum
#'     value for each column of `x`.
#' 
#' - A list of vectors `list(c(min1, max1), c(min2, max2),...)` with
#'     length `ncol(x)`: specifies different minimum and maximum
#'     values for each column of `x`. 
#'
#' @return
#' A matrix of dimensions `c(nrow(x), nrow(centers))` that contains the distance
#' between each row of `x` and each row of `centers`.
#'
#' @examples
#' # Example 1: Simple Matching Distance
#' set.seed(123)
#' dat <- data.frame(question1 = factor(sample(LETTERS[1:4], 10, replace=TRUE)),
#'                   question2 = factor(sample(LETTERS[1:6], 10, replace=TRUE)),
#'                   question3 = factor(sample(LETTERS[1:4], 10, replace=TRUE)),
#'                   question4 = factor(sample(LETTERS[1:5], 10, replace=TRUE)),
#'                   state = factor(sample(state.name[1:10], 10, replace=TRUE)),
#'                   gender = factor(sample(c('M', 'F', 'N'), 10, replace=TRUE,
#'                                          prob=c(0.45, 0.45, 0.1))))
#' datmat <- data.matrix(dat)
#' initcenters <- datmat[sample(1:10, 3),]
#' distSimMatch(datmat, initcenters)
#' ## within kcca
#' flexclust::kcca(dat, k=3, family=kccaExtendedFamily('kModes'))
#' ## as a distance matrix
#' as.dist(distSimMatch(datmat, datmat))
#' 
#' # Example 2: GDM2 distance
#' flexclust::kcca(dat, k=3, family=kccaExtendedFamily('kGDM2'))
#' 
#' # Example 3: Gower's distance
#' # Ex. 3.1: single variable type case with no missings:
#' flexclust::kcca(datmat, 3, kccaExtendedFamily('kGower'))
#' 
#' # Ex. 3.2: single variable type case with missing values:
#' nas <- sample(c(TRUE, FALSE), prod(dim(dat)), replace = TRUE,
#'    prob=c(0.1, 0.9)) |> 
#'    matrix(nrow = nrow(dat))
#' dat[nas] <- NA
#' flexclust::kcca(dat, 3, kccaExtendedFamily('kGower', cent=centMode))
#' 
#' #Ex. 3.3: mixed variable types (with or without missings): 
#' dat <- data.frame(cont = sample(1:100, 10, replace=TRUE)/10,
#'                   bin_sym = as.logical(sample(0:1, 10, replace=TRUE)),
#'                   bin_asym = as.logical(sample(0:1, 10, replace=TRUE)),                     
#'                   ord_levmis = factor(sample(1:5, 10, replace=TRUE),
#'                                       levels=1:6, ordered=TRUE),
#'                   ord_levfull = factor(sample(1:4, 10, replace=TRUE),
#'                                        levels=1:4, ordered=TRUE),
#'                   nom = factor(sample(letters[1:4], 10, replace=TRUE),
#'                                levels=letters[1:4]))
#' dat[nas] <- NA
#' flexclust::kcca(dat, 3, kccaExtendedFamily('kGower'))
#' 
#' @seealso
#' [flexclust::kcca()],
#' [klaR::kmodes()],
#' [cluster::daisy()],
#' [clusterSim::dist.GDM()]
#'
#' @references
#' - Ernst, D, Ortega Menjivar, L, Scharl, T, Grün, B (2025).
#'   *Ordinal Clustering with the flex-Scheme.*
#'   Austrian Journal of Statistics. _Submitted manuscript_.
#' - Gower, JC (1971).
#'   *A General Coefficient for Similarity and Some of Its Properties.*
#'   Biometrics, 27(4), 857-871.
#'   \doi{10.2307/2528823}
#' - Kaufman, L, Rousseeuw, P (1990).
#'   *Finding Groups in Data: An Introduction to Cluster Analysis.*
#'   Wiley Series in Probability and Statistics.
#'   \doi{10.1002/9780470316801}
#' - Leisch, F (2006). *A Toolbox for K-Centroids Cluster Analysis.*
#'   Computational Statistics and Data Analysis, 17(3), 526-544.
#'   \doi{10.1016/j.csda.2005.10.006}
#' - Kaufman, L, Rousseeuw, P (1990.) *Finding Groups in Data: An Introduction to Cluster Analysis.*
#'   Wiley Series in Probability and Statistics, New York: John Wiley & Sons.
#'   \doi{10.1002/9780470316801}
#' - Walesiak, M (1993). *Statystyczna Analiza Wielowymiarowa w Badaniach Marketingowych.*
#'   Wydawnictwo Akademii Ekonomicznej, 44-46.
#' - Weihs, C, Ligges, U, Luebke, K, Raabe, N (2005). *klaR Analyzing German Business Cycles*.
#'   In Baier D, Decker, R, Schmidt-Thieme, L (eds.). Data Analysis and Decision Support,
#'   335-343. Berlin: Springer-Verlag.
#'   \doi{10.1007/3-540-28397-8_36}
#' @name distances
NULL

#' @rdname distances
#' @export
distSimMatch <- function (x, centers) {
  if (ncol(x) != ncol(centers))
    stop(sQuote('x'), ' and ', sQuote('centers'), ' must have the same number of columns')
  z <- matrix(0, nrow=nrow(x), ncol=nrow(centers))
  for (k in 1:nrow(centers)) {
    z[,k] <- colMeans(t(x) != centers[k,])
  }
  z
}

