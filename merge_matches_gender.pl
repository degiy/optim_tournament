#!/bin/perl

$i=1;

$ml=`ls -1 m_u*.csv`;
@ms=split /\n/,$ml;
for $m (@ms)
{
    $gender='?';
    $gender='m' if $m=~/^m_u[0-9]*m/;
    $gender='f' if $m=~/^m_u[0-9]*f/;
    die "genre inconnu pour $m\n" if $gender eq '?';
    #print "$m est $gender\n";
    open F,$m;
    while(<F>)
    {
        ($id,$e1,$e2,$r)=split /;/,$_;
        print "$i;${gender}_${e1};${gender}_${e2};\n";
        $i++;
    }
    close F;
}
