# makefile

msg <- function(...) message(paste(...))

dir.create("data"  , showWarnings = FALSE)
dir.create("dumps" , showWarnings = FALSE)
dir.create("plots" , showWarnings = FALSE)

# parser

library(jsonlite)
library(XML)
library(qdap)
library(stringr)
library(plyr)
library(dplyr)

# networks

library(network)
library(sna)
library(tnet)
library(igraph)
library(rgexf)

# plots

library(ggplot2)
library(reshape2)
library(scales)
library(GGally)

source("data.r")
source("networks.r")

# enjoy your day
