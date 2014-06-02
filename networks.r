#' Build committee-specific amendment cosponsorship networks
#' 
#' @references http://www.europarl.europa.eu/committees/en/full-list.html
load('amdts.rda')

export = FALSE

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
results = data.frame()

for(i in names(coms)[ order(coms) ]) {

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
    n %n% "meta" = i
    
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
    
    save(n, g, e, d, file = file)
    
  }
  
  load(file)
  cat(network.size(n), "nodes", network.edgecount(n), "edges\n")
  
  file = paste0("data/com_", i, ".gexf")
  if(!file.exists(file) & export) {
    
    colors = t(col2rgb(groups[ names(groups) %in% as.character(n %v% "group") ]))
    
    mode = "fruchtermanreingold"
    meta = list(creator = "rgexf",
                description = paste0(mode, " placement"),
                keywords = "Parliament, European Union")
    
    people = sponsors[ network.vertex.names(n), ]

    node.att = cbind(label = tolower(people$name), people[, c("name", "group", "link", "id") ])
    
    people = data.frame(id = as.numeric(factor(tolower(people$name))),
                        label = tolower(people$name),
                        stringsAsFactors = FALSE)
    
    relations = data.frame(
      source = as.numeric(factor(n %e% "source", levels = levels(factor(people$label)))),
      target = as.numeric(factor(n %e% "target", levels = levels(factor(people$label)))),
      weight = n %e% "weight"
    )
    relations = na.omit(relations)
    
    nodecolors = lapply(node.att$group, function(x)
      data.frame(r = rgb[x, 1], g = rgb[x, 2], b = rgb[x, 3], a = .3 ))
    nodecolors = as.matrix(rbind.fill(nodecolors))
    
    net = as.matrix.network.adjacency(n)
    
    # placement method (Kamada-Kawai best at separating at reasonable distances)
    position = paste0("gplot.layout.", mode)
    if(!exists(position)) stop("Unsupported placement method '", position, "'")
    
    position = do.call(position, list(net, NULL))
    position = as.matrix(cbind(position, 1))
    colnames(position) = c("x", "y", "z")
    
    # compress floats
    position[, "x"] = round(position[, "x"], 2)
    position[, "y"] = round(position[, "y"], 2)
    
    node.att$group = as.character(node.att$group)
    people$label = toupper(people$label)
    node.att$label = toupper(node.att$label)
    
    write.gexf(nodes = people,
               edges = relations[, -3],
               edgesWeight = relations[, 3],
               nodesAtt = data.frame(label = node.att$label,
                                     name = node.att$name,
                                     group = node.att$group,
                                     uid = node.att$id,
                                     link = node.att$link,
                                     stringsAsFactors = FALSE),
               nodesVizAtt = list(position = position,
                                  color = nodecolors,
                                  size = rep(1, nrow(people))), # , size = node.att[, nodes ]
               # edgesVizAtt = list(size = relations[, 3]),
               defaultedgetype = "undirected", meta = meta,
               output = file)
    
  }
  
  file = paste0("data/mod_", i, ".rda")
  if(!file.exists(file)) {
    
    # weighted adjacency matrix to tnet
    tnet = as.tnet(as.sociomatrix(n, attrname = "weight"), type = "weighted one-mode tnet")
    
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
    #   if(sum(s == "ECO", na.rm = TRUE) < 10 & any(s == "ECO"))
    #     s[ s == "ECO" ] = "SOC"
    #   if(sum(s == "COM", na.rm = TRUE) < 10 & any(s == "COM"))
    #     s[ s == "COM" ] = "SOC"
    
    # drop unaffiliated sponsors
    s = ifelse(s == "SE", NA, s)
    
    # get MP parliamentary groups
    names(s) = network.vertex.names(n)
    
    # subset to nonmissing groups
    V(inet)$group = factor(s[ V(inet)$name ])
    print(table(V(inet)$group, exclude = NULL))
    
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
#                              Centralization = net %n% "degree",
#                              Distance = net %n% "distance",
#                              Global.Clustering = net %n% "clustering",
                             # maximized modularity
                             Modularity = modularity,
                             Modularity.Max = modularity_max,
                             Modularity.Ratio = modularity / modularity_max,
                             stringsAsFactors = FALSE))

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
    labs(y = NULL, x = "\nModularity") +
    theme_bw(16) +
    theme(legend.justification=c(0,1), legend.position=c(0,1),
          axis.text.y = element_blank(),
          axis.ticks.y = element_blank())
  
  ggsave("plots/modularity.pdf", g, width = 6, height = 6)
  ggsave("plots/modularity.png", g, width = 6, height = 6)
  
  g = qplot(data = results,
            x = Edges,
            y = Vertices,
            size = Density,
            label = Committee, geom = "text") +
    scale_size_continuous(range = c(3, 6)) +
    geom_vline(xintercept = mean(results$Edges), linetype = "dashed") +
    geom_hline(yintercept = mean(results$Vertices), linetype = "dashed") +
    labs(y = "Nodes\n", x = "\nEdges") +
    theme_bw(16) +
    theme(legend.justification=c(0,1), legend.position=c(0,1))
  
  ggsave("plots/density.pdf", g, width = 10, height = 9)
  ggsave("plots/density.png", g, width = 10, height = 9)

}

# have a nice day
