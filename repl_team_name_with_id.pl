#!/bin/perl

$#ARGV!=2 and die "Usage : $0 <matches.csv> <team_ids.csv> <matches_ids.csv>\n";

($fnmn,$fnti,$fnmi)=@ARGV;

open FMN,$fnmn or die "no $fnmn file to read from";
open FTI,">$fnti" or die;
open FMI,">$fnmi" or die;

$n=0;

while(<FMN>)
{
    ($id,$t1,$t2,$r)=split /;/,$_;
    print "$t1 $t2\n";
    $i1=&repl($t1);
    $i2=&repl($t2);
    print FMI "$i1 $i2\n";
}

sub repl
{
    $t=pop @_;
    unless (exists($ht{$t}))
    {
        print FTI "$n;$t;\n";
        $ht{$t}=$n++;
    }
    return $ht{$t};
}
close FMN;
close FTI;
close FMI;
