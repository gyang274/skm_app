#------------------------------------------------------------------------------#
#----------------------------- shinyApp::global.r -----------------------------#
#------------------------- author: gyang274@gmail.com -------------------------#
#------------------------------------------------------------------------------#

#--------+---------+---------+---------+---------+---------+---------+---------#
#234567890123456789012345678901234567890123456789012345678901234567890123456789#

#------------------------------------------------------------------------------#
#------------------------------------ init ------------------------------------#
#------------------------------------------------------------------------------#

# stwd

# setwd("d:/guang/packages/skm/app/")

# load

source("src/shine_h.r", echo = FALSE, max.deparse.length = 1000L)

source("src/shine_u.r", echo = FALSE, max.deparse.length = 1000L)

source("src/shine_c.r", echo = FALSE, max.deparse.length = 1000L)

# shine_d.r depends on shine_u.r - `%+%` in yg - ggplot2 crash r
source("src/shine_d.r", echo = FALSE, max.deparse.length = 1000L)

#------------------------------------------------------------------------------#