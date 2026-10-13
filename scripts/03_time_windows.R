# Segment x time-window bike lane facilities for Manhattan (moved here from
# 5_NYC_bikelanes/scripts/data_management/002_import_bikelanes.R on 2026-10-13)
#
# Inputs: DOT 2020 bike routes shapefile and the 2025 snapshot (nyc_traffic_data/streets/bike_routes),
#         manual/streetview_dot2020.csv (manual Street View checks), manual/lookup_bikelane_types.xlsx,
#         manual/protection_overrides.csv (manual/04_build_overrides.R), manual/segmentid_crosswalk_lion16d.csv
# Output: nyc_traffic_data/derived/bikelane_history/bike_lanes_time_windows.RDS, one row per
#         SegmentID x time_window with date_from, date_to and tf_/ft_facilit (Protected / Standard /
#         Sharrows), read with bikelane_windows_read(); bike_lane_updates.gpkg (2025 updates) next to it.
#         Includes copies for 18 LION 16d segments (manual/segmentid_crosswalk_lion16d.csv)
# Run from repo root: Rscript scripts/03_time_windows.R

library(data.table)
library(dplyr)
library(sf)

source("../nyc_traffic/R/nyc_traffic.R")
out_dir <- file.path(nyc_data_root(), "derived/bikelane_history")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# DOT bike routes snapshot for the 2025 updates (YYYYMMDD)
snap_bike_routes <- '20251008'

path_dot_bikelanes <- file.path(nyc_data_root(), "streets/bike_routes/Archived_nyc_bike_routes_2020/nyc_bike_routes_2020.shp")

# load -------------
dot.sf = read_sf(path_dot_bikelanes)

dot.sf = st_transform(dot.sf, "+init=EPSG:4326")


dot_geom.v = st_as_text(st_geometry(dot.sf))


dot.dt <- data.table(dot.sf)

# trick to keep the geometry and run a unique on the data.table
dot.dt = dot.dt[, geometry := dot_geom.v]


# cleaning and categorization of facilities ---------------------------------------------------------------------------------

# dot.dt[, lion16d_id := as.numeric(segmentid)]

nrow(dot.dt) - nrow(unique(dot.dt))
# 3 duplicates -> remove for now

dot.dt = unique(dot.dt)


# clean dates -------------
dot.dt[, instdate := gsub("T", " ", instdate)]
dot.dt[, moddate := gsub("T", " ", moddate)]

dot.dt[, install_date := as.POSIXct(substr(instdate, 1, 19), 
                                    format = "%Y-%m-%d", 
                                    tz = "America/New_York")]

dot.dt[, modif_date := as.POSIXct(substr(moddate, 1, 19), 
                                  format = "%Y-%m-%d", 
                                  tz ="America/New_York")]

dot.dt[, `:=`(instdate = NULL, moddate=NULL)]

# reminder: if never modified, modif date == install date
nrow(dot.dt[install_date == modif_date]) # majority of cases


# some modified dates are before the install date -> might be because of unknown install/modification date
# for now, we will consider those as never modified (not a huge issue if only looking at yearly)
dot.dt[install_date > modif_date, modif_date := install_date]

# clean categories -------------
unique(dot.dt[, facilitycl])
dot.dt[facilitycl == "i", facilitycl := "I"]
dot.dt[, .N, by = facilitycl]

unique(dot.dt[, tf_facilit])
unique(dot.dt[, ft_facilit])

# all combinations of Class and facilities
class_facilities = dot.dt[, .N, by = .(facilitycl, tf_facilit, ft_facilit)][order(facilitycl, -N)]
class_facilities

class_facilities_man = dot.dt[boro == 1, .N, by = .(facilitycl, tf_facilit, ft_facilit)][order(facilitycl, -N)]
# some inconsistencies to correct or drop
# I                 Standard              Standard   65
# II                Greenway              Greenway    9
# II          Protected Path                  <NA>    6
# II                    <NA>        Protected Path    3
# II          Protected Path        Protected Path    2
# III               Standard                  <NA>   15
# III               Curbside                  <NA>    5
# III                   <NA>              Standard    2
# drop for now until we know which variable to trust (107 obs)

precleancat = nrow(dot.dt)

dot.dt = dot.dt[!((facilitycl == "I" & tf_facilit == "Standard" & ft_facilit == "Standard") |
                    (facilitycl == "II" & tf_facilit == "Greenway" & ft_facilit == "Greenway") |
                    (facilitycl == "II" & tf_facilit == "Protected Path" & is.na(ft_facilit)) |
                    (facilitycl == "II" & is.na(tf_facilit) & ft_facilit == "Protected Path") |
                    (facilitycl == "II" & tf_facilit == "Protected Path" & ft_facilit == "Protected Path") |
                    (facilitycl == "III" & tf_facilit == "Standard" & is.na(ft_facilit)) |
                    (facilitycl == "III" & tf_facilit == "Curbside" & is.na(ft_facilit)) |
                    (facilitycl == "III" & is.na(tf_facilit) & ft_facilit == "Standard"))]

precleancat - nrow(dot.dt) # close enough
rm(precleancat)


# add manual table -----

# manual Street View checks: versioned export of the Google Sheet "Manual Streetview NYC Bikelanes"
# (tab 'dot 2020'); re-export with scripts/01_export_manual_sheet.R
dot_man <- fread('manual/streetview_dot2020.csv', colClasses = 'character')

dot_man[, install_date := as.POSIXct(install_date, format = "%Y-%m-%d", tz = "America/New_York")]
dot_man[, modif_date := as.POSIXct(na_if(modif_date, ""), format = "%Y-%m-%d", tz = "America/New_York")]

dot_man <- dot_man[, .(geometry, 
                       install_date, 
                       modif_date, 
                       modified, 
                       ft_facilit,
                       tf_facilit,
                       tf_bef_mod, 
                       ft_bef_mod,
                       from_manual_table = 1)]

# drop redundant cols
dot.dt[, c('facilitycl', 'allclasses') := NULL]

# append background info cols to manual table
cols <- c('geometry', names(dot.dt)[!names(dot.dt) %in% names(dot_man)])

dot_man <- merge(dot_man, dot.dt[, ..cols], by = 'geometry')


dot_final <- rbind(dot.dt, dot_man, fill = T)

dot_final[, dupl := .N, by = geometry]

dot_final <- dot_final[dupl == 1 | from_manual_table == 1]


# add updates from 2025 data ----

# keep only updates after latest modification in previous data
max_date_prev <- dot_final[, max(modif_date, na.rm = T)]


dot_25 <- st_read(dsn = nyc_latest('bike_routes', as_of = snap_bike_routes)) %>%
  filter(boro == 1) %>% 
  mutate(segmentid = as.numeric(segmentid)) %>% 
  filter(instdate > max_date_prev)

dot_updates <- dot_25 %>% 
  left_join(dot_final %>% transmute(segmentid, in_prev_streets_data = TRUE), by = 'segmentid') %>% 
  mutate(bike_lane_found = paste(facilitycl, in_prev_streets_data))


st_write(dot_updates, file.path(out_dir, 'bike_lane_updates.gpkg'), delete_layer = T, quiet = T)


# bind updates to previous ----


# rename updates
dot_updates <- dot_updates %>% 
  rename(install_date = instdate) %>% 
  mutate(modif_date = install_date) # this is to ensure that protected is not overwritten


# check non overlapping names
names_up <- names(dot_updates)
names_prev <- names(dot_final)


dot_updates <- dot_updates[, intersect(names_up, names_prev)]

# remove updates from previous
segments_update <- dot_updates %>% pull(segmentid)

dot_final <- dot_final %>% 
  filter(!segmentid %in% segments_update)

dot_updates <- dot_updates %>% 
  st_drop_geometry() %>% 
  as_tibble() %>% 
  mutate(boro = as.numeric(boro),
         lanecount = as.numeric(lanecount))

dot_final <- dot_final %>% 
  bind_rows(dot_updates %>% st_drop_geometry())



# putt all timewindows in I, II, III, coding ----
bl_types <- readxl::read_excel('manual/lookup_bikelane_types.xlsx')

bl_types <- setNames( bl_types %>% pull(facility_code),
                      bl_types %>% pull(facility_text))

# facility text or class code (the manual table codes pre-modification types as I/II/III) to class code
to_class <- function(x) unname(fifelse(x %in% c('I', 'II', 'III'), x, bl_types[x]))

# pre-modification type: from the manual table; if blank, the type did not change
# (manual sheet rules: "those without pre-mod keep the same class")
before_mod <- function(bef, after) fifelse(is.na(bef) | bef == '', to_class(after), to_class(bef))


dot_out <- dot_final[, .(
  segmentid,
  street,
  boro,
  fromstreet,
  tostreet,
  bikedir,
  lanecount,
  ft_after_mod = to_class(ft_facilit),
  tf_after_mod = to_class(tf_facilit),
  ft_before_mod = before_mod(ft_bef_mod, ft_facilit),
  tf_before_mod = before_mod(tf_bef_mod, tf_facilit),
  install_date,
  modif_date,
  geometry
)]




# add start_date to cases without bike infra
start_date <- as.POSIXct('1899-01-01', tz = "America/New_York")
end_date <- as.POSIXct('2099-09-09', tz = "America/New_York")


dot_out[is.na(install_date), install_date := start_date]


# expand the cases that are upgraded twice (so 3 time windows in total)
dot_out[ , infra_upgrades := 1] # for normal cases

dot_out[install_date < modif_date, infra_upgrades := 2]

# expand 
dot_out <- dot_out[, .(time_window = 1:(infra_upgrades+1)), by = c(names(dot_out))]


# set the time_window before installation
dot_out[time_window > 1, ft_facilit := ft_after_mod]
dot_out[time_window == 2 & infra_upgrades == 2, ft_facilit := ft_before_mod]

dot_out[time_window > 1, tf_facilit := tf_after_mod]
dot_out[time_window == 2 & infra_upgrades == 2, tf_facilit := tf_before_mod]

dot_out[time_window == 1, date_from := start_date]
dot_out[time_window == 2, date_from := install_date]
dot_out[time_window == 3, date_from := modif_date]

dot_out[time_window == 1, date_to := install_date]
dot_out[time_window == 2 & infra_upgrades == 1, date_to := end_date]
dot_out[time_window == 2 & infra_upgrades == 2, date_to := modif_date]
dot_out[time_window == 3, date_to := end_date]


# select
dot_export <- dot_out[, .(
  SegmentID = segmentid,
  time_window,
  date_from,
  date_to,
  tf_facilit,
  ft_facilit
)]

# refactor types
lane_types = c('I' = 'Protected',
               'II' = 'Standard',
               'III' = 'Sharrows')



dot_export[, tf_facilit := lane_types[tf_facilit]]
dot_export[, ft_facilit := lane_types[ft_facilit]]


# validated protection dates (Street View review, park-drive car-free dates) ----
# segment-level overrides built in manual/04_build_overrides.R;
# the directions that carry the lane are taken from the DOT windows (both if none)
ov <- fread('manual/protection_overrides.csv', colClasses = c(SegmentID = 'numeric'))
ov <- ov[SegmentID %in% dot_export$SegmentID | protected_from != 'never']

dirs <- dot_export[SegmentID %in% ov$SegmentID,
                   .(tf = any(!is.na(tf_facilit)), ft = any(!is.na(ft_facilit))), by = SegmentID]
ov <- merge(ov, dirs, by = 'SegmentID', all.x = TRUE)
ov[is.na(tf) | (!tf & !ft), `:=`(tf = TRUE, ft = TRUE)]

windows_for <- function(o) {
  if (o$protected_from == 'never') {
    w <- dot_export[SegmentID == o$SegmentID]
    w[tf_facilit == 'Protected', tf_facilit := 'Standard']
    w[ft_facilit == 'Protected', ft_facilit := 'Standard']
    return(w)
  }
  fac <- function(x, on) if (on) x else NA_character_
  if (o$protected_from == 'always') {
    return(data.table(SegmentID = o$SegmentID, time_window = 1L, date_from = start_date, date_to = end_date,
                      tf_facilit = fac('Protected', o$tf), ft_facilit = fac('Protected', o$ft)))
  }
  d <- as.POSIXct(o$protected_from, tz = 'America/New_York')
  before <- if (o$before_class == 'none') NA_character_ else o$before_class
  data.table(SegmentID = o$SegmentID, time_window = 1:2, date_from = c(start_date, d), date_to = c(d, end_date),
             tf_facilit = c(fac(before, o$tf), fac('Protected', o$tf)),
             ft_facilit = c(fac(before, o$ft), fac('Protected', o$ft)))
}
dot_ov <- rbindlist(lapply(split(ov, by = 'SegmentID'), windows_for))
dot_export <- rbind(dot_export[!SegmentID %in% ov$SegmentID], dot_ov)
cat('overrides applied to', uniqueN(dot_ov$SegmentID), 'segments\n')


# copies for LION 16d segments missing from the DOT data ----
# hand-made in 5_NYC_bikelanes 101_merge_streets_data.R (moved here 2026-10-13): the windows of a DOT
# segment are copied to the LION 16d SegmentID of the same street piece (the paper's street network).
# Note: 37669, 37630 and 37533 receive several sources and 36563 has windows of its own, so these get
# overlapping windows.
xw <- fread('manual/segmentid_crosswalk_lion16d.csv')
dot_xw <- dot_export[SegmentID %in% xw[, dot_segmentid]]
dot_xw[, SegmentID := xw[match(dot_xw[, SegmentID], xw[, dot_segmentid]), lion16d_segmentid]]
dot_export <- rbind(dot_export, dot_xw)

saveRDS(dot_export, file.path(out_dir, 'bike_lanes_time_windows.RDS'))
