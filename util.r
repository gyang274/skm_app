#------------------------------------------------------------------------------#
#--------------------------------- skm::app.r ---------------------------------#
#------------------------- author: gyang274@gmail.com -------------------------#
#------------------------------------------------------------------------------#

#--------+---------+---------+---------+---------+---------+---------+---------#
#234567890123456789012345678901234567890123456789012345678901234567890123456789#

#------------------------------------------------------------------------------#
#------------------------------------ misc ------------------------------------#
#------------------------------------------------------------------------------#

#------------------------------------ data ------------------------------------#

#' load_zip_dat: load mat/dzip2012.csv file
#' @return dzip: zip<5 digits> lat<latitude> lng<longitude>
load_zip_dat <- function(dat_file = "mat/dzip2012.csv", waitime = 0) {

  a_colname <- c("zip", "zipCodeType", "city", "state", "locationType", "lat", "lng",
                 "location", "decommisioned", "taxReturnsFiled", "population", "ink")

  a_coltype <- c(rep("character", 5), rep("numeric", 2), rep("character", 2), rep("numeric", 3))

  sc_colname <- c("zip", "lat", "lng", "population", "ink", "city", "state")

  if ( require(yg) ) {

    xs <- yg::load_dbfile_sc(
      fn = dat_file, colname = a_colname, coltype = a_coltype,
      sc_colname = sc_colname, id_colname = NULL,
      waitime = waitime, sep = ",", skip = 1L
    )

  } else {

    # yg::load_dbfile_sc handle can readin w pre-specified order
    sc_colname_sort <- a_colname[sort(match(sc_colname, a_colname))]

    sc_coltype_sort <- rep("NULL", length(a_coltype))

    sc_coltype_sort[match(sc_colname_sort, a_colname)] <- a_colname[match(sc_colname_sort, a_colname)]

    xs <- data.table::fread(
      input = dat_file, sep = ",", skip = 1L,
      col.names = sc_colname_sort, colClasses = sc_coltype_sort
    )

    setcolorder(xs, sc_colname)

  }


  # post-processing
  xs <- xs %>% 
    dplyr::arrange(zip) %>%
    dplyr::rename(pop = population) %>%
    subset(!is.na(lat) & !is.na(lng)) %>%
    subset(!is.na(pop) & !is.na(ink)) %>%
    dplyr::mutate(zip3 = substr(zip, 1, 3)) %>%
    dplyr::mutate(city = paste0(gsub("(^|[[:space:]])([[:alpha:]])", "\\1\\U\\2", tolower(city), perl=TRUE))) %>%
    `class<-`(c("data.table", "data.frame"))

  return(xs)

}

#------------------- create zip3 -- optim zip5 mapping file -------------------#

#' create_mapping_zip3_optim_zip5
#' find optimial zip5 within zip3 w.r.t min sum(d(s,t)) for all zip3 
create_mapping_zip3_optim_zip5 <- function(dzip) {
  
  m_zip3_zip5 <- dzip %>% 
    select(zip, zip3, lat, lng, pop) %>% 
    group_by(zip3) %>% 
    summarise(zip = find_optimal_zip5_within_zip3(zip, lat, lng, pop)) %>%
    merge(dzip[ , .(zip, lat, lng)], by = "zip", all.x = TRUE, all.y = FALSE) %>%
    setcolorder(c("zip3", "zip", "lat", "lng")) %>%
    `class<-`(c("data.table", "data.frame"))
  
  return(m_zip3_zip5)
  
}

#' find_optimal_zip5_within_zip3
#' find s<zip5> min sum(d(s,t)) for w.r.t all t<zip5> in same zip3 
find_optimal_zip5_within_zip3 <- function(zip, lat, lng, pop) {
  
  ddat <- data.table(zip = zip, lat = lat, lng = lng, pop = pop)
  
  opt_zip <- CJ.dt(ddat, ddat) %>%
    mutate(dist = distRpl_wlatlng_cpp(lat, lng, i.lat, i.lng)) %>%
    group_by(zip) %>% summarise(dist = sum(dist * i.pop), pop = mean(pop)) %>%
    arrange(dist, -pop) %>% slice(1) %>% `[[`("zip")
  
  return(opt_zip)
  
}

#------------------------------------------------------------------------------#

#----------------- create analytic view ready matrix and list -----------------#

#' create_dmtx_from_ddzt
create_dmtx_from_ddzt <- function(ddat = ddzt) {
  
  #- create matrix dmtx_<objective>_<weighting>
  ## i.e. dmtx_dist_pop - view default setting.
  ddat <- ddat %>% arrange(s, t)
  
  dmtx_dist_pop <- data.table::dcast(ddat[ , .(s, t, d = dist * p_pop)], s ~ t, value.var = "d")
  
  ## source name list s <source>
  # s_name <- dmtx_dist_pop[["s"]]
  if ( ! all(dsrc[["s"]] == dmtx_dist_pop[["s"]]) ) {
    
    stop("create_dmtx_from_ddzt: arrange s in dsrc w.r.t ddzt.\n")
    
  }
  
  dmtx_dist_pop[ , s := NULL ]
  
  ## target name list t <target>
  # t_name <- names(dmtx_dist_pop)
  if ( ! all(ddst[["t"]] == names(dmtx_dist_pop)) ) {
    
    stop("create_dmtx_from_ddzt: arrange t in ddst w.r.t ddzt.\n")
    
  }
  
  ## us-zip-code-map g<s-group> by 1st
  # g <- as.numeric(as.factor(substr(s_name, 1, 1)))
  
  ## weighting strategy p_pop and p_ink
  # dwts <- ddat %>% 
  #   group_by(t) %>% summarise(pop = mean(pop), ink = mean(ink)) %>%
  #   ungroup %>% mutate(p_pop = pop / sum(pop), p_ink = ink / sum(ink)) %>% 
  #   `class<-`(c("data.table", "data.frame"))
  # 
  # p_pop <- dwts[["p_pop"]][match(t_name, dwts[["t"]])]
  # 
  # p_ink <- dwts[["p_ink"]][match(t_name, dwts[["t"]])]
  
  ## optimization supporting info list 
  # dlst <- list(s_name = s_name, g = g, t_name = t_name, p_pop = p_pop, p_ink = p_ink)
  
  # saveRDS(dlst, file = "dat/dlst.RDS")
  
  ## objective with weighting - matrix
  for ( o in c("dist", "zone", "stnt") ) {
    
    eval(parse(text = paste0(
      'dmtx <- data.table::dcast(',
        'ddat[ , .(s, t, d = ', o, ')], s ~ t, value.var = "d"', 
      ') %>% ', 
        'select(-s) %>% as.matrix()'
    )))
    
    eval(parse(text = paste0(
      'saveRDS(dmtx, file = "dat/dmtx', '_', o, '.RDS")'
    )))
    
    for ( w in c("pop", "ink") ) {
      
      eval(parse(text = paste0(
        'dmtx <- data.table::dcast(',
          'ddat[ , .(s, t, d = ', o, ' * ', 'p_', w, ')], s ~ t, value.var = "d"', 
        ') %>% ',
          'select(-s) %>% as.matrix()'
      )))
      
      eval(parse(text = paste0(
        'saveRDS(dmtx, file = "dat/dmtx', '_', o, '_', w, '.RDS")'
      )))
      
    }
    
  }
  
  return(NULL)
}

#------------------------------------------------------------------------------#
