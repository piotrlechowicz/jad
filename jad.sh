#!/bin/bash

# declare array to store all parameters
declare -a parameters

# if there are no parameters exit
if [ $# -eq 0 ]; then
	echo "executing version without arguments"
    exit 42
fi

# checking if there is parameter with single hyphenation
if [[ $(expr match $1 "-[a-zA-Z]") -gt 0 ]]; then
    echo "parsing parameters with one hyphenation"
     # if there are at least two parameters (the first one is hyphenation)
    if [[ ${#1} -gt 2 ]]; then
        # substring from first character
        parameters_to_split=${1:1}

        # append each character with hyphenation to list of parameters
        for char in $(echo $parameters_to_split | fold -w1); do
            parameters+=("$char")
        done
        shift;
    fi
fi

# if the number of parameters is greater than zero, parse them
if [[ ${#parameters[@]} -gt 0 ]]; then
    for i in "${!parameters[@]}"; do
        case ${parameters[$i]} in
            b)
                echo "building modules"
                ;;
            d)
                echo "deploying application"
                ;;
            *)
                echo "Cannot recognize command"
                echo "I'm showing help..."
                exit
                ;;
        esac
    done
fi

# iterate through the rest of command line arguments
while [[ $# -gt 0 ]]; do
	case $1 in
	    -b | --build)       shift
							echo "building modules"
							;;
        -d | --deploy)      shift
                            echo "deploying application"
                            ;;
		-h  | --help)		shift
                            echo "I'm showing help..."
                            exit
                            ;;
		*)					shift
							echo "Cannot recognize command"
							echo "I'm showing help..."
                            exit
                            ;;
	esac
done;