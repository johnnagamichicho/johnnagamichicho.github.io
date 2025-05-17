#!/usr/local/bin/perl -- -*- C -*-
#
#  Perl script to tally SPAM Haiku votes and return a sorted summary.
#  
#  The Screamin' of Phil Erickson  11/1/95
#    updated 5/2/96 for the third vote (JC)
#

# Global variables.

$version = 2.0;
$datestamp = "May 2, 1996";
$votetally_file = "/home/cougar/alec/httpd_1.3/htdocs/vote_spam-tally";

# Associative arrays for lookup of days of week and months of the year.
%wdayname = (1,'Sun',2,'Mon',3,'Tue',4,'Wed',5,'Thu',6,'Fri',7,'Sat');
%monname = (1,'Jan',2,'Feb',3,'Mar',4,'Apr',5,'May',6,'Jun',
	    7,'Jul',8,'Aug',9,'Sep',10,'Oct',11,'Nov',12,'Dec');
%dstname = (1,'PST',2,'PDT');

# Associative arrays for lookup of top 30 haiku text.
%topfifty = 
(1,'Cop beats up migrants<br>Heading for "jobs" at Hormel.<br>Meat tenderizer.<p>',
2,'Make haiku on SPAM?<br>What pretention!  Forget it.<br>Leave it to the prose.<p>',
3,'Definition of<br>irony: excess SPAM means<br>vegetative state.<p>',
4,'SPAM treat: smart p&acirc;t&eacute;,<br>or meat parts, or ma\'s pet rat;<br>spells and smells the same.<p>',
5,'If Schr&ouml;dinger\'s cat<br>eats the SPAM, uncertainty<br>is out the door: dead.<p>',
6,'Republican SPAM:<br>It\'s the same old pork in a<br>fancier new can.<p>',
7,'Greasy tin, French bread<br>on a cracked, plastic table:<br>A poor man\'s p&acirc;t&eacute;.<p>',
8,'After scrutiny,<br>methinks it is doggie food.<br>I eat on all fours.<p>',
9,'Cheeks pink as primrose,<br>SPAM-sculpted.  Sweetly dimpling,<br>Pig-malion smiles.<p>',
10,'Taco Bell comes out<br>with new SPAM chimichangas.<br>Run from the border!<p>',
11,'Queasy, greasy SPAM<br>Slithers without propulsion<br>Across a white plate.<p>',
12,'Born in World War Two.<br>Hogs marching off to battle.<br>Dressed in tin armor.<p>',
13,'Grown in the French hills<br>Fine Spamernet sauvignon<br>You can taste the feet<p>',
14,'In Shakespeare\'s SPAMlet:<br>Shouts at Ophelia, "Get thee<br>to a cannery."<p>',
15,'Acronym him, plebs.<br>SPicy hAM, Mr. Nobel!<br>SPAM, by Hormel, Inc.<p>',
16,'At the abbatoir<br>Scythes and grinders groan.  Outside<br>Hormel\'s barrow waits.<p>',
17,'Is putting SPAM on<br>The engendered feces list<br>Scatological?<p>',
18,'New brand: Chia SPAM.<br>Meat <em>and</em> greens in every bite.<br>Hormel, we\'d buy it!<p>',
19,'Old retired jocks to<br>star in ads for new SPAM Lite.<br>"Tastes filling!"  "Less great!"<p>',
20,'Churchill on SPAM: "A<br>riddle wrapped in a myst\'ry<br>wrapped in some pink gel.".<p>',
21,'<em>1984</em>:<br>"Slavery is freedom" "War<br>is peace" "SPAM is food"<p>',
22,'When I was a kid<br>Mom would make SPAM casserole.<br>Now she denies it.<p>',
23,'O Terrible SPAM!<br>You\'re not a carcinogen.<br>You\'re cancer itself.<p>',
24,'Some Pork Art, Maybe?<br>Such Perfect Alien Meat!<br>Square, Pink, And Mottled.<p>',
25,'SPAM in Seattle<br>Rain-soaked, white bread like death glue<br>Mountains wish to move"<p>',
26,'Patio slime trails<br>Are not from snails but anxious<br>SPAMs seeking escape.<p>',
27,'New fundamental<br>particle found in pig snouts.<br>It\'s the SPARK (SPiced quARK).<p>',
28,'Evita eats a<br>slab of SPAM, sings "Don\'t Cry For<br>Me, Minnesota."<p>',
29,'Myrrh, frankincense, and<br>SPAM: the gifts of two wise men<br>and one complete fool.<p>',
30,'O\'er black bubbling vat,<br>Snout, ears, feet, and fat.  This, that.<br>Witches cackle, "SPAM!"<p>');

# Begin code

# Construct date and time stamp for this request
$timenow = time;
($secnow,$minnow,$hournow,$mdaynow,$monnow,$yearnow,
   $wdaynow,$ydaynow,$isdstnow) =
    localtime($timenow);	# ending time
$fulldatenow = sprintf("%s %s %d %02d:%02d:%02d %s %d\n",
		       $wdayname{$wdaynow+1}, $monname{$monnow+1},
		       $mdaynow, $hournow, $minnow, $secnow,
		       $dstname{$isdstnow+1}, $yearnow+1900);

# zero out the vote tabulation arrays

for ($i = 0; $i <= 30; $i++) {
    $votetab{$i} = 0;
}

# Suck in the regular vote tally file, tallying up votes as we go.

open(REGFILE, $votetally_file);

while (<REGFILE>) {
    ($votes, $voter_name, $voter_email, $voter_host, $voter_addr,
     $junk1, $junk2) = split(/:/);
    @votearray = split(/,/, $votes);
    for ($i = 0; $i <= $#votearray; $i++) {
	$haiku_number = $votearray[$i];
	$votetab{$haiku_number} = $votetab{$haiku_number} + 1;
    }
}
close(REGFILE);

# reverse array so that values are keys and vice versa
while (($key,$value) = each(%votetab)) {
    $oldval = $votereverse{$value};
    if (length($oldval) == 0) {
	$votereverse{$value} = $key;
    }
    else {
	$votereverse{$value} = $votereverse{$value}.",".$key;
    }				       
}

# Calculate total vote counts

$vote_total = 0;
while (($key,$value) = each(%votetab)) {
    $vote_total = $vote_total + $value;
}
# Print a nice HTML page with the summary.

print sprintf("%s",&PrintHeader);
print sprintf("<HTML> <HEAD> <TITLE> SPAM Haiku Vote Tally: $fulldatenow </TITLE></HEAD>\n");
print sprintf("<BODY> <H1> SPAM Haiku Vote Tally: <br> $fulldatenow </H1>\n");
print sprintf("<HR> <H2> Total Top 30 Votes Cast: ".$vote_total." </H2>\n");

print sprintf("<HR> <H2> Top 30 SPAM Haiku Vote Tally: </H2> <HR>\n");
foreach $key (sort {$b <=> $a} (keys %votereverse)) {
    @ya = sort {$a <=> $b} split(/,/, $votereverse{$key});
    if ($key != 0) {
	print sprintf("<H3>Votes: %3d</H3>",$key);
	for ($i = 0; $i <= $#ya; $i++) {
	    print $topfifty{$ya[$i]};
	    print "<P>";
	}
	print sprintf("\n");
    }
}

&SendSignature;

# That's all!
exit;

###########################################################################
#  User subroutines
###########################################################################

sub SendSignature {
  print sprintf("<HR> Vote tally form last updated: %s <P>",$datestamp);
  print sprintf('<ADDRESS> <A HREF="http://www.haystack.edu/~pje"> Screamin Phil Erickson </A>, <A HREF="mailto:pje@hyperion.haystack.edu"> pje@hyperion.haystack.edu </A> </ADDRESS>');
  print sprintf("</BODY> </HTML>\n");
}
# PrintHeader
# Returns the magic line which tells WWW that we're an HTML document

sub PrintHeader {
  return "Content-type: text/html\n\n";
}

###########################################################################




