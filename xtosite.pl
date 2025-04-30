#!/bin/perl
#
# generate site thanks to exchange file (xfile)

use Data::Dumper;

# format of exchange file : slot_time; court ; category ; pool ; phase (if any); team 1; team 2; score t1; score t2;
use POSIX qw(strftime setlocale LC_TIME);
$ENV{'TZ'} = 'Europe/Paris';
$gentime = strftime "%H:%M:%S", localtime;

while(<>)
{
    chomp;
    next unless /^[0-9:]+;/;
    @t=split /;/,$_;
    push @tall,[@t];
    ($slot,$court,$cat,$pool,$phase,$equ1,$equ2,$sc1,$sc2)=@t;
    $htslot{$slot}=1;
    $htcourt{$court}=1;
    $htcat{$cat}=() unless exists $htcat{$cat};
    $htcat{$cat}{$pool}=() unless exists $htcat{$cat}{$pool};
    $phase='-' if $phase eq '';
    $htcat{$cat}{$pool}{$phase}=() unless exists $htcat{$cat}{$pool}{$phase};
    #$htcat{$cat}{$pool}{$phase}{$equ1}=1;
    #$htcat{$cat}{$pool}{$phase}{$equ2}=1;
    #$htequ{$cat}{$equ1}=1;
    #$htequ{$cat}{$equ2}=1;
    $htequp{$cat}{$pool}{$equ1}=1;
    $htequp{$cat}{$pool}{$equ2}=1;
}

# ================ COURTS ================
@courts=sort keys %htcourt;
print "courts : ",join(' ',@courts,"\n");

mkdir "./courts";
for my $court (@courts)
{
    mkdir "./courts/$court";
    open F,">./courts/$court/index.html";
    &header;
    print F "Matches sur Terrain $court<p>\n";
    my $tfil=&filter(1,$court);
    &table($tfil,
           'Heure','Equipe 1','Equipe 2','Cat.','Poule','Phase',
           0,      5,          6,        2,     3,      4,
           'slot',  'team',   'team',    'z',   'z',    'z');
    &footer;
    close F;
}

# all slots
@slots=sort keys %htslot;
print "slots : ",join(' ',@slots,"\n");

# =============== CATEGORIES ===========
@cats=sort keys %htcat;
mkdir "./cats";
for my $cat (@cats)
{
    mkdir "./cats/$cat";
    open F,">./cats/$cat/index.html";
    &header;
    print F "Categorie $cat<p><ul>\n";
    @pools=sort keys %{$htcat{$cat}};
    foreach $pool (@pools)
    {
        mkdir "./cats/$cat/$pool";
        print F "<li><a href=\"$pool/index.html\">Poule $pool</a><ul>\n";
        @teams=sort keys %{$htequp{$cat}{$pool}};
        foreach $team (@teams)
        {
            $prettyteam=&rewrite_team($team);
            print F "<li><a href=\"$pool/$team.html\">$prettyteam</a></li> ";
            push @t_cat_pool_team,[$cat,$pool,$team];
        }
        print F " </ul> </li>\n";
        push @t_cat_pool,[ $cat,$pool];
    }
    print F "</ul>\n";
    &footer;
    close F;
}

# =============== POOLS ===============
for my $ecp (@t_cat_pool)
{
    my ($cat,$pool)=@$ecp;
    open F,">./cats/$cat/$pool/index.html";
    &header;
    print F "Poule $cat $pool<p><p>\n";
    print F "Matchs : <p>\n";
    my $tfil=&filter2(2,3,$cat,$pool);
    my $tscore=&scoring($tfil);
    &table($tfil,
           'Heure','Equipe 1','Equipe 2','Phase','Terrain',
           0,      5,         6,         4,      1,
           'slot', 'team',    'team',    'z',    'z');
    print F "<p>Classement : <p>\n";
    my $tss=&sort_scores($tscore);
    &table($tss,
           'Rang','Equipe','Points','M. Gagnes','M. Perdus','M. Nulls','Pts. marques','Pts. encaisses','Diff. Score',
           0,     1,       2,       3,          4,          5,         6,              7,               8,
           'z',   'team',  'z',     'z',        'z',        'z',       'z',           'z',              'z');

    &footer;
    close F;
}

# format of exchange file : slot_time; court ; category ; pool ; phase (if any); team 1; team 2; score t1; score t2;
# =============== TEAMS ===============
for my $ecpt (@t_cat_pool_team)
{
    my ($cat,$pool,$team)=@$ecpt;
    open F,">./cats/$cat/$pool/$team.html";
    &header;
    print F "Equipe ",&rewrite_team($team)," ($cat $pool)<p>\n";
    print F "Matchs : <p>\n";
    my $tfil=&filter2(2,3,56,$cat,$pool,$team);
    &keepone($tfil,5,6,$team);
    &table($tfil,
           'Heure','Terrain','Contre','Phase',
           0,1,5,4,
           'slot','z','team','z');

    &footer;
    close F;
}

# ============== Utilities =========

sub sort_scores
{
    my ($psrc)=@_;
    my @dst=();
    my ($max,$i,$cost,$imax,$line);
    my $rank=1;

    while($#$psrc>=0)
    {
        $max=0-(1<<20);
        for ($i=0;$i<=$#$psrc;$i++)
        {
            $cost= ($psrc->[$i]->[2])<<20;
            $cost+=(($psrc->[$i]->[8])+(1<<9))<<10;
            $cost+=($psrc->[$i]->[6]);
            if ($cost>$max)
            {
                $max=$cost;
                $imax=$i;
            }
        }
        my $line=splice @$psrc,$imax,1;
        $line->[0]=$rank++;
        push @dst,$line;
    }
    return \@dst;
}

sub scoring
{
    my ($tfil)=@_;
    # first find all the teams from the table
    my %teams=();
    my ($pt,$t,%hpts,%hwin,%hlost,%hdraw,%hplus,%hminus,%hdiff,@tn);
    print "scoring :\n";
    for $pt (@$tfil)
    {
        $teams{$pt->[5]}=1;
        $teams{$pt->[6]}=1;
    }
    # init hash tables for individual scores
    @tn=sort(keys(%teams));
    for $t (@tn)
    {
        print "  ",$t,"\n";
        $hpts{$t}=0;
        $hwin{$t}=0;
        $hlost{$t}=0;
        $hdraw{$t}=0;
        $hplus{$t}=0;
        $hminus{$t}=0;
        $hdiff{$t}=0;
    }
    # make the scoring
    for $pt (@$tfil)
    {
        my ($r,$r,$r,$r,$r,$t1,$t2,$sc1,$sc2)=@$pt;
        next unless $s1 or $sc2;
        # we have a score
        $hdiff{$t1}+=$sc1-$sc2;
        $hdiff{$t2}+=$sc2-$sc1;
        $hplus{$t1}+=$sc1;
        $hminus{$t1}-=$sc2;
        $hplus{$t2}+=$sc2;
        $hminus{$t2}-=$sc1;
        if ($sc1>$sc2)
        {
            # team 1 victorious
            $hwin{$t1}++;
            $hlost{$t2}++;
            $hpts{$t1}+=3;
            $hpts{$t2}+=1;
        }
        elsif ($sc1<$sc2)
        {
            # team 2 victorious
            $hwin{$t2}++;
            $hlost{$t1}++;
            $hpts{$t2}+=3;
            $hpts{$t1}+=1;
        }
        else
        {
            # draw
            $hdraw{$t2}++;
            $hdraw{$t1}++;
            $hpts{$t2}+=2;
            $hpts{$t1}+=2;
        }
        $pt->[5]=&rewrite_team($t1)." ($sc1)";
        $pt->[6]=&rewrite_team($t2)." ($sc2)";
    }
    # now the ranking
    @tsc=();
    for $t (@tn)
    {
        push @tsc,[ 1,$t,$hpts{$t},$hwin{$t},$hlost{$t},$hdraw{$t},$hplus{$t},$hminus{$t},$hdiff{$t} ];
    }
    #print Dumper(\@tsc);
    return \@tsc;
}

sub filter
{
    my ($col,$val)=@_;
    #print "col=$col, val=$val\n";
    my @tfil=();
    my ($pt);
    for $pt (@tall)
    {
        #print "pt ",$pt->[$col],"\n";
        if ($pt->[$col] eq $val)
        {
            push @tfil,[@{$pt}];
        }
    }
    return \@tfil;
}

sub filter2
{
    my (@ar)=@_;
    my ($nb,$pt,$keep,$kind,$val,$i,$id,$keep2);
    $nb=($#ar+1)/2;
    my @tfil=();
    for $pt (@tall)
    {
        $keep=1;
        # logical AND
        for ($i=0;$i<$nb;$i++)
        {
            $kind=$ar[$i];
            $val=$ar[$i+$nb];
            if ($kind>=10)
            {
                # logical OR (except on column 0)
                $keep2=0;
                while ($kind>0)
                {
                    $id=$kind%10;
                    if ($pt->[$id] eq $val) { $keep2=1; }
                    $kind/=10;
                }
                $keep=0 unless $keep2==1;
            }
            else
            {
                # single value
                unless ($pt->[$kind] eq $val) { $keep=0; }
            }
        }
        if ($keep==1)
        {
            push @tfil,[@{$pt}];
        }
    }
    return \@tfil;
}

sub keepone
{
    my ($tfil,$col1,$col2,$ref)=@_;
    for $pt (@$tfil)
    {
        if ($pt->[$col1] eq $ref) { $pt->[$col1] = $pt->[$col2]; }
        elsif ($pt->[$col2] eq $ref) { $pt->[$col2] = $pt->[$col1]; }
    }
}

sub table
{
    my (@ar)=@_;
    my ($pt,$nb,$i,$cell,$css);
    my $tfil=shift @ar;
    $nb=($#ar+1)/3;
    print F "<table><thead><tr> ";
    for($i=0;$i<$nb;$i++) { print F "<th>",$ar[$i],"</th> "; }
    print F "</tr></thead>\n<tbody>\n";
    for $pt (@$tfil)
    {
        print F "<tr> ";
        for ($i=0;$i<$nb;$i++)
        {
            $cell=$pt->[$ar[$nb+$i]];
            $css=$ar[$nb+$nb+$i];
            if ($css eq 'team') { $cell=&rewrite_team($cell); }
            print F "<td class=\"$css\">$cell</td> ";
        }
        print F "</tr>\n";
    }
    print F "</tbody></table>\n";
}

sub rewrite_team
{
    my ($t)=@_;
    my $t2=ucfirst($t);
    if ($t2 =~/[0-9]$/) { $t2=~s/^(.*)([0-9])$/\1 \2/; }
    return $t2;
}

sub header
{
    print F "<html><body>\n";
    print F "  <style>
    table, th, td {
      border: 1px solid black;
      border-collapse: collapse;
      padding: 8px;
      text-align: center;
    }
.team::first-letter {
  text-transform: uppercase;
}
.slot { font-weight: bold; }
    </style>\n";
}

sub footer
{
    print F "<i>genere a $gentime</i>\n";
    print F "</body></html>";
}
