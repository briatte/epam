<?php

  if(count($_GET) > 0) {
    if(!empty($_GET['co'])) $co = basename($_GET['co']);
  }

  if(!isset($co)) $co = "CULT";
  if($co == '0') $co = "CULT";
  
  $array = array(
    "AFCO" => "Constitutional Affairs",
    "AFET" => "Foreign Affairs",
    "AGRI" => "Agriculture and Rural Development",
    "BUDG" => "Budgets",
    "CONT" => "Budgetary Control",
    "CRIM" => "Organised crime, corruption and money laundering",
    "CRIS" => "Financial, Economic and Social Crisis",
    "CULT" => "Culture and Education",
    "DEVE" => "Development",
    "DROI" => "Human Rights",
    "ECON" => "Economic and Monetary Affairs",
    "EMPL" => "Employment and Social Affairs",
    "ENVI" => "Environment, Public Health and Food Safety",
    "FEMM" => "Women's Rights and Gender Equality",
    "IMCO" => "Internal Market and Consumer Protection",
    "INTA" => "International Trade",
    "ITRE" => "Industry, Research and Energy",
    "JURI" => "Legal Affairs",
    "LIBE" => "Civil Liberties, Justice and Home Affairs",
    "PECH" => "Fisheries",
    "PETI" => "Petitions",
    "REGI" => "Regional Development",
    "SEDE" => "Security and Defence",
    "SURE" => "Policy Challenges",
    "TRAN" => "Transport and Tourism");
  $class = array(
    "AFCO" => "",
    "AFET" => "",
    "AGRI" => "",
    "BUDG" => "",
    "CONT" => "",
    "CRIM" => "",
    "CRIS" => "",
    "CULT" => "",
    "DEVE" => "",
    "DROI" => "",
    "ECON" => "",
    "EMPL" => "",
    "ENVI" => "",
    "FEMM" => "",
    "IMCO" => "",
    "INTA" => "",
    "ITRE" => "",
    "JURI" => "",
    "LIBE" => "",
    "PECH" => "",
    "PETI" => "",
    "REGI" => "",
    "SEDE" => "",
    "SURE" => "",
    "TRAN" => "");
  $class[$co] = "here";

  $caption='<p>This graph shows Members of the European Parliament (MEPs) during the 7th term (2009-2014). A link between two MEPs indicates that they have cosponsored at least one committee amendment. See <a href="plots.html" target="_blank">this page</a> for more plots.</p>';
  // $caption = $caption . ' Their size is proportional to their <a href="http://toreopsahl.com/tnet/weighted-networks/node-centrality/">weighted degree</a>.</p>'
  
?>

<!doctype html>
<html>
<head>
  <title><?php
    echo "Cosponsorship networks in the European Parliament: ";
    echo $co;
    ?>
  </title>
  <meta charset="utf-8">
  <link href="http://fonts.googleapis.com/css?family=Source+Sans+Pro:400,600" rel="stylesheet" type="text/css" />
  <link href="assets/styles.css" rel="stylesheet" type="text/css" />
  <link rel="stylesheet" href="font-awesome-4.0.3/css/font-awesome.min.css">
  <style type="text/css" media="screen">
  html, body {
    font: 24px/150% "Source Sans Pro", sans-serif;
    background-image: url("assets/hemicycle.png");
    color: #fff;
    margin: 0;
    padding:0;
    width: 100%;
    height: 100%;
  }
  </style>
  <!--[if lt IE 8]>
    <link rel="stylesheet" href="assets/stylesheets/social_foundicons_ie7.css">
  <![endif]-->
</head>
<body>

<div id="sigma-container">
  <div id="controls" class="bg">
    <h1>european parliament</h1>    
    <h2><a target='_blank' href='<?php echo "http://parltrack.euwiki.org/committee/" . $co; ?>' title='Go to Parltrack committee page (new window)'><?php echo $array[$co]; ?></a></h2>

    <p>
      Committee&nbsp;&nbsp;
      <a href="?co=AFCO" title='<?php echo $array['AFCO']; ?>' class='<?php echo $class["AFCO"]; ?>'>AFCO</a>&nbsp;&nbsp;
      <a href="?co=AFET" title='<?php echo $array['AFET']; ?>'  class='<?php echo $class["AFET"]; ?>'>AFET</a>&nbsp;&nbsp;
      <a href="?co=AGRI" title='<?php echo $array['AGRI']; ?>'  class='<?php echo $class["AGRI"]; ?>'>AGRI</a>&nbsp;&nbsp;
      <a href="?co=BUDG" title='<?php echo $array['BUDG']; ?>'  class='<?php echo $class["BUDG"]; ?>'>BUDG</a>&nbsp;&nbsp;
      <a href="?co=CONT" title='<?php echo $array['CONT']; ?>'  class='<?php echo $class["CONT"]; ?>'>CONT</a>&nbsp;&nbsp;
      <!-- <a href="?co=CRIM" title='<?php echo $array['CRIM']; ?>'  class='<?php echo $class["CRIM"]; ?>'>CRIM</a>&nbsp;&nbsp; -->
      <a href="?co=CRIS" title='<?php echo $array['CRIS']; ?>'  class='<?php echo $class["CRIS"]; ?>'>CRIS</a>&nbsp;&nbsp;
      <a href="?co=CULT" title='<?php echo $array['CULT']; ?>'  class='<?php echo $class["CULT"]; ?>'>CULT</a>&nbsp;&nbsp;
      <a href="?co=DEVE" title='<?php echo $array['DEVE']; ?>'  class='<?php echo $class["DEVE"]; ?>'>DEVE</a>&nbsp;&nbsp;
      <!-- <a href="?co=DROI" title='<?php echo $array['DROI']; ?>'  class='<?php echo $class["DROI"]; ?>'>DROI</a>&nbsp;&nbsp; -->
      <a href="?co=ECON" title='<?php echo $array['ECON']; ?>'  class='<?php echo $class["ECON"]; ?>'>ECON</a>&nbsp;&nbsp;
      <a href="?co=EMPL" title='<?php echo $array['EMPL']; ?>'  class='<?php echo $class["EMPL"]; ?>'>EMPL</a>&nbsp;&nbsp;
      <a href="?co=ENVI" title='<?php echo $array['ENVI']; ?>'  class='<?php echo $class["ENVI"]; ?>'>ENVI</a>&nbsp;&nbsp;
      <a href="?co=FEMM" title='<?php echo $array['FEMM']; ?>'  class='<?php echo $class["FEMM"]; ?>'>FEMM</a>&nbsp;&nbsp;
      <a href="?co=IMCO" title='<?php echo $array['IMCO']; ?>'  class='<?php echo $class["IMCO"]; ?>'>IMCO</a>&nbsp;&nbsp;
      <a href="?co=INTA" title='<?php echo $array['INTA']; ?>'  class='<?php echo $class["INTA"]; ?>'>INTA</a>&nbsp;&nbsp;
      <a href="?co=ITRE" title='<?php echo $array['ITRE']; ?>'  class='<?php echo $class["ITRE"]; ?>'>ITRE</a>&nbsp;&nbsp;
      <a href="?co=JURI" title='<?php echo $array['JURI']; ?>'  class='<?php echo $class["JURI"]; ?>'>JURI</a>&nbsp;&nbsp;
      <a href="?co=LIBE" title='<?php echo $array['LIBE']; ?>'  class='<?php echo $class["LIBE"]; ?>'>LIBE</a>&nbsp;&nbsp;
      <a href="?co=PECH" title='<?php echo $array['PECH']; ?>'  class='<?php echo $class["PECH"]; ?>'>PECH</a>&nbsp;&nbsp;
      <a href="?co=PETI" title='<?php echo $array['PETI']; ?>'  class='<?php echo $class["PETI"]; ?>'>PETI</a>&nbsp;&nbsp;
      <a href="?co=REGI" title='<?php echo $array['REGI']; ?>'  class='<?php echo $class["REGI"]; ?>'>REGI</a>&nbsp;&nbsp;
      <!-- <a href="?co=SEDE" title='<?php echo $array['SEDE']; ?>'  class='<?php echo $class["SEDE"]; ?>'>SEDE</a>&nbsp;&nbsp; -->
      <a href="?co=SURE" title='<?php echo $array['SURE']; ?>'  class='<?php echo $class["SURE"]; ?>'>SURE</a>&nbsp;&nbsp;
      <a href="?co=TRAN" title='<?php echo $array['TRAN']; ?>'  class='<?php echo $class["TRAN"]; ?>'>TRAN</a>
    </p>
    <p>
      Click a node to show its ego network. Double click to zoom in or out.<br>
      Hide&nbsp;
      <label title="Do not draw network ties (vertex edges).">
        <input type="checkbox" id="showEdges" />
        Edges
      </label>
      &nbsp;
      <label title="Do not add labels to nodes (MP names) when zooming in.">
        <input type="checkbox" id="showLabels" />
        Labels
      </label>
      &nbsp;
      <label title="Draw only ties formed among frequent cosponsors (edge weight > 0.5).">
        <input type="checkbox" id="showSparse" />
        Weak ties
      </label>
      <br>
      Download&nbsp;&nbsp;<i class="fa fa-file-o"></i>&nbsp;&nbsp;<a href="com_<?php echo $co; ?>.gexf" title="Download this graph (GEXF, readable with Gephi)">network</a>&nbsp;&nbsp;<i class="fa fa-files-o"></i>&nbsp;&nbsp;<a href="all.zip" title="Download all graphs (GEXF, readable with Gephi)">full series</a></p>
    <p><a href="#" id="recenter-camera" class="button" title="Reset graph to initial zoom position.">reset zoom</a>&nbsp;&nbsp;<a href="#" id="toggle-layout" class="button" title="Animate with Force Atlas 2.">Animate</a> <small><a href="https://gephi.org/2011/forceatlas2-the-new-version-of-our-home-brew-layout/" title="Details on the Force Atlas 2 algorithm."><i class="fa fa-info-circle"></i></a></small></p>
    <p><a href="http://twitter.com/share?text=Cosponsorship%20networks%20in%20the%20European%20Parliament,%20by%20@phnk:&amp;url=<?php echo 'http://' . $_SERVER["SERVER_NAME"].$_SERVER["REQUEST_URI"]; ?>" class="button" title="Share this page on Twitter."><i class="fa fa-twitter"></i> Tweet</a>&nbsp;&nbsp;<a href="https://github.com/briatte/epam" class="button" title="Get the code and data from GitHub."><i class="fa fa-github"></i> Code</a></p>
    <footer>
        <p>Amendments data from <a href="http://parltrack.euwiki.org/dumps/" title="Index of Parltrack /dumps/">Parltrack</a> (May 16, 2014).<br />
          Background photo by <a href="https://commons.wikimedia.org/wiki/File:EP_Strasbourg_hemicycle_l-gal.jpg">JLogan</a> (Wikimedia).</p>
    </footer>
    <div id="graph-container"></div>
  </div>
  <div id="caption" class="bg">
    <?php echo $caption; ?>
  </div>

</div>

<script src="sigmajs-release-v1.0.2/sigma.min.js"></script>
<script src="sigmajs-release-v1.0.2/plugins/sigma.parsers.gexf.min.js"></script>
<script src="sigmajs-release-v1.0.2/plugins/sigma.layout.forceAtlas2.min.js"></script>

<script>
function decimalAdjust(type, value, exp) {
	// If the exp is undefined or zero...
	if (typeof exp === 'undefined' || +exp === 0) {
		return Math[type](value);
	}
	value = +value;
	exp = +exp;
	// If the value is not a number or the exp is not an integer...
	if (isNaN(value) || !(typeof exp === 'number' && exp % 1 === 0)) {
		return NaN;
	}
	// Shift
	value = value.toString().split('e');
	value = Math[type](+(value[0] + 'e' + (value[1] ? (+value[1] - exp) : -exp)));
	// Shift back
	value = value.toString().split('e');
	return +(value[0] + 'e' + (value[1] ? (+value[1] + exp) : exp));
}

// Decimal round
if (!Math.round10) {
	Math.round10 = function(value, exp) {
		return decimalAdjust('round', value, exp);
	};
}

// Add a method to the graph model that returns an
// object with every neighbors of a node inside:
sigma.classes.graph.addMethod('neighbors', function(nodeId) {
  var k,
      neighbors = {},
      index = this.allNeighborsIndex[nodeId] || {};

  for (k in index)
    neighbors[k] = this.nodesIndex[k];

  return neighbors;
});

sigma.classes.graph.addMethod('getNeighborsCount', function(nodeId) {
  return this.allNeighborsCount[nodeId];
});

sigma.parsers.gexf(
  document.title.replace("Cosponsorship networks in the European Parliament: ", "com_")+'.gexf',
  { // Here is the ID of the DOM element that
    // will contain the graph:
    container: 'sigma-container'
  },
  function(s) {
    
    console.log(document.title.replace("Cosponsorship networks in the European Parliament: ", "com_")+'.gexf')
      
    // We first need to save the original colors of our
    // nodes and edges, like this:
    s.graph.nodes().forEach(function(n) {
      n.originalColor = n.color;
      n.originalX = n.x;
      n.originalY = n.y;
    });
    s.graph.edges().forEach(function(e) {
      e.originalColor = e.color;
      e.type = 'arrow';
    });

    // When a node is clicked, we check for each node
    // if it is a neighbor of the clicked one. If not,
    // we set its color as grey, and else, it takes its
    // original color.
    // We do the same for the edges, and we only keep
    // edges that have both extremities colored.
    s.bind('clickNode', function(e) {
      var nodeId = e.data.node.id,
          toKeep = s.graph.neighbors(nodeId);
      toKeep[nodeId] = e.data.node;

      s.graph.nodes().forEach(function(n) {
        if (toKeep[n.id])
          n.color = n.originalColor;
        else
          n.color = '#555';
      });

      s.graph.edges().forEach(function(e) {
        if (toKeep[e.source] && toKeep[e.target])
          e.color = e.originalColor;
        else
          e.color = '#333';
      });

      // node color
      var rgba = e.data.node.color;

      profile = "<a href='http://www.europarl.europa.eu" + e.data.node.attributes['link'] + "' title='Go to EP profile (new window)' target='_blank'>";
      parltrack = "<a href='http://parltrack.euwiki.org/mep/" + e.data.node.attributes['label'] + "' title='Go to Parltrack profile (new window)' target='_blank'";
      
      document.getElementById('caption').innerHTML = '<p style="background:' + rgba + ';">' + profile + '<img src="http://www.europarl.europa.eu/mepphoto/' + e.data.node.attributes['uid'] + '.jpg" alt="no photo available" /></a> You selected <span style="text-transform:uppercase;">' + profile + e.data.node.label + '</a></span> <span style="color:' + rgba.replace('0.3)', '1)') + ';">(' + e.data.node.attributes['group'] + ')</span>, an MEP who had <span title="unweighted Freeman degree">' + s.graph.getNeighborsCount(nodeId) + ' cosponsors</span> in this committee over the entire term.<br /><a href="http://www.europarl.europa.eu' + e.data.node.attributes['link'] + '" class="button"" style="width: 125px; margin:1.25em 0; float:none;" title="Go to EP profile (new window)" target="_blank">EP homepage</a>&nbsp;&nbsp; ' + parltrack + '" class="button" style="width: 175px; margin:1.25em 0; float:none;" target="_blank">Parltrack profile</a></p>';
      
      // Since the data has been modified, we need to
      // call the refresh method to make the colors
      // update effective.
      s.refresh();
    });

    // When the stage is clicked, we just color each
    // node and edge with its original color.
    s.bind('clickStage', function(e) {
      s.graph.nodes().forEach(function(n) {
        n.color = n.originalColor;
      });

      s.graph.edges().forEach(function(e) {
        e.color = e.originalColor;
      });

      // Same as in the previous event:
      s.refresh();
      
      document.getElementById('caption').innerHTML = '<?php echo $caption; ?>';
    });
    
    s.settings({
      defaultEdgeColor: '#555',
      edgeColor: 'source',
      minNodeSize: 2,
      maxNodeSize: 6,
      defaultLabelColor: '#fff',
      defaultLabelSize: 18,
      font: "source sans pro",
      minEdgeSize: .3,
      maxEdgeSize: .9,
      labelHoverBGColor: 'node',
      defaultLabelHoverColor: '#fff',
      labelHoverShadow: 'node'
    });
    
    // Refresh the graph to see the changes:
    s.refresh();
    
    // hide edges
    //
    document.getElementById('showEdges').addEventListener('change',
    function(e){
      if (e.target.checked) {
        s.settings({
          drawEdges: false
        });
      } else {
        s.settings({
          drawEdges: true
        });
      }
      s.refresh();
    });
    
    // hide labels
    //
    document.getElementById('showLabels').addEventListener('change', 
    function(e){
      if (e.target.checked) {
        s.settings({
          drawLabels: false
        });
      } else {
        s.settings({
          drawLabels: true
        });
      }
      s.refresh();
    }); 
    
    // hide sparse ties
    //
    document.getElementById('showSparse').addEventListener('change', 
    function(e){
      if (e.target.checked) {
        s.graph.edges().forEach(function(e) {
          // use upper quartile marker
          if(e.weight > 1)
            e.color = 'rgba(66,66,66,0)';
        });
        s.settings({
          minEdgeSize: .1,
          maxEdgeSize: 3
        });
      } else {
        s.graph.edges().forEach(function(e) {
          e.color = e.originalColor;
        });
        s.settings({
          minEdgeSize: .5,
          maxEdgeSize: 1,
        });
      }
      s.refresh();
    }); 
        
    // force atlas
    //
    document.getElementById('toggle-layout').addEventListener('click', 
    function() {
      if ((s.forceatlas2 || {}).isRunning) {
        s.stopForceAtlas2();
        document.getElementById('toggle-layout').innerHTML = 'Animate';
      } else {
        s.startForceAtlas2();
        document.getElementById('toggle-layout').innerHTML = 'Stop';
      }
    });
    
    // reset zoom
    document.getElementById('recenter-camera').addEventListener('click', 
    function() {
      s.cameras[0].goTo({
                x: 0,
                y: 0,
                angle: 0,
                ratio: 1
              });
    });
    
  }
);
</script>

</body>
</html>
