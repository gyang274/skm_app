#------------------------------------------------------------------------------#
#--------------------------------- skm::app.r ---------------------------------#
#------------------------- author: gyang274@gmail.com -------------------------#
#------------------------------------------------------------------------------#

#--------+---------+---------+---------+---------+---------+---------+---------#
#234567890123456789012345678901234567890123456789012345678901234567890123456789#

#------------------------------------------------------------------------------#
#------------------------------------ init ------------------------------------#
#------------------------------------------------------------------------------#

library(skm)

library(plyr)
library(dplyr)

#------------------------------------------------------------------------------#

#------------------------------------------------------------------------------#
#------------------------------------ load ------------------------------------#
#------------------------------------------------------------------------------#
source("util.r")
source("src/shine_u.r")
source("src/shine_c.r")
#------------------------------------------------------------------------------#

#------------------------------------------------------------------------------#
#------------------------------------ main ------------------------------------#
#------------------------------------------------------------------------------#

#------------------------------------------------------------------------------#

#- question: a busniess want to start building it's warehouses - objective reach
#- as many as u.s population as possible - minimize population weighted distance
#- so where to build the first one, the second one, the third one, and etc.?

## load zip dat
dzip <- load_zip_dat()

## map zip3 into optim zip5 within zip3 area so
## can have a lat lng for generating a distance
# m_zip3_zip5 <- create_mapping_zip3_optim_zip5(dzip)
# saveRDS(m_zip3_zip5, file = "mat/m_zip3_zip5.RDS")
m_zip3_zip5 <- readRDS("mat/m_zip3_zip5.RDS")

## create dsrc s <source>

## consider top zip3 in each state with most population as
## candiate location on building a warehouse in the future

dsrc <- dzip %>% 
  group_by(state, zip3) %>% 
  summarise(pop = sum(pop)) %>% 
  arrange(-pop) %>%
  group_by(state) %>% 
  slice(1) %>%
  select(zip3) %>%
  merge(m_zip3_zip5, by = "zip3") %>%
  select(zip) %>%
  merge(dzip, by = "zip") %>%
  select(-zip3) %>%
  mutate(g = as.numeric(as.factor(substr(zip, 1, 1)))) %>%
  mutate(id = paste0(city, ' - ', state, ' (', zip, ')')) %>%
  mutate(popup = paste0(
    '<b>', city, ' - ', state, ' (', zip, ')', '<b><br/>',
    'Population: ', round(pop / 1000.00000, 2), ' Thousands', '<br/>',
    'Total Income: ', round(ink / 1000000.00, 2), ' Millions')) %>%
  rename(s = zip, s_lat = lat, s_lng = lng) %>%
  `class<-`(c("data.table", "data.frame"))

saveRDS(dsrc, file = "dat/dsrc.RDS")

## create ddst t <target> (destination)
## want to reach all u.s. so all zip included
ddst <- dzip %>%
  select(zip, lat, lng, pop, ink, city, state) %>%
  rename(t = zip, t_lat = lat, t_lng = lng) %>%
  mutate(p_pop = pop / sum(pop),
         p_ink = ink / sum(ink)) %>%
  `class<-`(c("data.table", "data.frame"))

saveRDS(ddst, file = "dat/ddst.RDS")

## create analytical data ddzt: dist zone stnt
## distance zone and estimated time in transit
ddzt <- yg::CJ.dt(dsrc[ , .(s, s_lat, s_lng)], ddst) %>%
  mutate(dist = distRpl_wlatlng_cpp(s_lat, s_lng, t_lat, t_lng)) %>%
  mutate(zone = create_zone_from_dist(dist)) %>%
  mutate(stnt = create_stnt_from_dist_pop(dist, pop)) %>%
  `class<-`(c("data.table", "data.frame"))

create_dmtx_from_ddzt(ddzt)
