#!/bin/bash bash

# removes prefix and suffix " if they exist in the variable
#
# param $1: variable to sanitize
# returns sanitized variable
function sanitize_variable {
    local variable=$1
    variable=${variable%\"} # removing suffix
    variable=${variable#\"} # removing prefix
    echo $variable
}

# parses server path
#
# param $1 : json file
# param $2 : profile fetched from json file
#
# sets : global variable server_path
function parse_server_path {
    local json_file=$1
    local profile_json=$2

    #fetches string from server and checks if there is such a profile in servers group
    # in json file, if not it means it is a path
    temp=$(echo $profile_json | jq ".server")
    server_path=$(cat $json_file | jq ".servers.$temp")
    [ "$server_path" = null ] && server_path=$temp
    server_path=$(sanitize_variable $server_path)
}

# parses ear path
#
# param $1 : json file
# param $2 : profile fetched from json file
#
# sets : global variables
#           ear_maven_path
#           ear_path
#           ear_name
function parse_ear_path {
    local json_file=$1
    local profile_json=$2

    # checks if found structure is string, if it is it means that ear properties are in
    # ears group in json file
    ear_json=$(echo $profile_json | jq '.ear')
    [ $(echo $ear_json | jq '. | type') = "\"string\"" ] && ear_json=$(cat $json_file | jq ".ears.$ear_json")

    if [[ $ear_json != "null" ]]; then
        ear_maven_path=$(sanitize_variable $(echo $ear_json | jq '.mvn_path'))
        ear_path=$(sanitize_variable $(echo $ear_json | jq '.ear_path'))
        ear_name=$(sanitize_variable $(echo $ear_json | jq '.name'))
    fi
}

# helper funcion for parsing modules
#
# it recursively parses modules in following manner:
#   1.  checks whether found string exists in '.modules' section
#       in json file
#   2.  if so, it fetches that array and for each it goes to step 1
#   3.  if not, it adds this module to the modules_paths
#
function parse_modules_helper {
    local json_file=$1
    local json_module=$(sanitize_variable $2)

    json_module=$(cat $json_file | jq ".modules.$json_module")

    for path in $(echo $json_module | jq ".[]"); do
        module_in_modules=$(cat $json_file | jq ".modules.$path")
        if [[ ! "$module_in_modules" = null ]]; then
            parse_modules_helper "$json_file" "$path"
        else
            modules_paths+=("$(sanitize_variable $path)")
        fi
    done
}

# parses module paths
#
# param $1 : json file
# param $2 : profile fetched from json file
#
# sets : global variable modules_paths[]
function parse_modules {
    local json_file=$1
    local profile_json=$2

    local modules_json=$(echo $profile_json | jq ".modules")

    for path in $(echo $modules_json | jq ".[]"); do
        module_in_modules=$(cat $json_file | jq ".modules.$path")
        if [[ ! "$module_in_modules" = null ]]; then
            parse_modules_helper "$json_file" "$path"
        else
            modules_paths+=("$(sanitize_variable $path)")
        fi
    done
}


# parses deployment profile details from json file
# there are fetched following variables:
#   $server_path, $ear_mvn_path, $ear_path, $ear_name, ${modules_path[*]}
# if fetching fails, the variable will store 'null' string
#
# param $1: deployment profile
# return: nothing
function parse_profile {
    local profile=$1
    profile_json=$(cat $json_file | jq ".profiles.\"$profile\"")

    if [[ $profile_json == "null" ]]; then
        echo "provided provile does not exist"
        exit 5
    fi;

    parse_server_path "$json_file" "$profile_json"
    parse_ear_path "$json_file" "$profile_json"
    parse_modules "$json_file" "$profile_json"


    if [[ "$script_debug" = true ]]; then
        echo -e "server path : $server_path
ear maven path : $ear_maven_path
ear path : $ear_path
ear name : $ear_name
modules paths : ${modules_paths[@]}\n"
    fi
}