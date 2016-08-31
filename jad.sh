#!/bin/bash

#### PRECONDITIONS ####

# checks if jq package for parsing json is installed---------------------
if [[ ! `dpkg -s 'jq' | grep 'ok install'` ]]; then
    echo "Please install jq package for parsing json"
    echo `dpkg-query -l 'jq'`
    exit 42
fi

# checks if json configuration file exists--------------------------------
json_file="jad-conf.json"

if [ ! -e "$json_file" ]; then
    echo "Missing json configuration file: $json_file"
fi

# if there are no parameters exit-----------------------------------------
if [ $# -eq 0 ]; then
	echo "executing version without arguments"
    exit 42
fi

#### DECLARE VARIABLES ####

# possible options
build_modules=false
build_ear=false
deploy=false
show_errors=false
skip_tests=false
profile="default"
debug=false
quiet=false

server_path=""
modules_paths=()
ear_path=""

# this function parses parameters in short format ( -zxcv )
# as a parameter it takes one argument
# it returns whether any parameter was parsed
function parse_short_parameters {
    local parameters=()
    # checking if there is parameter with single hyphenation------------------
    if [[ $(expr match $1 "-[a-zA-Z]") -gt 0 ]]; then
        result="true"
        # if there are at least two parameters (the first one is hyphenation)
        if [[ ${#1} -gt 2 ]]; then
            # substring from first character
            parameters_to_split=${1:1}

            # append each character with hyphenation to list of parameters
            for char in $(echo $parameters_to_split | fold -w1); do
                parameters+=("$char")
            done
        fi
    fi
    # if the number of parameters is greater than zero, parse them
    if [[ ${#parameters[@]} -gt 0 ]]; then
        for i in "${!parameters[@]}"; do
            case ${parameters[$i]} in
                b)
                    #Set build modules to true"
                    build_modules=true
                    ;;
                d)
                    #Set deploy ear to true"
                    deploy=true
                    ;;
                e)
                    #Set deploy ear to true"
                    build_ear=true
                    ;;
                r)
                    #Set show errors to true
                    show_errors=true
                    ;;
                s)
                    #Set skip tests to true
                    skip_tests=true
                    ;;
                X)
                    #Set debug
                    debug=true
                    ;;
                q)
                    #Set quiet
                    quiet=true
                    ;;
                *)
                    echo "Cannot recognize command"
                    echo "I'm showing help..."
                    exit
                    ;;
            esac
        done
    fi
    return ${#parameters[@]}
}

# this function parses parameters in long format ( -zzz -xxx -yyy)
function parse_long_parameters {
    # iterate through the rest of command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -b | --build)       shift
                                #Set build modules to true"
                                build_modules=true
                                ;;
            -d | --deploy)      shift
                                #Set deploy ear to true"
                                deploy=true
                                ;;
            -e | --ear)         shift
                                #Set deploy ear to true"
                                build_ear=true
                                ;;
            -p | --profile)     shift
                                #Set profile to $1"
                                profile=$1
                                shift
                                ;;
            -r | --show-errors) shift
                                #Set show errors to true
                                show_errors=true
                                ;;
            -s | --skip-tests)  shift
                                #Set skip tests to true
                                skip_tests=true
                                ;;
            -q | --quiet)       shift
                                #Set quiet to true
                                quiet=true
                                ;;
            -X | --debug)       shift
                                #Set debug to true
                                debug=true
                                ;;
            -h | --help)		shift
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
}

function parse_profile {
    local profile=$1
    profile_json=$(cat $json_file | jq ".\"$profile\"")

    if [[ $profile_json == "null" ]]; then
        echo "provided provile does not exist"
        exit 5
    fi;

    server_path=$(echo $profile_json | jq '.server')
    ear_path=$(echo $profile_json | jq '.ear')

    if [[ $(echo $profile_json | jq '.modules') != "null" ]]; then
        for path in $(echo $profile_json | jq '.modules[]'); do
            modules_paths+=("$path")
        done
    fi
}

function prepare_maven_command {
    local maven_command="mvn"
    [ "$show_errors" = "true" ] && maven_command+=" -e";
    [ $debug = true ] && maven_command+=" -X"
    [ $quiet = true ] && maven_command+=" -q"
    [ $skip_tests = true ] && maven_command+=" -DskipTests=true"

    printf "%s" "$maven_command"
}

function perform_building_modules {
    echo "Building modules:"

    for module in ${modules_paths[*]}; do
        echo "building module: $module"
        mvn_args=$(prepare_maven_command)
        echo $mvn_args

    done
}


parse_short_parameters $1
# parse short parameters returns information if any argument war parsed
# function returns how may arguments was parsed from single input
# if at least one was parsed input arguments should be moved
if [[ $? -gt 0 ]]; then
    shift
fi
parse_long_parameters $@
parse_profile $profile

echo "executing with $profile profile"

if [[ $build_modules != false ]]; then
    perform_building_modules

fi








