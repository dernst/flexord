% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/flxregmultinom.R
\name{FLXMCregmultinom}
\alias{FLXMCregmultinom}
\title{FlexMix Driver for Regularized Multinomial Mixtures}
\usage{
FLXMCregmultinom(formula = . ~ ., size, alpha2 = 0)
}
\arguments{
\item{formula}{A formula which is interpreted relative to the formula
specified in the call to \code{\link[flexmix:flexmix]{flexmix::flexmix()}} using
\code{\link[stats:update.formula]{stats::update.formula()}}. Only the
left-hand side (response) of the formula is used. Default is to
use the original model formula specified in \code{\link[flexmix:flexmix]{flexmix::flexmix()}}.}

\item{size}{Values are assumed to be integers in \code{1:size}.}

\item{alpha2}{A non-negative scalar acting as regularization
parameter. Can be regarded as adding \code{alpha2} observations
equal to the population mean to each component.}
}
\value{
an object of class \code{"FLXC"}
}
\description{
This model driver can be used to cluster data using a multinomial
distribution.
}
\details{
Using a regularization parameter \code{alpha2} greater than zero
acts as adding \code{alpha2} observations conforming to the population
mean to each component. This can be used to avoid degenerate
solutions. It also has the effect
that clusters become more similar to each other the larger
\code{alpha2} is chosen. For small values it is mostly negligible however.

For regularization we compute the MAP estimates for the multinomial
distribution using the Dirichlet distribution as prior, which is
the conjugate prior. The parameters of this prior are selected to
correspond to the marginal distribution of the variable across all
observations.
}
\examples{
library("flexmix")
library("flexord")
library("flexclust")

# Sample data
k <- 4     # nr of clusters
size <- 4  # nr of trials
N <- 100   # obs. per cluster

set.seed(0xdeaf)

# random probabilities per component
probs <- lapply(seq_len(k), \(ki) runif(10, 0.01, 0.99))

# sample data
dat <- lapply(probs, \(p) {
    lapply(p, \(p_i) {
        rbinom(N, size, p_i)
    }) |> do.call(cbind, args=_)
}) |> do.call(rbind, args=_)

true_clusters <- rep(1:4, rep(N, k))

# Sample data is drawn from a binomial distribution but we fit
# a multinomial meaning the model is mis-specified.
# Note that for the multinomial distribution we expect values to lie inside
# 1:(size+1) hence we add +1.

# Cluster without regularization
m1 <- stepFlexmix((dat+1L)~1, model=FLXMCregmultinom(size=size+1L, alpha2=0), k=k)

# Cluster with regularization
m2 <- stepFlexmix((dat+1L)~1, model=FLXMCregmultinom(size=size+1L, alpha2=1), k=k)

# Both models are mostly able to reconstruct the true clusters (ARI ~ 0.95)
# (it's a very easy clustering problem)
# Small values for the regularization don't seem to affect the ARI (much)
randIndex(clusters(m1), true_clusters)
randIndex(clusters(m2), true_clusters)
}
\references{
\itemize{
\item Galindo Garre, F, Vermunt, JK (2006).
\emph{Avoiding Boundary Estimates in Latent Class Analysis by Bayesian Posterior Mode Estimation}
Behaviormetrika, 33, 43-59.
\item Ernst, D, Ortega Menjivar, L, Scharl, T, Grün, B (2025).
\emph{Ordinal Clustering with the flex-Scheme.}
Austrian Journal of Statistics. \emph{Submitted manuscript}.
}
}
