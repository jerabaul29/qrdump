##############################################
# sounder programming environment            #
##############################################

# exit if a command fails
set -o errexit
# make sure to show the error code of the first failing command
set -o pipefail
# do not overwrite files too easily
set -o noclobber
# exit if try to use undefined variable
set -o nounset

##############################################
# a few params                               #
##############################################

GIVE_ACCESS=false

########################################
# helper functions                     #
########################################

# TODO: allow to redirect tests to a log file

press_any(){
	if [ $GIVE_ACCESS = true ]
	then
	    echo "giving a chance to inspect the output"
	    read -n 1 -s -r -p "Press any key to continue"
	    echo " "
	fi
}

give_access(){
	if [ $GIVE_ACCESS = true ]
	then
    	nautilus . &
	fi
}

########################################
# set up the test env                  #
########################################

cd ../src/

if [ -d "dummy" ]
then
    echo "dir dummy for tests already exists; cleaning!"
    rm -rf dummy
fi

mkdir dummy
