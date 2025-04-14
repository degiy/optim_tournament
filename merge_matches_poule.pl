#!/bin/perl

$i=1;

$ml=`ls -1 m_u*.csv`;
@ms=split /\n/,$ml;
for $m (@ms)
{
    $poule=$m;
    $poule=~s/^m_//;
    $poule=~s/.csv$//;
    open F,$m;
    while(<F>)
    {
        ($id,$e1,$e2,$r)=split /;/,$_;
        print "$i;${e1}_${poule};${e2}_${poule};\n";
        $i++;
    }
    close F;
}
