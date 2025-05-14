#! bin/bash

set -e

for i in {0..99}
do
  cat <<EOF

    ####################################
    ###### Running testing - p$i  ######
    ####################################

EOF
  ./01_run p$i

  cat <<EOF

    ###############################################
    ###### Finsh testing - p$i and clean up  ######
    ###############################################

EOF

  ./99_clean_up
done

echo "All tests have been run !"