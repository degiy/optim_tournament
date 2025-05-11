#!/bin/perl
#
# convert tableau to web site and exchange file (used between excel and site)

use integer;

# we start at 10:00 with slots lasting 0:20
$mins=10*60;
$m_duration=20;
@court_names=qw(ext1 ext2 ext3 ext4);

# format of exchange file : slot_time; court ; category ; pool ; phase (if any); team 1; team 2; score t1; score t2;

# tableau format is : slot_ndx; team1 - team2 (pool); team1 - teams2 (pool/pĥase);.... as many as courts availlage/busy;
while ($#ARGV>=0)
{
    if ($ARGV[0] eq '-s')
    {
        shift @ARGV;
        $st=shift @ARGV;
        ($hh,$mm)=split /:/,$st;
        $mins=$hh*60+$mm;
    }
    $fname=shift @ARGV;
}

$i=0;
open F,$fname;
while(<F>)
{
    chomp $_;
    @l=split /;/,$_;
    $slndx=shift @l;
    if (($i==0)&&($slndx eq ''))
    {
        # courts names provided, so use them
        @court_names=();
        for $c (@l)
        {
            push @court_names,$c unless $c eq '';
        }
    }
    next unless $slndx=~/^[0-9]/;
    #print $l[0],"\n";
    $slot=&mins2string($mins);
    for($i=0;$i<=$#l;$i++)
    {
        $cell=$l[$i];
        next unless $cell=~/ - /;
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
        print "$slot;",$court_names[$i],";$cat;$pool;$phase;$t1;$t2;;;\n"
    }
    $mins+=$m_duration;
    $i++;
}
close F;

# 620 to => 10:20
sub mins2string
{
    my ($mins)=@_;
    my ($hh,$mm,$st);

    $hh=$mins/60;
    $mm=$mins%60;
    $st=sprintf("%02d:%02d",$hh,$mm);
    return $st;
}
