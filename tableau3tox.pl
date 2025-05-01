#!/bin/perl
#
# convert tableau3 (csv exported execl tab) to web site and exchange file (used between excel and site)

use integer;

# format of exchange file : slot_time; court ; category ; pool ; phase (if any); team 1; team 2; score t1; score t2;

# tableau format is :
#          ; court1; court2;....;last court
# slot_time; team1 - team2 (pool); team1 - teams2 (pool/pĥase);.... as many as courts availlage/busy;
#          ; sc tm1              ; sc tm1           ;...
#          ;              sc tm2 ;         sc tm2   ;...
# slot_time ...

$l=<>;
chomp $l;
@court_names=split /;/,$l;
shift @court_names;

$i=0;
while(<>)
{
    chomp $_;
    $i3=$i%3;
    if ($i3==0)
    {
        # first line (the one with slot and teams)
        @t1=split /;/,$_;
        $slot=shift @t1;
    }
    elsif ($i3==1)
    {
        # second line (scores teams 1)
        @t2=split /;/,$_;
        shift @t2;
    }
    else
    {
        # third line (scores teams 2)
        @t3=split /;/,$_;
        shift @t3;
        # the 3 lines full process
        for($x=0;$x<=$#t1;$x++)
        {
            $cell=$t1[$x];
            next unless $cell=~/ - .*\(.*\)/;
            #print $court_names[$i]," $cell\n";
            ($t1,$t2,$p)=$cell=~/^(.*) - (.*) \((.*)\)$/;
            if ($p=~/\//)
            {
                # phase
                ($cat,$pool,$phase)=$p=~/^(....)(.*)\/(.*)$/;
            }
            else
            {
                ($cat,$pool)=$p=~/^(.*i?)(.)$/;
                $phase='';
            }
            $sc1=$t2[$x];
            $sc2=$t3[$x];
            $court=$court_names[$x];
            print "$slot;$court;$cat;$pool;$phase;$t1;$t2;$sc1;$sc2;\n"
        }
    }
    $i++
}
