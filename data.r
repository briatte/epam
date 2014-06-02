#' Extract amendments from the Parltrack data dump
#' 
#' @source http://parltrack.euwiki.org/
if(!file.exists("amdts.rda")) {
  
  meps = "data/meps.csv"
  if(!file.exists(meps)) {
    
    msg("Extracting MEPs data...")
    
    html = "http://www.europarl.europa.eu/meps/en/directory.html?filter=all&leg="
    html = htmlParse(html, encoding = "UTF-8")
    
    # index page
    root = function(x) paste0("//div[@class='zone_info_mep']/div[@class='mep_details']/ul/li", x)
    link = xpathSApply(html, root("[@class='mep_name']/a/@href"))
    
    name = xpathSApply(html, root("[@class='mep_name']"))
    name = sapply(name, xmlValue)
    
    write.csv(data.frame(link, name), meps, row.names = FALSE) # , natl, party, group, member
    
  }
  
  meps = read.csv(meps, stringsAsFactors = FALSE)
  
  # loop twice to solve network errors
  for(i in rep(meps$link, 2)) {
    
    j = gsub("/meps/en/(\\d+)(.*)", "\\1", i)
    
    file = paste0("data/", j, "_nfo.csv")
    
    if(!file.exists(file)) {
      
      html = htmlParse(paste0("http://www.europarl.europa.eu/", gsub("home", "history", i)), encoding = "UTF-8")
      group = sapply(xpathApply(html, "//*/li[contains(@class, 'group')]"), xmlValue)
      group = scrubber(group)
      info = sapply(xpathSApply(html, "//ul[contains(@class, 'events_collection')]/li"), xmlValue)
      info = scrubber(info)
      
      if(nchar(group) > 0) {
        
        cat("\nParsing new MEP:", i, "\n")
        info = gsub("(\\w|-)+(Delegation|Committee|Subcommittee) (.*)", "\\2 \\3", info)
        started = ended = NA
        
      } else {
        
        cat("\nParsing old MEP:", i, "\n")
        started = substr(info, 1, 10)
        ended = substr(info, 14, 23)
        info = gsub("\\s+-\\s+Member\\s*$", "", substring(info, 25))
        group = info[1]
        info = info[-1]
        
      }
      
      # bind and drop national party affiliations on the way
      info = data.frame(org = c(group, info), started, ended, stringsAsFactors = FALSE)
      info = rbind(info[1, ], subset(info, grepl("Delegation|Committee|Subcommittee", org)))
      
      info$type = "group"
      info$type[ grepl("Delegation", info$org) ] = "delegation"
      info$type[ grepl("Committee", info$org) ] = "committee"
      info$type[ grepl("Subcommittee", info$org) ] = "subcommittee"
      
      write.csv(data.frame(id = j, info[, c(4, 1, 2:3) ]), file, row.names = FALSE)
      
    } else {
      f = read.csv(file, stringsAsFactors = FALSE)
      
      if(all(is.na(f$started)) | all(is.na(f$ended))) {
        
        f$started[ -1 ] = substr(f$org[ -1 ], 1, 10)
        f$ended[ -1 ] = substr(f$org[ -1 ], 14, 23)
        f$org[ -1 ] = substring(f$org[ -1 ], 25)
        
        write.csv(f[, c("id", "type", "org", "started", "ended") ], file, row.names = FALSE)
        
      }
      
    }
    
  }
  
  # merge raw files
  build <- function(x) {
    x = dir("data", pattern = paste0("_", x, ".csv"))
    x = lapply(paste0("data/", x), read.csv, stringsAsFactors = FALSE)
    return(rbind.fill(x[, c("id", "type", "org", "started", "ended") ]))
  }
  
  msg("Postprocessing MEPs data...")
  
  if(!file.exists("data/nfo.csv")) {
    nfo = build("nfo")
    write.csv(nfo[, c("id", "type", "org", "started", "ended") ], file = "data/nfo.csv", row.names = FALSE)
  }
  
  nfo = read.csv("data/nfo.csv", stringsAsFactors = FALSE)
  
  # party groups
  
  x = unique(nfo[ nfo$type == "group", c("id", "org") ])
  x$org = gsub(" -( )?(Chair|Treasurer|Vice-Chair|Member of the Bureau)?", "", x$org)
  
  y = rep(NA, nrow(x))
  
  # far left
  y[ grepl("Communist and Allies|Left Unity|European United Left|Nordic Green Left", x$org) ] = "Left.COM,LU,EUL/NGL"
  # Greens/regionalists
  y[ grepl("Rainbow|Greens/European Free Alliance", x$org) ] = "Green.RBW,G/EFA"
  # short-lived
  y[ grepl("Green Group", x$org) ] = "Green"
  # socialists
  y[ grepl("Socialist", x$org) ] = "Soc-dem."
  # radicals
  y[ grepl("European Radical Alliance", x$org) ] = "Radic."
  # Lib-Dems
  y[ grepl("Liberal and Democratic|Liberals|Democrat and Reform", x$org) ] = "Lib-dem.ELDR,ALDE"
  # conservatives: EPP family
  y[ grepl("Christian(.*)Democrat", x$org) ] = "Christ-dem.EPP"
  # more conservatives
  y[ grepl("European (Conservative|Democratic) Group|Conservatives and Reformists", x$org) ] = "Conserv."
  # euroskeptics
  y[ grepl("(Independents for a )?Europe of Nations|Democracies and Diversities|Independence/Democracy|Europe of freedom and democracy", x$org) ] = "Euroskep.EoN,I/D,EfD"
  # national-conservatives
  y[ grepl("Democratic Union Group|Union for Europe( of the Nations)?|Progressive Democrats|Forza Europa|European Democratic Alliance", x$org) ] = "Natl-conserv.UDE,EPD,UFE,EDA,UEN"
  # French extreme right and Italian neofascists
  y[ grepl("Identity, Tradition and Sovereignty Group|European Right", x$org) ] = "Extr-Right.ER,ITS"
  # # residuals
  y[ grepl("Ind(e|i)pendent (Group|Member)|Non-attached", x$org) ] = "Indep."
  
  # large families
  y[ grepl("^Left", y) ] = "Far-left"
  y[ grepl("^Green", y) ] = "Greens"
  y[ grepl("^Soc", y) ] = "Socialists"
  y[ grepl("^Lib|^Rad", y) ] = "Centrists"
  y[ grepl("^Conserv|^Eurosk", y) ] = "Euroskeptics" # merged conservatives
  y[ grepl("^Christ", y) ] = "Christian-Democrats" #
  y[ grepl("^Extr|^Natl", y) ] = "Extreme-right" # merged natl-conservatives from legislatures 5-6
  y[ grepl("^Indep", y) ] = "Independents"
  
  # debug here
  if(any(is.na(y))) {
    
    cat("\nThere are unrecognized groups:\n")
    print(table(y, exclude = NULL))
    
  }
  
  x$org = factor(y, levels = c("Far-left", "Greens", "Socialists", "Centrists", "Christian-Democrats", "Euroskeptics", "Extreme-right", "Independents"))
  
  # add party to MP name and link
  meps$id = as.integer(gsub("/meps/en/(\\d+)(.*)", "\\1", meps$link))
  meps = left_join(meps, x, by = "id")
  names(meps)[ names(meps) == "org" ] = "group"
  
  data = "data/amds.csv"
  if(!file.exists(data)) {
    
    msg("Extracting amendments data...")
    
    get <- function(x) {
      
      u = paste0("http://parltrack.euwiki.org/", x)
      if(!file.exists(x)) download.file(u, x, mode = "wb")
      
      return(readLines(xzfile(x), warn = TRUE))
      
    }
    
    read <- function(x) return(fromJSON(x, flatten = TRUE))
    
    amds = read(get("dumps/ep_amendments.json.xz"))
    amds = amds[ , c("_id", "reference", "date", "committee", "authors", "src") ]
    names(amds)[1:2] = c("uid", "proc")
    amds$committee = sapply(amds$committee, function(x) {
      if(!length(x))
        return(NA)
      return(paste0(sort(unique(x)), collapse = ";"))
    })
    write.csv(amds[, c("uid", "proc", "date", "committee", "authors", "src")], data, row.names = FALSE)
    
  }
  
  msg("Postprocessing amendments data...")
  
  data = read.csv('data/amds.csv', stringsAsFactors = FALSE)
  
  data$date = as.Date(data$date)
  data$n_au = 1 + str_count(data$authors, ",")
  
  fix <- function(x) {
    
    x[ grepl("^ECR|^EFD|^EPP|^ALDE|^GREENS|^GUE|&|Republic|Kingdom|Shadow|Committee|European|Council|Parliament|amendment|\\d+", x) ] = NA
    x = gsub("(<AuNomDe>|on behalf|in the name|in name|Draft|Proposed|Proposal|Proposition)(.*)|<|(/)?Members>|\\((.*)\\)$", "", x)
    x = gsub("( and | et |;)", ",", x)
    x = gsub("-\\s", "-", x)
    
    # missing commas
    x = gsub("Franziska Katharina Brantner Ana Gomes Krzysztof Lisek Arnaud Danjean Michael Gahler", "Franziska Katharina Brantner,Ana Gomes,Krzysztof Lisek,Arnaud Danjean,Michael Gahler", x)
    x = gsub("Philippe Lamberts Bas Eickhout", "Philippe Lamberts,Bas Eickhout", x)
    x = gsub("Ana Gomes Marietta Giannakou Ágnes Hankiss", "Ana Gomes,Marietta Giannakou,Ágnes Hankiss", x)
    x = gsub("Jens Rohde Philippe Lamberts", "Jens Rohde,Philippe Lamberts", x)
    x = gsub("Sven Giegold Philippe Lamberts", "Sven Giegold,Philippe Lamberts", x)
    x = gsub("Eva-Britt Svensson Gesine Meissner", "Eva-Britt Svensson,Gesine Meissner", x)
    x = gsub("Marije Cornelissen Sophia in 't Veld", "Marije Cornelissen,Sophia in't Veld", x)
    x = gsub("Franziska Katharina Brantner Marietta Giannakou Ana Gomes", "Franziska Katharina Brantner,Marietta Giannakou,Ana Gomes", x)
    x = gsub("Ana Gomes Krzysztof Lisek Arnaud Danjean Michael Gahler", "Ana Gomes,Krzysztof Lisek,Arnaud Danjean,Michael Gahler", x)
    x = gsub("Cristina Gutiérrez-Cortines Rosa Estaràs Ferragut", "Cristina Gutiérrez-Cortines,Rosa Estaràs Ferragut", x)
    x = gsub("George Sabin Cutaş Frédéric Daerden", "George Sabin Cutaş,Frédéric Daerden", x)
    x = gsub("George Sabin Cutaş Ria Oomen-Ruijten", "George Sabin Cutaş,Ria Oomen-Ruijten", x)
    x = gsub("Glenis Willmott Christel Schaldemose", "Glenis Willmott,Christel Schaldemose", x)
    x = gsub("Maria Eleni Koppa, Ioan Mircea PaşcuRoberto Gualtieri", "Maria Eleni Koppa, Ioan Mircea Paşcu,Roberto Gualtieri", x)
    x = gsub("Kartika Tamara Liotard Bart Staes", "Kartika Tamara Liotard,Bart Staes", x)
    x = gsub("Lívia Járóka Eva-Britt Svensson", "Lívia Járóka,Eva-Britt Svensson", x)
    x = gsub("Marina Yannakoudakis Andrea Češková", "Marina Yannakoudakis,Andrea Češková", x)
    x = gsub("Michèle Striffler Cecilia Wikström", "Michèle Striffler,Cecilia Wikström", x)
    x = gsub("Mojca KlevaSławomir Witold Nitras", "Mojca KlevaSławomir,Witold Nitras", x)
    x = gsub("Satu Hassi Åsa Westlund", "Satu Hassi,Åsa Westlund", x)
    x = gsub("Artur Zasada Bogdan", "Artur Zasada,Bogdan", x)
    x = gsub("Arturs Krišjānis KariĦš|Arturs Krisjanis Karins", "Artus,Krišjānis KARIŅŠ", x)
    x = gsub("Mojca KlevaSławomir", "Mojca Kleva,Sławomir", x)
    x = gsub("Michèle Rivasi Fiona Hall", "Michèle Rivasi,Fiona Hall", x)
    x = gsub("Michael Theurer Yannick Jadot", "Michael Theurer,Yannick Jadot", x)
    x = gsub("Bernd Lange Yannick Jadot", "Bernd Lange,Yannick Jadot", x)
    x = gsub("Françoise Grossetête Werner Langen", "Françoise Grossetête,Werner Langen", x)
    x = gsub("Glenis Willmott Nessa Childers", "Glenis Willmott,Nessa Childers", x)
    x = gsub("Enikı Gyıri Danuta Jazłowiecka", "Enikı Gyıri,Danuta Jazłowiecka", x)
    x = gsub("Sampo Terho Ana Gomes", "Sampo Terho,Ana Gomes", x)
    x = gsub("José Ignacio Salafranca Sánchez-Neyr, Francisco José Millán Mon", "José Ignacio SALAFRANCA SÁNCHEZ-NEYRA,Francisco José Millán Mon", x)
    
    # name spellings
    x = gsub("Agustín Díaz de Mera Gacía Consuegra", "Agustín Díaz de Mera García Consuegra", x) # missing 'r' in 'García' -- does not work
    x = gsub("Annemie Neyts--Uyttebroeck", "Annemie Neyts-Uyttebroeck", x)
    x = gsub("Anne Jensen", "Anne E. Jensen", x)
    x = gsub("Ashley Foxon", "Ashley Fox", x)
    x = gsub("Antolín Sánchez Presedos", "Antolín Sánchez Presedo", x)
    x = gsub("Arkadiusz Bratkowski", "Arkadiusz Tomasz BRATKOWSKI", x)
    x = gsub("Birgit Sipper", "Birgit Sippel", x)
    x = gsub("Bogdan Marcinkiewicz", "Bogdan Kazimierz MARCINKIEWICZ", x)
    x = gsub("Boguslaw Liberadzki", "Bogusław LIBERADZKI", x)
    x = gsub("Boguslaw Sonik", "Bogusław Sonik", x)
    x = gsub("Catherine Souille", "Catherine SOULLIE", x)
    x = gsub("Corina CreŃu", "Corina CREŢU", x)
    x = gsub("Corine Lepage", "Corinne Lepage", x)
    x = gsub("Cristian Silviu Buşoim", "Cristian Silviu BUŞOI", x)
    x = gsub("Csaba İry", "Csaba ŐRY", x)
    x = gsub("Csaba Tabajdi", "Csaba Sándor TABAJDI", x)
    x = gsub("Czeslaw Siekierski|Czesław Siekierski", "Czesław Adam SIEKIERSKI", x)
    x = gsub("Daciana Sarbu", "Daciana Octavia SÂRBU", x)
    x = gsub("Dan Jorgensen", "Dan Jørgensen", x)
    x = gsub("Laurence J.A. J. Stassen", "Laurence J.A.J. Stassen", x) # initials
    x = gsub("Edite Estrelamail.com", "Edite Estrela", x)
    x = gsub("Edward McMillan Scott", "Edward McMILLAN-SCOTT", x)
    x = gsub("Eleni Theocharus", "Eleni THEOCHAROUS", x)
    x = gsub("Elisa Ferrreira", "Elisa Ferreira", x)
    x = gsub("ElŜbieta Katarzyna Łukacijewska|ElŜbieta Łukacijewska", "Elżbieta Katarzyna ŁUKACIJEWSKA", x)
    x = gsub("Enikı Gyıri", "Enikő GYŐRI", x)
    x = gsub("Jacek Wlosowicz", "Jacek WŁOSOWICZ", x)
    x = gsub("Evelyne Evelyne Gebhardt", "Evelyne Gebhardt", x)
    x = gsub("Franziska Keller", "Ska Keller", x) # using shortened name
    x = gsub("Georgios Koumoutsakoss", "Georgios KOUMOUTSAKOS", x)
    x = gsub("Giancarlo Scotta'", "Giancarlo SCOTTÀ", x)
    x = gsub("Hans Van Baalen", "Johannes Cornelis van BAALEN", x)
    x = gsub("Helga Trüpel vv", "Helga Trüpel", x)
    x = gsub("Inês Zuber", "Inês Cristina Zuber", x)
    x = gsub("Iziaskun Bilbao Barandica", "Izaskun BILBAO BARANDICA", x)
    x = gsub("Jacky Henan", "Jacky Hénin", x)
    x = gsub("Jan Kozlowski", "Jan KOZŁOWSKI", x)
    x = gsub("Janusz Wladyslaw Zemke", "Janusz Władysław ZEMKE", x)
    x = gsub("Jaroslaw Kalinowski", "Jarosław KALINOWSKI", x)
    x = gsub("Jaroslaw Walesa", "Jarosław Leszek WAŁĘSA", x)
    x = gsub("Joanna Skrzydlewska", "Joanna Katarzyna SKRZYDLEWSKA", x)
    x = gsub("Jolanta Hibner", "Jolanta Emilia HIBNER", x)
    x = gsub("José Ignacio Samaranch Sánchez-Neyra", "José Ignacio SALAFRANCA SÁNCHEZ-NEYRA", x)
    x = gsub("Judith Merkies", "Judith A. MERKIES", x)
    x = gsub("Judith Sargebtubu", "Judith SARGENTINI", x) # strange?
    x = gsub("Jürgen Miguel Portas", "Miguel PORTAS", x)
    x = gsub("Kartika Liotard", "Kartika Tamara LIOTARD", x)
    x = gsub("Krišjānis KariĦš", "Krišjānis KARIŅŠ", x)
    x = gsub("László Tıkés", "László TŐKÉS", x)
    x = gsub("Lena Barbara Kolarska-Bobinska", "Lena KOLARSKA-BOBIŃSKA", x)
    x = gsub("Liz Lynne", "Elizabeth LYNNE", x)
    x = gsub("Luís Capoulas Santos", "Luis Manuel CAPOULAS SANTOS", x)
    x = gsub("(Luisa )?Monica Macovei", "Monica Luisa MACOVEI", x)
    x = gsub("Lydia Geringer de Oedenberg", "Lidia Joanna GERINGER de OEDENBERG", x)
    x = gsub("Ma³gorzata Handzlik", "Małgorzata HANDZLIK", x)
    x = gsub("Mairead McGuiness", "Mairead McGUINNESS", x)
    x = gsub("Malgorzata Handzlik", "Małgorzata Handzlik", x)
    x = gsub("Marcus Ferber", "Markus Ferber", x)
    x = gsub("Maria Ad Grace Carvel", "Maria Da Graça CARVALHO", x)
    x = gsub("María Paloma Muñiz De Urquiza", "María MUÑIZ DE URQUIZA", x)
    x = gsub("Marie Eleni Koppa", "Maria Eleni KOPPA", x)
    x = gsub("Marielle De Starnes", "Marielle de SARNEZ", x)
    x = gsub("Mariya Nedelcheva", "Mariya GABRIEL", x)
    x = gsub("NgocElisa Ferreira", "Elisa Ferreira", x)
    x = gsub("Pat de Cope Gallagher", "Pat the Cope GALLAGHER", x)
    x = gsub("Pawel Robert Kowal", "Paweł Robert KOWAL", x)
    x = gsub("Philip Juvin", "Philippe Juvin", x)
    x = gsub("Petru Luhan", "Petru Constantin LUHAN", x)
    x = gsub("Petra ammerevert", "Petra KAMMEREVERT", x)
    x = gsub("Paul Murphy Paul Murphy", "Paul Murphy", x)
    x = gsub("Nadezhda Mihaylova", "Nadezhda NEYNSKY", x) # using married name
    x = gsub("Miroslaw Piotrowski", "Mirosław PIOTROWSKI", x)
    x = gsub("Minodora Cliveta", "Minodora CLIVETI", x)
    x = gsub("Pilar Ayuso y Esther Herranz", "Pilar AYUSO", x)
    x = gsub("Radvil÷ Morkūnait÷-Mikul÷nien÷", "Radvilė MORKŪNAITĖ-MIKULĖNIENĖ", x)
    x = gsub("Rafał Kazimierz Trzaskowski", "Rafał TRZASKOWSKI", x)
    x = gsub("Ramon Tremors i Balcells", "Ramon TREMOSA i BALCELLS", x)
    x = gsub("Riikka Manner", "Riikka PAKARINEN", x) # using maiden name
    x = gsub("(Roberts )?Zīle", "Roberts ZĪLE", x)
    x = gsub("Romana Jordan Cizelj", "Romana JORDAN", x)
    x = gsub("RóŜa Gräfin Von Thun Und Hohenstein|RóŜa Gräfin von Thun und Hohenstein|RóŜa Thun Und Hohenstein|Roza Thun und Hohenstein", "Róża Gräfin von THUN UND HOHENSTEIN", x)
    x = gsub("Sergia Gaetano Cofferati|Sergio Coferatti", "Sergio Gaetano COFFERATI", x)
    x = gsub("Sidonia Jędrzejewska|Sidonia ElŜbieta Jędrzejewska", "Sidonia Elżbieta JĘDRZEJEWSKA", x)
    x = gsub("Silvia -Adriana łicău|Silvia-Adriana łicău|Silvia-Adriana Þicãu", "Silvia-Adriana ŢICĂU", x)
    x = gsub("Sergio Gaetano Gaetano Cofferati", "Sergio Gaetano Cofferati", x)
    x = gsub("Sophia in 't Veld", "Sophia in't Veld", x)
    x = gsub("Sven Giegold VERT", "Sven Giegold", x)
    x = gsub("Sophie Briard Auconie", "Sophie Auconie", x)
    x = gsub("(Sławomir ){0,2}(Witold )?Nitras", "Sławomir NITRAS", x)
    x = gsub("Teresa Jimenez Becerril", "Teresa JIMÉNEZ-BECERRIL BARRIO", x)
    x = gsub("Véronique Matheiu Houillon", "Véronique MATHIEU HOUILLON", x)
    x = gsub("Yannik Jadot", "Yannick Jadot", x)
    x = gsub("Zusanna Roithova", "Zuzana ROITHOVÁ", x)
    
    # special chars
    x = gsub("albert deß", "Albert DESS", x, ignore.case = TRUE)
    x = gsub("amelia andersdotte(r)?", "Amelia ANDERSDOTTER", x, ignore.case = TRUE)
    x = gsub("(j)?an březina", "Jan BŘEZINA", x, ignore.case = TRUE)
    x = gsub("ana miranda", "Ana MIRANDA DE LAGE", x, ignore.case = TRUE)
    x = gsub("andrea ceskova", "Andrea ČEŠKOVÁ", x, ignore.case = TRUE)
    x = gsub("andres perello rodriguez|andrés perello rodríguez", "Andrés PERELLÓ RODRÍGUEZ", x, ignore.case = TRUE)
    x = gsub("anna zaborska", "Anna ZÁBORSKÁ", x, ignore.case = TRUE)
    x = gsub("asa westlund", "Åsa WESTLUND", x, ignore.case = TRUE)
    x = gsub("carmen romero( lópez)?", "Carmen ROMERO LÓPEZ", x, ignore.case = TRUE)
    x = gsub("catherine greze", "Catherine GRÈZE", x, ignore.case = TRUE)
    x = gsub("christa klaß", "Christa KLASS", x, ignore.case = TRUE)
    x = gsub("cristian silviu busoi", "Cristian Silviu BUŞOI", x, ignore.case = TRUE)
    x = gsub("danuta jazłowieck(a){0,2}", "Danuta JAZŁOWIECKA", x, ignore.case = TRUE)
    x = gsub("danuta maria hubner", "Danuta Maria HÜBNER", x, ignore.case = TRUE)
    x = gsub("elena basescu", "Elena BĂSESCU", x, ignore.case = TRUE)
    x = gsub("esther herranz( garcía)?", "Esther HERRANZ GARCÍA", x, ignore.case = TRUE)
    x = gsub("ferber markus", "Markus FERBER", x, ignore.case = TRUE)
    x = gsub("francoise grossetete|francoise grossetête", "Françoise GROSSETÊTE", x, ignore.case = TRUE)
    x = gsub("frederic daerden", "Frédéric DAERDEN", x, ignore.case = TRUE)
    x = gsub("gesine meißner", "Gesine MEISSNER", x, ignore.case = TRUE)
    x = gsub("giancarlo scotta", "Giancarlo SCOTTÀ", x, ignore.case = TRUE)
    x = gsub("graham watson", "Sir Graham WATSON", x, ignore.case = TRUE)
    x = gsub("ingeborg gräßle", "Ingeborg GRÄSSLE", x, ignore.case = TRUE)
    x = gsub("iñigo méndez de vigo", "Íñigo MÉNDEZ DE VIGO", x, ignore.case = TRUE)
    x = gsub("jacek saryusz -wolski", "Jacek SARYUSZ-WOLSKI", x, ignore.case = TRUE)
    x = gsub("josefa andres barea", "Josefa ANDRÉS BAREA", x, ignore.case = TRUE)
    x = gsub("jozsef szajer", "József SZÁJER", x, ignore.case = TRUE)
    x = gsub("jürgen creutzman(n)?", "Jürgen CREUTZMANN", x, ignore.case = TRUE)
    x = gsub("jurgen klute", "Jürgen KLUTE", x, ignore.case = TRUE)
    x = gsub("justina vitkauskaite( bernard)?", "Justina VITKAUSKAITE BERNARD", x, ignore.case = TRUE)
    x = gsub("(bogdan )?kazimierz marcinkiewicz", "Bogdan Kazimierz MARCINKIEWICZ", x, ignore.case = TRUE)
    x = gsub("konrad szymanski", "Konrad SZYMAŃSKI", x, ignore.case = TRUE)
    x = gsub("laima liucija andrikien÷", "Laima Liucija ANDRIKIENĖ", x, ignore.case = TRUE)
    x = gsub("(constance )?le grip", "Constance LE GRIP", x, ignore.case = TRUE)
    x = gsub("lena kolarska-bobinska", "Lena KOLARSKA-BOBIŃSKA", x, ignore.case = TRUE)
    x = gsub("liem hoang( ngoc)?", "Liem HOANG NGOC", x, ignore.case = TRUE)
    x = gsub("luis yañez-barnuevo garcía", "Luis YÁÑEZ-BARNUEVO GARCÍA", x, ignore.case = TRUE)
    x = gsub("mairead mc guinness", "Mairead McGUINNESS", x, ignore.case = TRUE)
    x = gsub("mojca kleva( kekuš)?", "Mojca KLEVA KEKUŠ", x, ignore.case = TRUE)
    x = gsub("oldrich vlasak", "Oldřich VLASÁK", x, ignore.case = TRUE)
    x = gsub("pablo arias echeverria", "Pablo ARIAS ECHEVERRÍA", x, ignore.case = TRUE)
    x = gsub("pablo zalba bidegaín", "Pablo ZALBA BIDEGAIN", x, ignore.case = TRUE)
    x = gsub("paul rubig", "Paul RÜBIG", x, ignore.case = TRUE)
    x = gsub("pier antonio panzer(i)?", "Pier Antonio PANZERI", x, ignore.case = TRUE)
    x = gsub("pilar del castillo( vera)?", "Pilar del CASTILLO VERA", x, ignore.case = TRUE)
    x = gsub("ramona nicole manescu", "Ramona Nicole MĂNESCU", x, ignore.case = TRUE)
    x = gsub("ranner hella", "Hella RANNER", x, ignore.case = TRUE)
    x = gsub("roberts zile", "Roberts ZĪLE", x, ignore.case = TRUE)
    x = gsub("(george )?sabin cutaş", "George Sabin CUTAŞ", x, ignore.case = TRUE)
    x = gsub("(baroness )?sarah ludford", "Baroness Sarah LUDFORD", x, ignore.case = TRUE)
    x = gsub("sean kelly", "Seán KELLY", x, ignore.case = TRUE)
    x = gsub("sergio gutierrez prieto", "Sergio GUTIÉRREZ PRIETO", x, ignore.case = TRUE)
    x = gsub("silvia-adriana țicău", "Silvia-Adriana ŢICĂU", x, ignore.case = TRUE)
    x = gsub("ska keller", "Franziska KELLER", x, ignore.case = TRUE)
    x = gsub("sophia in ‘t veld|sophia in't veld", "Sophia in 't VELD", x, ignore.case = TRUE)
    x = gsub("strasser ernst", "Ernst STRASSER", x, ignore.case = TRUE)
    x = gsub("tadeusz cymanski", "Tadeusz CYMAŃSKI", x, ignore.case = TRUE)
    x = gsub("tamas deutsch", "Tamás DEUTSCH", x, ignore.case = TRUE)
    x = gsub("tokia( saïfi)?", "Tokia SAÏFI", x, ignore.case = TRUE)
    x = gsub("tomasz piotr poreba", "Tomasz Piotr PORĘBA", x, ignore.case = TRUE)
    x = gsub("(sebastian )?valentin bodu", "Sebastian Valentin BODU", x, ignore.case = TRUE)
    x = gsub("vasilica viorica dancila", "Vasilica Viorica DĂNCILĂ", x, ignore.case = TRUE)
    x = gsub("veronica lope fontagné", "Verónica LOPE FONTAGNÉ", x, ignore.case = TRUE)
    x = gsub("(veronique |véronique )?mathieu( houillon)?( grosch)?", "Véronique MATHIEU HOUILLON", x, ignore.case = TRUE)
    x = gsub("(alejo )?vidal-quadras", "Alejo VIDAL-QUADRAS", x, ignore.case = TRUE)
    x = gsub("vilija blinkevičiūt÷", "Vilija BLINKEVIČIŪTĖ", x, ignore.case = TRUE)
    x = gsub("vilja savisaar(-toomast)?", "Vilja SAVISAAR-TOOMAST", x, ignore.case = TRUE)
    x = gsub("ville itala", "Ville ITÄLÄ", x, ignore.case = TRUE)
    # x = gsub("sławomir", "", x, ignore.case = TRUE)
    
    return(x)
    
  }
  
  data$authors = fix(data$authors)
  
  noise = c("", "ECR", "Artus", "Agustín Díaz de Mera Gacía Consuegra", "Bogdan", "Sławomir")
  
  uniq = scrubber(unlist(strsplit(data$authors, ",")))
  uniq = sort(unique(tolower(uniq[ !uniq %in% noise ])))
  uniq = uniq[ !uniq %in% tolower(meps$name) ]
  
  if(length(uniq)) {
    
    cat("\nThere are unrecognized sponsors:\n")
    print(uniq)
    
  }
  
}

save(data, meps, nfo, file = "amdts.rda")

# kthxbye
