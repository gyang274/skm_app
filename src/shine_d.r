#------------------------------------------------------------------------------#
#--------------------------------- shiny apps ---------------------------------#
#------------------------- author: gyang274@gmail.com -------------------------#
#------------------------------------------------------------------------------#

#--------+---------+---------+---------+---------+---------+---------+---------#
#234567890123456789012345678901234567890123456789012345678901234567890123456789#

#------------------------------------------------------------------------------#
#------------------------------------ data ------------------------------------#
#------------------------------------------------------------------------------#

#----------------------- objective and weighting schema -----------------------#

dobj <- data.table(
  nam = c("distance", "fedex zone", "estimated time in transit"),
  val = c("dist", "zone", "stnt"))

map_obj_v <- purrr::partial(
  plyr::mapvalues, from = dobj[["nam"]], to = dobj[["val"]], warn_missing = FALSE)

map_obj_n <- purrr::partial(
  plyr::mapvalues, from = dobj[["val"]], to = dobj[["nam"]], warn_missing = FALSE)
  

dwgt <- data.table(nam = c("population", "income"), 
                   val = c("pop", "ink"))

map_wgt_v <- purrr::partial(
  plyr::mapvalues, from = dwgt[["nam"]], to = dwgt[["val"]], warn_missing = FALSE)

map_wgt_n <- purrr::partial(
  plyr::mapvalues, from = dwgt[["val"]], to = dwgt[["nam"]], warn_missing = FALSE)

#------------------------------------------------------------------------------#

#------------------------------------------------------------------------------#
#------------------------------------ load ------------------------------------#
#------------------------------------------------------------------------------#

dsrc <- readRDS("dat/dsrc.RDS")

map_dsrc_s <- purrr::partial(
  plyr::mapvalues, from = dsrc[["id"]], to = dsrc[["s"]], warn_missing = FALSE)

ddst <- readRDS("dat/ddst.RDS")

for ( o in c("dist", "zone", "stnt") ) {
  
  eval(parse(text = 'dmtx' %+% '_' %+% o %+% ' <- readRDS("dat/dmtx' %+% '_' %+% o %+% '.RDS")'))
  
  for ( w in c("pop", "ink") ) {
    
    eval(parse(text = 'dmtx' %+% '_' %+% o %+% '_' %+% w %+% ' <- readRDS("dat/dmtx' %+% '_' %+% o %+% '_' %+% w %+% '.RDS")'))
    
  }
}

# show a subset of t on map-view
set.seed(285714)

subset_t_name <- ddst %>% select(t) %>% 
  mutate(g = substr(t, 1, 3)) %>% group_by(g) %>% 
  sample_n(4, replace = TRUE) %>% unique %>% `[[`("t")

subset_t_indx <- match(subset_t_name, ddst[["t"]])

for ( o in c("dist", "zone", "stnt") ) {
  
  eval(parse(text = 'dmtx_map_' %+% o %+% ' <- dmtx_' %+% o %+% '[ , subset_t_indx]'))
  
}

# customerized icons in map-view
# metroIcons <- leaflet::icons(
#   iconUrl = "fig/metro.png",
#   iconWidth = 32, iconHeight = 32,
#   iconAnchorX = 32, iconAnchorY = 32
# )

#------------------------------------------------------------------------------#

#------------------------------------------------------------------------------#
#----------------------------- Data Explorer View -----------------------------#
#------------------------------------------------------------------------------#

dstt <- unique(ddst[["state"]])

dcit <- ddst %>% select(city, state) %>% unique
#------------------------------------------------------------------------------#