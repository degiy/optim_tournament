#!/bin/perl

$#ARGV!=2 and die "Usage : $0 <matches_with_team_id.csv> <team_ids.csv> <matches_with_team_names.csv>\n";

($fnmi,$fnti,$fnmn)=@ARGV;

open FMI,"$fnmi" or die;
open FTI,"$fnti" or die;
open FMN,">$fnmn" or die;

$n=0;

print "[ team_id team_name ]\n";
while(<FTI>)
{
    ($id,$t,$r)=split /;/,$_;
    print "$id $t\n";
    $tab[$id]=$t;
}
close FTI;

while(<FMI>)
{
    @l=split /;/,$_;
    $slot=shift @l;
    printf FMN "$n;";
    for $e (@l)
    {
        unless ($e=~/-/) { printf FMN ";"; next; }
        ($ta,$tb)=split /-/,$e;
        @order = sort ($ta,$tb);
        ($ta,$tb)=@order;
	$a=$tab[$ta];
	$b=$tab[$tb];
        printf FMN "$a - $b;";
    }
    print FMN "\n";
    $n++;
}
close FMI;
close FMN;

