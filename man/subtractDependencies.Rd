% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tags.R
\name{subtractDependencies}
\alias{subtractDependencies}
\title{Subtract dependencies}
\usage{
subtractDependencies(dependencies, remove, warnOnConflict = TRUE)
}
\arguments{
\item{dependencies}{A list of \code{\link[=htmlDependency]{htmlDependency()}} objects from which
dependencies should be removed.}

\item{remove}{A list of \code{\link[=htmlDependency]{htmlDependency()}} objects indicating which
dependencies should be removed, or a character vector indicating dependency
names.}

\item{warnOnConflict}{If \code{TRUE}, a warning is emitted for each
dependency that is removed if the corresponding dependency in \code{remove}
has a lower version number. Has no effect if \code{remove} is provided as a
character vector.}
}
\value{
A list of \code{\link[=htmlDependency]{htmlDependency()}} objects that don't intersect
with \code{remove}.
}
\description{
Remove a set of dependencies from another list of dependencies. The set of
dependencies to remove can be expressed as either a character vector or a
list; if the latter, a warning can be emitted if the version of the
dependency being removed is later than the version of the dependency object
that is causing the removal.
}
