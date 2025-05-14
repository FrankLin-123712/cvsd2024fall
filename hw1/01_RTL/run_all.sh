#! bin/bash

set -e

for i in {0..9}
do
  cat <<EOF

    ####################################
    ###### Running Instruction $i ######
    ####################################

EOF
  ./01_run I$i
done

echo "All tests have been run !"
