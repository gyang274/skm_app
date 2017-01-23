<!-- README.md is generated from README.Rmd. Please edit that file -->
OWL - Optimal Warehouse Locator
===============================

A brief introduction on how the problem is constructed, and the business problem targeted to solve.

``` r
library(skm)

library(plyr)
library(dplyr)

#- question: a busniess want to start building it's warehouses - objective reach
#- as many as u.s population as possible - minimize population weighted distance
#- so where to build the first one, the second one, the third one, and etc.?

## load skm built in datasets
data("zip2012")
data("source_zip_list")

## suppose build at most one warehouse in each state located at source_zip_list:
## create a s <source> - t <destination> - dist <distance> analytical data.table

## create dsrc s <source>
dsrc <- zip2012 %>%
  subset(zip %in% source_zip_list) %>%
  rename(s = zip, s_lat = lat, s_lng = lng) %>%
  select(s, s_lat, s_lng) %>%
  `class<-`(c("data.table", "data.frame"))

## create ddst t <target> (destination)
## want to reach all u.s. so all zip included
ddst <- zip2012 %>% 
  rename(t = zip, t_lat = lat, t_lng = lng) %>%
  select(t, t_lat, t_lng, pop) %>%
  `class<-`(c("data.table", "data.frame"))

## create analytical data ddzt: s - t - dist

# > yg::CJ.dt
# function (X, Y) 
# {
#     stopifnot(is.data.table(X), is.data.table(Y))
#     k = NULL
#     X = X[, c(k = 1, .SD)]
#     setkey(X, k)
#     Y = Y[, c(k = 1, .SD)]
#     setkey(Y, NULL)
#     return(X[Y, allow.cartesian = TRUE][, `:=`(k, NULL)][])
# }
# <environment: namespace:yg>

ddzt <- yg::CJ.dt(dsrc, ddst) %>%
  mutate(dist = distRpl_wlatlng_cpp(s_lat, s_lng, t_lat, t_lng)) %>%
  `class<-`(c("data.table", "data.frame"))

## solve the problem with skm_mls
## suppose we want to know the best solution for 1-10 number of warehouse:
skm_mls(
  x = ddzt, k = 1L:10L, s_colname = "s", t_colname = "t", 
  d_colname = "dist", w_colname = "pop"
)

## suppose we already built 4 warehouses at NJ, IA, TX and CA, and want to
## know where to build the 5th - 10th warehouse:

skm_mls(
  x = ddzt, k = 5L:10L, s_colname = "s", t_colname = "t", 
  d_colname = "dist", w_colname = "pop", 
  s_must = c("07017",  "50317", "77804", "94596")
)

## a slightly different scenario is that we decided to build 4 warehouses 
## at NJ, IA, TX and CA, and also want to know where to build the 5-10th.
## when number of warehouse <= 4, select location within 4 already built,
## and when number of warehhouse > 4 we build on top of these 4 locations

skm_mls(
  x = ddzt, k = 1L:10L, s_colname = "s", t_colname = "t", 
  d_colname = "dist", w_colname = "pop", 
  s_must = c("07017",  "50317", "77804", "94596")
)
```
