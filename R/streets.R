# Readers for the street network history built in nyc_streets (outputs in nyc_traffic_data/derived/streets)
#
# source("../nyc_streets/R/streets.R")   # also sources nyc_traffic.R for nyc_data_root()
# k <- segment_key_map(c(32886, 9000277), date = "2014-06-01")

local({
  ofiles <- unlist(lapply(sys.frames(), function(f) if (is.character(f$ofile)) f$ofile))
  this <- tail(ofiles[grepl("streets\\.R$", ofiles)], 1)
  repo <- if (length(this)) dirname(dirname(this)) else "."
  if (!exists("nyc_data_root")) source(file.path(repo, "..", "nyc_traffic", "R", "nyc_traffic.R"), local = FALSE)
})

streets_dir <- function(...) file.path(nyc_data_root(), "derived", "streets", ...)

# Segment key (spine/03_segment_key.R): every LION SegmentID x geometry version since 12a with the
# SegmentIDs of the last release it continues as. share = share of the version's length that maps to
# key_id; key_status current (still in the last release), continued (replaced, split, merged or
# redrawn), retired (removed, key_id NA).
segment_key_read <- function() data.table::setDT(arrow::read_parquet(streets_dir("spine", "segment_key.parquet")))[]

# Map SegmentIDs to the key. date: the version in use on that date (the release in force then);
# without a date the latest version of each id.
segment_key_map <- function(segment_id, date = NULL, key = segment_key_read()) {
  ids <- data.table::data.table(segment_id = as.integer(segment_id))
  k <- key[ids, on = "segment_id", nomatch = 0]
  if (!is.null(date)) k <- k[first_date <= as.Date(date)]
  if (nrow(k)) k <- k[k[, .I[version == max(version)], by = segment_id][, V1]]   # ids in no release (before 12a) drop out
  k[, .(segment_id, version, key_id, share, key_status)][]
}

# Segment versions (spine/02_segment_versions.R) as sf in EPSG 2263; date: the network in use then
segment_versions_read <- function(date = NULL) {
  v <- sf::st_read(streets_dir("spine", "segment_versions.gpkg"), quiet = TRUE)
  if (is.null(date)) return(v)
  r <- lion_releases()
  rel <- r[["release"]][max(1, findInterval(as.numeric(as.Date(date)), as.numeric(r[["release_date"]])))]
  ri <- match(c(v$first_release, v$last_release, rel), r[["release"]])
  n <- nrow(v)
  v[ri[seq_len(n)] <= ri[2 * n + 1] & ri[n + seq_len(n)] >= ri[2 * n + 1], ]
}
