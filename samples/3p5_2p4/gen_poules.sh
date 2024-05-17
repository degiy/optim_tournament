#!/bin/bash

rm -f ./m_*.csv

for a in p_*csv
do

    ./match_de_poule.pl $a
done
