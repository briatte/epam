# makefile

msg <- function(...) message(paste(...))

dir.create("data"  , showWarnings = FALSE)
dir.create("dumps" , showWarnings = FALSE)
dir.create("plots" , showWarnings = FALSE)

# parser

library(jsonlite)
library(qdap)
library(stringr)
library(plyr)
library(XML)
library(dplyr) # keep last

# networks

library(igraph) # keep first
library(network)
library(sna)
library(rgexf)
library(tnet)

# plots

library(GGally)
library(ggplot2)
library(grid) # for unit()

source("data.r")
source("networks.r")

# enjoy your day
