#' HDX Resource
#'
#' HDX Resource
#'
#' @importFrom tools file_path_as_absolute
#' @format NULL
#' @usage NULL
#'
#' @examples
#' \dontrun{
#'   set_rhdx_config()
#'   resource <- pull_resource("98aa1742-b5d3-40c3-94c6-01e31ded6e84")
#'   resource
#' }
Resource <- R6::R6Class(
  classname = "Resource",

  private = list(
    configuration = NULL,
    download_folder_ = NULL
  ),

  public = list(
    data = NULL,

    initialize = function(initial_data = NULL, configuration = NULL) {
      if (is.null(configuration) | !inherits(configuration, "Configuration")) {
        private$configuration <- get_rhdx_config()
      } else {
        private$configuration <- configuration
      }
      if (is.null(initial_data))
        initial_data <- list()

      class <- vapply(initial_data, class, character(1))
      form_file_index <- class == "form_file"

      if (any(form_file_index)) {
        initial_data <- c(drop_nulls(initial_data[!form_file_index]), initial_data[form_file_index])
      } else {
        initial_data <- drop_nulls(initial_data)
      }
      self$data <- initial_data
    },

    download = function(folder = NULL, filename = NULL,
                        quiet = TRUE, force = FALSE, ...) {


      if (is.null(folder)) {
        folder <- rhdx_cache_dir()
      }

      if (!dir.exists(folder))
        dir.create(folder)

      if (is.null(filename)) {
        filename <- basename(file.path(self$data$url)) ## self$data$url
        if (!is.null(self$data$resource_type) && self$data$resource_type == "api")
          filename <- gsub("\\?.*", "", filename)
      }

      file_path <- file.path(folder, filename)

      if (!file.exists(file_path) | force)
        download.file(url = self$data$url,
                      destfile = file_path,
                      mode = "wb",
                      quiet = quiet, ...)

      private$download_folder_ <- tools::file_path_as_absolute(folder)
      invisible(tools::file_path_as_absolute(file_path))
    },

    download_folder = function() {
      tools::file_path_as_absolute(private$download_folder_)
    },

    read_resource = function(sheet = NULL, layer = NULL, folder = NULL, simplify_json = TRUE, force_download = FALSE, quiet = TRUE, ...) {

      if (!is.null(private$download_folder_) & is.null(folder))
        folder <- self$download_folder()

      file_path <- self$download(folder = folder, quiet = quiet, force = force_download, ...)

      format <- self$get_file_type()

      hxl <- any(grepl("hxl", get_tags_name(self$get_dataset()), ignore.case = TRUE))

      switch(format,
             csv = read_hdx_csv(file_path, hxl = hxl),
             `zipped csv` = read_hdx_csv(file_path, hxl = hxl),
             excel = read_hdx_excel(file_path, sheet = sheet, hxl = hxl),
             xlsx = read_hdx_excel(file_path, sheet = sheet, hxl = hxl),
             xls = read_hdx_excel(file_path, sheet = sheet, hxl = hxl),
             json = read_hdx_json(file_path, simplify_json = simplify_json),
             geojson = read_hdx_vector(file_path, layer),
             geotiff = read_hdx_raster(file_path, zipped = FALSE),
             kmz = read_hdx_vector(file_path, layer = layer),
             `zipped shapefile` = read_hdx_vector(file_path, layer = layer),
             `zipped geodatabase` = read_hdx_vector(file_path, layer = layer, zipped = FALSE),
             `zipped kml` = read_hdx_vector(file_path, layer = layer),
             `zipped geopackage` = read_hdx_vector(file_path, layer = layer),
             `zipped geotiff` = read_hdx_raster(file_path))
    },

    get_layers = function(folder = NULL, quiet = TRUE, force_download = FALSE, ...) {

      if (!is.null(private$download_folder_) & is.null(folder))
        folder <- self$download_folder()

      file_path <- self$download(folder = folder, quiet = quiet, force = force_download, ...)

      format <- self$get_file_type()

      supported_geo_format <- c("geojson", "zipped shapefile", "zipped geodatabase",
                                "zipped geopackage", "kmz", "zipped kml")
      if (!format %in% supported_geo_format)
        stop("This (spatial) data format is not yet supported", call. = FALSE)

      switch(format,
             geojson = get_hdx_layers_(file_path, zipped = FALSE),
             `zipped shapefile` = get_hdx_layers_(file_path),
             `zipped geodatabase` = get_hdx_layers_(file_path, zipped = FALSE),
             `zipped geopackage` = get_hdx_layers_(file_path),
             kmz = get_hdx_layers_(file_path),
             `zipped kml` = get_hdx_layers_(file_path))
    },

    get_sheets = function(folder = NULL, quiet = TRUE, force_download = FALSE, ...) {

      if (!is.null(private$download_folder_) & is.null(folder))
        folder <- self$download_folder()

      file_path <- self$download(folder = folder, quiet = quiet, force = force_download, ...)

      format <- self$get_file_type()

      if (!format %in% c("xlsx", "xls", "excel"))
        stop("`get_sheets work only with Excel file", call. = FALSE)

      switch(format,
             excel = get_hdx_sheets_(file_path),
             xlsx = get_hdx_sheets_(file_path),
             xls = get_hdx_sheets_(file_path))
    },

    get_dataset = function() {
      package_id <- self$data$package_id
      if (is.null(package_id)) {
        stop("Resource has no package id!", call. = FALSE)
      } else {
        pull_dataset(package_id)
      }
    },

    get_file_to_upload = function() {
      self$data$file_to_upload
    },

    get_required_fields = function() {
      private$configuration$data$hdx_config$resource$required_fields
    },

    check_required_field = function(check_dataset_id = FALSE) {
      n2 <- names(self$data)
      n1 <- self$get_required_fields()
      if (check_dataset_id)
        # remove package_id
        n1 <- setdiff(n1, "package_id")
      if (!all(n1 %in% n2))
        stop(sprintf("Field %s is missing in the dataset!\n",
                     setdiff(n1, n2)), call. = FALSE)
    },

    get_file_type = function() {
      tolower(self$data$format)
    },

    get_format = function() {
      tolower(self$data$format)
    },

    as_list = function() {
      self$data
    },

    browse = function() {
      url <- private$configuration$get_hdx_site_url()
      dataset_id <- self$data$package_id
      resource_id <- self$data$id
      browseURL(url = paste0(url, "dataset/", dataset_id, "/resource/", resource_id))
    },

    print = function() {
      cat(paste0("<HDX Resource> ", self$data$id), "\n")
      cat("  Name: ", self$data$name, "\n", sep = "")
      cat("  Description: ", self$data$description, "\n", sep = "")
      cat("  Size: ", self$data$size, "\n", sep = "")
      cat("  Format: ", self$data$format, "\n", sep = "")
      invisible(self)
    }
  )
)

#' @export
#' @aliases Resource
#' @importFrom tibble as_tibble
as_tibble.Resource <- function(x, ...) {
  df <- tibble::tibble(
    resource_id = x$data$id,
    resource_name = x$data$name,
    resource_format = tolower(x$data$format),
    resource_url = x$data$url)
  df$resource <- list(x)
  df
}

#' @export
#' @aliases Resource
as.list.Resource <- function(x, ...) {
  x$as_list()
}

#' Download an HDX resource
#'
#' Download an HDX resource into a specific folder
#'
#' @param resource Resource, an HDX resource
#' @param folder Character, path of the directory where you will store the data
#' @param filename Character, name of the file you will download
#' @param quiet Logical, no progress bar from download (default = FALSE)
#' @param force Logical, force download (default = FALSE)
#' @param ... extra paramaters
#'
#' @return Resource
#' @export
#'
#' @examples
#' \dontrun{
#' #Setting the config to use HDX default server
#'  set_rhdx_config()
#'  res <- read_resource("98aa1742-b5d3-40c3-94c6-01e31ded6e84")
#'  download_resource(res, folder = "/tmp")
#' }
download_resource <- function(resource, folder = NULL, filename = NULL, quiet = FALSE, force = FALSE, ...) {
  assert_resource(resource)
  resource$download(folder = folder, filename = filename, quiet = quiet, force = force, ...)
}

#' List layers available in spatial resources on HDX
#'
#' List layers available in spatial resources on HDX
#' @param resource Resource, an HDX resource
#' @param folder Character, path of the directory where you will store the data
#' @param quiet Logical, no progress bar from download (default = FALSE)
#'
#' @return the layers name
#' @export
get_layers <- function(resource, folder = NULL, quiet = TRUE) {
  assert_resource(resource)
  resource$get_layers(folder = folder, quiet = quiet)
}


#' Get the names of the sheets of XLS(X) resources
#'
#'  Get the names of the sheets of XLS(X) resources
#' @param resource Resource, an HDX resource
#' @param folder Character, path of the directory where you will store the data
#' @param quiet Logical, no progress bar from download (default = FALSE)
#' @param ... extra parameters
#'
#' @return the names of the sheets of XLS(X) resources
#' @export
get_sheets <- function(resource, folder = NULL, quiet = TRUE, ...) {
  assert_resource(resource)
  resource$get_sheets(folder = folder, quiet = quiet, ...)
}

#' Get the file format of the resource
#'
#' Get the file format of the resource
#' @param resource Resource, an HDX resource
#'
#' @return A character, the format of the resource
#' @export
get_format <- function(resource) {
  assert_resource(resource)
  resource$get_format()
}


#' Read resource
#'
#' Read resource
#' @param resource Resource, an HDX resource
#'
#' @param sheet Character, the name of the sheet to read if XLS(X) resources. The first sheet is read by default.
#' @param layer Character, the name of the layer to read if spatial data. The first sheet is read by default.
#' @param folder Character, the path of the folder to store the downloaded data
#' @param simplify_json Logical, if TRUE simplifies nested lists into vectors and data frames for JSON resources
#' @param force_download Logical, force download if TRUE
#' @param ... Extra parameters
#' @return an `tbl`, a `list` or a `sf` object depending on the type of resource you are reading
#' @export
read_resource <- function(resource, sheet = NULL, layer = NULL, folder = NULL, simplify_json = TRUE, force_download = FALSE, ...) {
  assert_resource(resource)
  resource$read_resource(sheet = sheet,
                         layer = layer,
                         folder = folder,
                         simplify_json = simplify_json,
                         force_download = force_download,
                         ...)
}

#' Search resources
#'
#' Search Resources
#'
#' @rdname search_resources
#' @param query Character, a query
#' @param configuration an HDX configuration object
#' @param ... extra params
.search_resources  <-  function(query = "*:*", configuration = NULL, ...) {
  if (!is.null(configuration) & inherits(configuration, "Configuration"))
    set_rhdx_config(configuration = configuration)
  configuration <- get_rhdx_config()
  res <- configuration$call_action("resource_search", list(query = query, ...))
  list_of_rs <- lapply(res$results, function(x) Resource$new(initial_data = x, configuration = configuration))
  class(list_of_rs) <- "resources_list"
  list_of_rs
}

#' @rdname search_resources
#' @export
search_resources <- memoise::memoise(.search_resources)

#' @export
#' @aliases Resource
as_tibble.resources_list <- function(x, ...) {
  l <- lapply(x, as_tibble)
  Reduce(rbind, l)
}


#' @noRd
.pull_resource <- function(identifier, configuration = NULL) {
  if (!is.null(configuration) & inherits(configuration, "Configuration"))
    set_rhdx_config(configuration = configuration)
  configuration <- get_rhdx_config()
  res <- configuration$call_action("resource_show", list(id = identifier))
  Resource$new(initial_data = res, configuration = configuration)
}

#' Read an HDX resource
#'
#' Read an HDX resource
#'
#' @param identifier character resource uuid
#' @param configuration an HDX configuration object
#' @param ... Extra parameters
#'
#' @rdname pull_resource
#'
#' @return Resource
#' @export
#'
#' @examples
#' \dontrun{
#' #Setting the config to use HDX default server
#'  set_rhdx_config()
#'  res <- read_resource("98aa1742-b5d3-40c3-94c6-01e31ded6e84")
#'  res
#' }
pull_resource <- memoise::memoise(.pull_resource)

#' @rdname browse
#' @export
browse.Resource <- function(x, ...)
  x$browse()
