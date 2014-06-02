# makefile

msg <- function(...) message(paste(...))

dir.create("data"  , showWarnings = FALSE)
dir.create("dumps" , showWarnings = FALSE)
dir.create("plots" , showWarnings = FALSE)

# parser

library(XML)
library(jsonlite)
library(qdap)
library(stringr)
library(plyr)
library(dplyr)
library(qdap)

# networks

library(network)
library(devtools)
library(ggplot2)
library(scales)
library(sna)

source_url("https://raw.githubusercontent.com/briatte/ggnet/master/ggnet.R")

source("data.r")
source("networks.r")

# enjoy your day
