#' Build committee-specific amendment cosponsorship networks
#' 
#' @references http://www.europarl.europa.eu/committees/en/full-list.html
load("data/amdts.rda")

plot = TRUE
gexf = TRUE
zip = TRUE

groups = c(
  "Far-left" = "#E41A1C",
  "Greens" = "#4DAF4A",
  "Socialists" = "#F781BF",
  "Centrists" = "#FF7F00",
  "Christian-Democrats" = "#377EB8",
  "Euroskeptics" = "#984EA3",
  "Extreme-right" = "#A65628",
  "Independents" = "#999999")

order = names(groups)

rgb = t(col2rgb(groups))

sponsors = unique(meps[, c("link", "name", "id", "group", "natl", "photo") ])
sponsors$group = factor(sponsors$group, levels = names(groups), ordered = TRUE)
rownames(sponsors) = tolower(sponsors$name)

countries = c(
  "at" = "Austria",
  "be" = "Belgium",
  "bg" = "Bulgaria",
  "cy" = "Cyprus",
  "cz" = "the Czech Republic",
  "de" = "Germany",
  "dk" = "Denmark",
  "ee" = "Estonia",
  "es" = "Spain",
  "fi" = "Finland",
  "fr" = "France",
  "gb" = "Great Britain",
  "gr" = "Greece",
  "hr" = "Croatia",
  "hu" = "Hungary",
  "ie" = "Ireland",
  "it" = "Italy",
  "lt" = "Lithuania",
  "lu" = "the Tax Haven of Luxembourg",
  "lv" = "Latvia",
  "mt" = "Malta",
  "nl" = "the Netherlands",
  "pl" = "Poland",
  "pt" = "Portugal",
  "ro" = "Romania",
  "se" = "Sweden",
  "si" = "Slovenia",
  "sk" = "Slovakia")

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
results = data.frame()

for(i in names(coms)[ order(sort(coms)) ]) {

  d = subset(data, committee == i & n_au > 1)
  
  total = sum(d$n_au)
  cat(i, titles[ i ], ":", total, "sponsorships ... ")
  
  file = paste0("data/com_", i, ".rda")
  if(!file.exists(file)) {
    
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
    e = rbind.fill(n)
    names(e) = c("i", "j")
    
    # edge weights (raw counts, undirected network)
    e$w = paste(e$i, e$j, sep = "_")
    count = table(e$w)
    e$w = count[ e$w ]
    e = unique(e)
    
    n = network(e[, 1:2 ], directed = FALSE)
    n %n% "title" = i

    n %n% "n_amendments" = nrow(d)
    n %n% "n_sponsors" = table(subset(data, committee == i)$n_au)
    
    network::set.edge.attribute(n, "source", as.character(e[, 1]))
    network::set.edge.attribute(n, "target", as.character(e[, 2]))
    network::set.edge.attribute(n, "weight", as.numeric(e[, 3]))
    network::set.edge.attribute(n, "alpha", as.numeric(cut(n %e% "weight", c(1:4, Inf), include.lowest = TRUE)) / 5)
    
    n %v% "group" = as.character(sponsors[ tolower(network.vertex.names(n)), "group" ])
    n %v% "nat" = as.vector(countries[ as.character(sponsors[ tolower(network.vertex.names(n)), "natl" ]) ])
    n %v% "url" = gsub("/meps/en/|_home\\.html", "", sponsors[ tolower(network.vertex.names(n)), "link" ])
    n %v% "photo" = as.character(sponsors[ tolower(network.vertex.names(n)), "photo" ])
    # n %v% "nb_mandates" = as.character(sponsors[ tolower(network.vertex.names(n)), "nb_mandates" ])
    
    # weighted adjacency matrix to tnet
    tnet = as.tnet(as.sociomatrix(n, attrname = "weight"), type = "weighted one-mode tnet")
    
    # weighted degree and distance
    wdeg = as.data.frame(degree_w(tnet, measure = "degree"))
    dist = distance_w(tnet)
    wdeg$distance = NA
    wdeg[ attr(dist, "nodes"), ]$distance = colMeans(dist, na.rm = TRUE)
    wdeg = cbind(wdeg, clustering_local_w(tnet)[, 2])
    names(wdeg) = c("node", "degree", "distance", "clustering")
    
    n %v% "degree" = wdeg$degree
    n %n% "degree" = mean(wdeg$degree, na.rm = TRUE)
    
    n %v% "distance" = wdeg$distance
    n %n% "distance" = mean(wdeg$distance, na.rm = TRUE)

    n %v% "clustering" = wdeg$clustering    # local
    n %n% "clustering" = clustering_w(tnet) # global

    save(n, e, d, file = file) # network, edges and data
    
  }
  
  load(file)
  cat(network.size(n), "nodes", network.edgecount(n), "edges\n")
  
  # edge colors
  
  ii = groups[ sponsors[ n %e% "source", "group" ] ]
  jj = groups[ sponsors[ n %e% "target", "group" ] ]
  
  party = as.vector(ii)
  party[ ii != jj ] = "#AAAAAA"
  
  print(table(n %v% "group", exclude = NULL))
  
  # number of amendments cosponsored
  na = sapply(network.vertex.names(n), function(x) {
    sum(grepl(x, d$authors, ignore.case = TRUE)) # ids are unique names
  })
  n %v% "n_amendments" = as.vector(na)

  if(plot) {

    q = unique(quantile(n %v% "degree")) # safer
    n %v% "size" = as.numeric(cut(n %v% "degree", q, include.lowest = TRUE))
    g = suppressWarnings(ggnet(n, size = 0, segment.alpha = 1/2, # mode = "kamadakawai",
                               segment.color = party) +
                           geom_point(alpha = 1/3, aes(size = n %v% "size", color = n %v% "group")) +
                           geom_point(alpha = 1/2, aes(size = min(n %v% "size"), color = n %v% "group")) +
                           scale_size_continuous(range = c(6, 12)) +
                           scale_color_manual("", values = groups, breaks = order) +
                           labs(title = paste0(titles[ i ], " (", i, ")")) +
                           theme(#legend.key = element_blank(),
                             legend.position = "bottom",
                             legend.key.size = unit(1, "cm"),
                             legend.text = element_text(size = 16)) +
                           guides(size = FALSE, color = guide_legend(override.aes = list(alpha = 1/3, size = 6))))
    
    print(g)
    
    ## unweighted, colored by edge source
    
    #     g = ggnet(n, segment.color = groups[ sponsors[ e$i, "group" ] ],
    #               segment.alpha = n %e% "alpha",
    #               node.group = n %v% "group", node.color = groups[ unique(n %v% "group") ], size = 0) +
    #       scale_color_manual("", values = groups, breaks = names(groups)) +
    #       scale_alpha_discrete() +
    #       geom_point(size = 9, alpha = 1/3) +
    #       geom_point(size = 6, alpha = 1/2) +
    #       labs(title = paste0(titles[ i ], " (", i, ")")) +
    #       theme(legend.position = "bottom")
    
    ggsave(paste0("plots/", i, ".pdf"), g, width = 12, height = 12)
    ggsave(paste0("plots/", i, ".jpg"), g + labs(title = NULL) + theme(legend.position = "none"), 
           width = 9, height = 9, dpi = 72)
    
  }
  
  if(gexf) {
    
    colors = t(col2rgb(groups[ names(groups) %in% as.character(n %v% "group") ]))
    
    # placement method (Kamada-Kawai best at separating at reasonable distances)
    mode = "fruchtermanreingold"
    meta = list(creator = "rgexf",
                description = paste(mode, "placement", nrow(d), "amendments"),
                keywords = "parliament, european union")
    
    node.att = data.frame(
      group = n %v% "group",
      amendments = n %v% "n_amendments",
      nat = n %v% "nat",
      url = n %v% "url",
      photo = n %v% "photo",
      distance = round(n %v% "distance", 1),
      stringsAsFactors = FALSE)
        
    people = data.frame(id = as.numeric(factor(sponsors[ network.vertex.names(n), "name" ])),
                        label = sponsors[ network.vertex.names(n), "name" ], stringsAsFactors = FALSE)
    
    relations = data.frame(
      source = as.numeric(factor(n %e% "source", levels = levels(factor(tolower(people$label))))),
      target = as.numeric(factor(n %e% "target", levels = levels(factor(tolower(people$label))))),
      weight = round(n %e% "weight", 2)) # , count = n %e% "count"
    relations = na.omit(relations)
    
    # check all weights are positive after rounding
    stopifnot(all(relations$weight > 0))
    
    nodecolors = lapply(node.att$group, function(x)
      data.frame(r = rgb[x, 1], g = rgb[x, 2], b = rgb[x, 3], a = .5))
    nodecolors = as.matrix(rbind.fill(nodecolors))
    
    # node placement
    position = do.call(paste0("gplot.layout.", mode),
                       list(as.matrix.network.adjacency(n), NULL))
    position = as.matrix(cbind(round(position, 1), 1))
    colnames(position) = c("x", "y", "z")

    # save with compressed floats
    write.gexf(nodes = people, nodesAtt = node.att,
               edges = relations[, 1:2 ], edgesWeight = relations[, 3],
               nodesVizAtt = list(position = position, color = nodecolors,
                                  size = round(n %v% "degree", 1)),
               defaultedgetype = "undirected", meta = meta,
               output = gsub("data/", "", gsub(".rda", ".gexf", file)))
    
  }

  file = paste0("data/mod_", i, ".rda")
  if(!file.exists(file)) {
    
    # symmetrise for undirected algorithms 
    tnet = symmetrise_w(tnet, method = "AMEAN")
        
    # rename vertices
    tnet = data.frame(
      i = network.vertex.names(n)[ tnet[, 1] ],
      j = network.vertex.names(n)[ tnet[, 2] ],
      w = tnet[, 3]
    )
    
    # convert to igraph
    inet = graph.edgelist(as.matrix(tnet[, 1:2]), directed = FALSE)
    E(inet)$weight = tnet[, 3]
    
    # merge appended sponsors to main groups
    s = n %v% "group"
    names(s) = network.vertex.names(n)
    
    # subset to nonmissing groups
    V(inet)$group = factor(s[ V(inet)$name ])
    print(table(V(inet)$group, exclude = NULL))
    
    # keeping Independents as a political group
    inet = inet - which(is.na(V(inet)$group))
    
    # modularity
    modularity = modularity(inet, membership = V(inet)$group, weights = E(inet)$weight)
    
    msg("Modularity:", round(modularity, 2),
        "over", n_distinct(V(inet)$group), "groups")
    
    # maximized Walktrap (Waugh et al. 2009, arXiv:0907.3509, Section 2.3)
    walktrap = lapply(1:50, function(x) walktrap.community(inet, steps = x))
    
    # max. partition
    maxwalks = order(sapply(walktrap, modularity), decreasing = TRUE)[1]
    walktrap = walktrap[[ maxwalks ]]
    
    msg("Maximized to", n_distinct(walktrap[[ "membership" ]]), "groups (Walktrap,", maxwalks, "steps out of 50)")
    
    # multilevel Louvain (Blondel et al. 2008, arXiv:0803.0476)
    louvain = multilevel.community(inet)
    
    msg("Maximized to", n_distinct(louvain[[ "membership" ]]), "groups (Louvain)")
    
  } else {
    
    load(file)
    
  }
  
  save(tnet, inet, modularity, walktrap, louvain, file = file)
  
  modularity_max = max(c( modularity(walktrap), modularity(louvain) ))
  results = rbind(results,
                  data.frame(Committee = i,
                             # unweighted graph-level
                             Vertices = network.size(n),
                             Edges = network.edgecount(n),
                             Density = network.density(n),
                             # weighted graph-level
                             Centralization = n %n% "degree",
                             Distance = n %n% "distance",
                             Global.Clustering = n %n% "clustering",
                             # maximized modularity
                             Modularity = modularity,
                             Modularity.Max = modularity_max,
                             Modularity.Ratio = modularity / modularity_max,
                             stringsAsFactors = FALSE))

}

# plots

g = qplot(data = results,
          size = I(4),
          x = Modularity,
          color = Modularity.Ratio,
          y = reorder(Committee, Modularity.Ratio),
          label = Committee, geom = "text") +
  scale_color_gradient(low = "steelblue", high = "darkred") +
  geom_point(aes(x = Modularity.Max), size = 3, color = "grey50") +
  geom_point(aes(x = Modularity.Max), size = 2, color = "white") +
  geom_vline(xintercept = mean(results$Modularity), linetype = "dashed") +
  geom_vline(xintercept = mean(results$Modularity.Max), linetype = "dotted") +
  labs(y = "EP committee\n", x = "\nModularity (empirical and maximized)") +
  theme_bw(16) +
  theme(legend.justification=c(0,1), legend.position=c(0,1),
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        axis.line.y = element_line(color = "grey10"))

ggsave("plots/modularity.pdf", g, width = 9, height = 9)
ggsave("plots/modularity.png", g, width = 9, height = 9)

g = qplot(data = results,
          x = Edges,
          y = Vertices,
          size = Density,
          label = Committee, geom = "text") +
  scale_size_continuous(range = c(3, 6)) +
  geom_vline(xintercept = mean(results$Edges), linetype = "dashed") +
  geom_hline(yintercept = mean(results$Vertices), linetype = "dashed") +
  labs(y = "Nodes (MEPs)\n", x = "\nEdges (cosponsorships)") +
  theme_bw(16) +
  theme(legend.justification=c(0,1), legend.position=c(0,1),
        axis.line.y = element_line(color = "grey10"))

ggsave("plots/density.pdf", g, width = 10, height = 9)
ggsave("plots/density.png", g, width = 10, height = 9)

if(zip)
  zip("net_eu.zip", dir(pattern = "gexf$"))

# have a nice day
