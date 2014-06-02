#' Build networks for each EP committee
#' 
#' @references http://www.europarl.europa.eu/committees/en/full-list.html
load('amdts.rda')

sponsors = unique(meps[, c("link", "name", "id", "group") ])
sponsors$group = factor(sponsors$group, levels = names(groups), ordered = TRUE)
rownames(sponsors) = tolower(sponsors$name)

groups = c(
  "Far-left" = "#E41A1C",
  "Greens" = "#4DAF4A",
  "Socialists" = "#F781BF",
  "Centrists" = "#FF7F00",
  "Christian-Democrats" = "#377EB8",
  "Euroskeptics" = "#984EA3",
  "Extreme-right" = "#A65628",
  "Independents" = "#999999")

rgb = t(col2rgb(groups))

titles = c("AFCO" = "Constitutional Affairs",
           "AFET" = "Foreign Affairs",
           "AGRI" = "Agriculture and Rural Development",
           "BUDG" = "Budgets",
           "CONT" = "Budgetary Control",
           "CRIM" = "Organised crime, corruption and money laundering",
           "CRIS" = "Financial, Economic and Social Crisis",
           "CULT" = "Culture and Education",
           "DEVE" = "Development",
           "DROI" = "Human Rights",
           "ECON" = "Economic and Monetary Affairs",
           "EMPL" = "Employment and Social Affairs",
           "ENVI" = "Environment, Public Health and Food Safety",
           "FEMM" = "Women's Rights and Gender Equality",
           "IMCO" = "Internal Market and Consumer Protection",
           "INTA" = "International Trade",
           "ITRE" = "Industry, Research and Energy",
           "JURI" = "Legal Affairs",
           "LIBE" = "Civil Liberties, Justice and Home Affairs",
           "PECH" = "Fisheries",
           "PETI" = "Petitions",
           "REGI" = "Regional Development",
           "SEDE" = "Security and Defence",
           "SURE" = "Policy Challenges",
           "TRAN" = "Transport and Tourism")

coms = table(unlist(strsplit(data$committee, ";")))
for(i in names(coms)[ order(coms) ]) {

  d = subset(data, committee == i & n_au > 1)
  
  total = sum(d$n_au)
  msg(i, titles[ i], total, "sponsorships")
  
  if(!file.exists(paste0("data/com_", i, ".rda"))) {
    
    n = lapply(tolower(d$authors), function(x) {
      x = strsplit(x, ",")
      x = sapply(x, scrubber)
      x = x[ x %in% tolower(sponsors$name) ]
      if(all(is.na(x)) | all(is.null(x)))
        return(data.frame())
      x = data.frame(expand.grid(x, x), stringsAsFactors = FALSE)
      x = x[ x$Var1 != x$Var2, ]
      x = data.frame(t(apply(x, 1, sort)), stringsAsFactors = FALSE)
      return(unique(x))
    })
    
    # edge list
    n = rbind.fill(n)
    names(n) = c("i", "j")
    
    # edge weights
    n$w = paste(n$i, n$j, sep = "_")
    count = table(n$w)
    n$w = count[ n$w ]
    n = unique(n)
    
    #   d3SimpleNetwork(n, file = paste0("plots/", i, ".html"), charge = -100)
    #   e = groups[ sponsors[ n$i, "group" ] ]
    
    e = n
    n = network(n[, 1:2 ], directed = FALSE)
    
    network::set.edge.attribute(n, "source", as.character(e[, 1]))
    network::set.edge.attribute(n, "target", as.character(e[, 2]))
    network::set.edge.attribute(n, "weight", as.numeric(e[, 3]))
    network::set.edge.attribute(n, "alpha", as.numeric(cut(n %e% "weight", c(1:4, Inf), include.lowest = TRUE)) / 5)
    
    n %v% "group" = as.character(sponsors[ tolower(network.vertex.names(n)), "group" ])
    g = ggnet(n, segment.color = groups[ sponsors[ e$i, "group" ] ],
              segment.alpha = n %e% "alpha",
              node.group = n %v% "group", node.color = groups[ unique(n %v% "group") ], size = 0) +
      scale_color_manual("", values = groups, breaks = names(groups)) +
      scale_alpha_discrete() +
      geom_point(size = 9, alpha = 1/3) +
      geom_point(size = 6, alpha = 1/2) +
      labs(title = paste0(titles[ i ], " (", i, ")")) +
      theme(legend.position = "bottom")
    
    ggsave(paste0("plots/", i, ".pdf"), g, width = 11, height = 11)
    ggsave(paste0("plots/", i, ".jpg"), g + labs(title = NULL) + guides(color = FALSE), width = 6, height = 6)
    
    save(n, g, e, d, file = paste0("data/com_", i, ".rda"))
    
  }
  
}

# have a nice day
