% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/configuration.R
\docType{data}
\name{Configuration}
\alias{Configuration}
\title{HDX Configuration}
\description{
HDX Configuration allow to connect to an HDX server and setup project where you can interact with the HDX platform
}
\details{
\strong{Methods}
\describe{
\item{\code{create(hdx_site, hdx_key, read_only, hdx_key_file, hdx_config, hdx_config_yaml, hdx_config_json, project_config, project_config_yaml, project_config_json, configuration)}}{
Create a HDX Configuration
}
\item{\code{get_credentials()}}{
Setup a HDX Configuration object
}
\item{\code{set_read_only(read_only)}}{
Read a Configuration object
}\preformatted{\item{`set_hdx_key(hdx_key)`}{
  Provides an API key
}

\item{`load_hdx_key(path)`}{
  Provides an API key from path
}

\item{`get_hdx_key()`}{
  Get the HDX server site in use.
}

\item{`set_hdx_key(hdx_site)`}{
  Set the HDX server site to use.
}
}

\item{\code{get_hdx_key()}}{
Get the API key
}

\item{\code{get_hdx_key_url()}}{
Get the HDX server URL
}

\item{\code{remoteclient()}}{
Remote API client
}

\item{\code{call_remoteclient()}}{
Call remote API client
}

\item{\code{setup()}}{
Setup configuration i.e HDX server, API and read only status.
}

\item{\code{delete()}}{
Delete actual configuration.
}

\item{\code{general_statistics()}}{
Some statistics about HDX
}

}
}
\examples{
\dontrun{
set_rhdx_config(hdx_site = "prod")
get_rhd_config()
}
}
\keyword{datasets}
