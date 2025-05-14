#!/bin/bash

set -e

for i in {24..99}
do
  line_count=$(wc -l < ../00_TB/PATTERN/p$i/status.dat)
  printf "p%d : %d\n" $i $line_count
done