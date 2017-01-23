#------------------------------------------------------------------------------#
#--------------------------------- shiny apps ---------------------------------#
#------------------------- author: gyang274@gmail.com -------------------------#
#------------------------------------------------------------------------------#

#--------+---------+---------+---------+---------+---------+---------+---------#
#234567890123456789012345678901234567890123456789012345678901234567890123456789#

#------------------------------------------------------------------------------#
#----------------------------- shine color schema -----------------------------#
#------------------------------------------------------------------------------#

#------------------------- color schema on fedex zone -------------------------#

# fedex dist - zone mapping strategy: dist_cuts has length +1 of zone rgbc and dist
map_dist_zone_list <- list(
  zone = c(2L:8L), dist_cuts = c(-Inf, 150L, 300L, 600L, 1000L, 1400L, 1800L, Inf),
  rgbc = c("#ffb3b3", "#ffd699", "#ffff66", "#d9ff66", "#99ffff", "#99b3ff", "#ccccff"),
  dist = c("0 - 150 miles", "151 - 300 miles", "301 - 600 miles", "601 - 1000 miles",
           "1001 - 1400 miles", "1401 - 1800 miles", "1801+ miles")
)

# create_zone_from_dist
create_zone_from_dist <- function(x) {
  
  return( 
    as.numeric(as.character(
      cut(x, breaks = map_dist_zone_list[["dist_cuts"]], labels = map_dist_zone_list[["zone"]]) 
    ))
  )
  
}

map_zone_c <- purrr::partial(
  plyr::mapvalues, from = map_dist_zone_list[["zone"]], to = map_dist_zone_list[["rgbc"]], warn_missing = FALSE
)


#----------------------- color schema on time in transit ----------------------#

# estimated time in transit
map_stnt_list <- list(
  stnt = c(1L:6L),
  dist_cuts = c(-Inf, 300L, 500L, 800L, 1300L, 2100L, Inf),
  pp_adjust = c(-Inf, 10000L, 20000L, 30000L, 40000L, 50000L, Inf),
  rgbc = c("#ffb3b3", "#ffd699", "#ffff66", "#d9ff66", "#99ffff", "#99b3ff")
)

# create_stnt_from_dist and population
create_stnt_from_dist_pop <- function(x, y) {
  
  stnt_baseline <- as.numeric(as.character(
    cut(x, breaks = map_stnt_list[["dist_cuts"]], labels = map_stnt_list[["stnt"]]) 
  ))
  
  stnt_adjusted <- 1L + (-0.25) * as.numeric(as.character(
    cut(y, breaks = map_stnt_list[["pp_adjust"]], labels = map_stnt_list[["stnt"]]) 
  ))
  
  return ( round(pmin(pmax(0.5, (stnt_baseline + stnt_adjusted)), 6.0)) )
}

map_stnt_c <- purrr::partial(
  plyr::mapvalues, from = map_stnt_list[["stnt"]], to = map_stnt_list[["rgbc"]], warn_missing = FALSE
)

#------------------------------------------------------------------------------#
