#! /bin/bash

git diff --no-index --quiet ../00_TESTBED/pattern1_data/f3.dat  output.dat
echo $? # Returns 0 if files are identical, 1 if different