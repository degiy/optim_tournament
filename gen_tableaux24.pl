#!/bin/perl

open(F,"tableau.csv");
open(F2,">tableau2.csv");
open(F4,">tableau4.csv");

$l=<F>;
printf F2 $l;
printf F4 $l;

while(<F>)
{
    print F2 $_;
    print F4 $_;
    ($id)=$_=~/^([^;]*);/;
    s/[^;]//g;
    print F2 $_,"\n";
    print F4 $_,"\n";
    print F4 $_,"\n";
    print F4 $_,"\n";
}
