#!/usr/bin/perl

# script de creation des différentes matches d'une poule
# si on ne veut pas de match entre equipes du meme club
$pmclub=defined $ENV{PAS_DE_MATCH_ENTRE_EQUIPES_DU_MEME_CLUB};

$#ARGV==-1 and die "$0 <p_poule.csv>\n";
$file=$ARGV[0];

$poule=$file;
$poule=~s/\.csv$//;
$poule=~s/^p_//;

open F,$file or die "impossible d'ouvrir $file\n";
while (<F>)
{
    next unless /[a-z]/;
    next if /#/;
    chomp $_;
    s/;.*$//;
    push @eq,$_;
}
close F;

open F,">m_$poule.csv";

@eqs=sort @eq;
$nb=$#eq+1;
$c=1;
for ($i=0;$i<$nb;$i++)
{
    for ($j=$i+1;$j<$nb;$j++)
    {
	$ea=$eqs[$i];
	$eb=$eqs[$j];
	if ($pmclub)
	{
	    $cea=$ea;
	    $ceb=$eb;
	    $cea=~s/[0-9]*//g;
	    $ceb=~s/[0-9]*//g;
	    next if $cea eq $ceb;
	}
	print F $c++,';',$ea,';',$eb,';',"\n";
    }
}
close F;

