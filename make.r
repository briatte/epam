library(XML)
library(jsonlite)
library(qdap)
library(stringr)
library(plyr)
library(dplyr)
library(qdap)
library(network)

msg <- function(...) message(paste(...))

dir.create("data")
dir.create("dumps")
dir.create("plots")

source("data.r")
source("networks.r")

# enjoy your day
