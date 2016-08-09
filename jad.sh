#!/bin/bash

if [ "$#" == "0" ]; then
	echo "executing version without arguments"
else 
	while [[ $# > 0 ]]; do
		case $1 in
			-a | --aaa) 		shift
								echo "some option a"
								;;
			-b | --bbb)			shift
								echo "some option b"
								;;
			-h | --help)		shift
								echo "I'm showing help..."
								exit
								;;
			*)					shift
								echo "Unrecognize command"
								echo "I'm showing help..."
								exit
								;;
		esac
	done
fi
