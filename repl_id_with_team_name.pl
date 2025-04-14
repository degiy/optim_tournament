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
        ($a,$b)=split /-/,$e;
        &repl($a);
        $ta=$team;
        $pa=$poule;
        &repl($b);
        $tb=$team;
        $pb=$poule;
        @order = sort ($ta,$tb);
        ($ta,$tb)=@order;
        if ($pa eq $pb)
        {
            printf FMN "$ta - $tb ($pa);"
        }
        else
        {
            my $common_prefix = "";
            for (my $i = 0; $i < length($pa) && $i < length($pb); $i++)
            {
                if (substr($pa, $i, 1) eq substr($pb, $i, 1))
                {
                    $common_prefix .= substr($pa, $i, 1);
                }
                else
                {
                    last;
                }
            }
            if ($common_prefix)
              { printf FMN "$ta - $tb ($common_prefix);"; }
            else
              { printf FMN "$ta - $tb;";}
        }
    }
    print FMN "\n";
    $n++;
}
close FMI;
close FMN;

sub repl
{
    my ($t)=@_;
    $tp=$tab[$t];
    ($team,$poule)=split /_/,$tp;
}
