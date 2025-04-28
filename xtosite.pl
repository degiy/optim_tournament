#!/bin/perl
#
# generate site thanks to exchange file (xfile)

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
foreach $court (@courts)
{
    mkdir "./courts/$court";
    open F,">./courts/$court/index.html";
    &header;
    print F "Matches sur Terrain $court<p>\n";
    &filter(1,$court);
    &table('Heure','Equipe 1','Equipe 2','Cat.','Poule','Phase',
           0,5,6,2,3,4,
           'slot','team','team','z','z','z');
    &footer;
    close F;
}

# all slots
@slots=sort keys %htslot;
print "slots : ",join(' ',@slots,"\n");

# =============== CATEGORIES ===========
@cats=sort keys %htcat;
mkdir "./cats";
foreach $cat (@cats)
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
foreach $ecp (@t_cat_pool)
{
    ($cat,$pool)=@$ecp;
    open F,">./cats/$cat/$pool/index.html";
    &header;
    print F "Poule $cat $pool<p>\n";
    &footer;
    close F;
}

# format of exchange file : slot_time; court ; category ; pool ; phase (if any); team 1; team 2; score t1; score t2;
# =============== TEAMS ===============
foreach $ecpt (@t_cat_pool_team)
{
    ($cat,$pool,$team)=@$ecpt;
    open F,">./cats/$cat/$pool/$team.html";
    &header;
    print F "Equipe $team ($cat $pool)<p>\n";
    print F "Matchs : <p>\n";
    &filter2(2,3,56,$cat,$pool,$team);
    &table('Heure','Terrain','Contre','Contre2',
           0,1,5,6,
           'slot','z','team','team');

    &footer;
    close F;
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

sub filter
{
    my ($col,$val)=@_;
    #print "col=$col, val=$val\n";
    @tfil=();
    for $pt (@tall)
    {
        #print "pt ",$pt->[$col],"\n";
        if ($pt->[$col] eq $val)
        {
            push @tfil,[@{$pt}];
        }
    }
}

sub filter2
{
    my (@ar)=@_;
    my ($nb);
    $nb=($#ar+1)/2;
    @tfil=();
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
}

sub table
{
    my (@ar)=@_;
    my ($pt,$nb,$i,$cell,$css);
    $nb=($#ar+1)/3;
    print F "<table><thead><tr> ";
    for($i=0;$i<$nb;$i++) { print F "<th>",$ar[$i],"</th> "; }
    print F "</tr></thead>\n<tbody>\n";
    for $pt (@tfil)
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
