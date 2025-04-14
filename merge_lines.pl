#!/bin/perl

$#ARGV!=1 and die "Usage $0 <file1> <file2>\n";
while ($#ARGV>=0)
{
    $f=shift @ARGV;
    print "$f\n";
}
