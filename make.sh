#!/bin/bash

if [ $# -eq 0 ]; then 
	echo "Usage: $0 <TumbleWeedModel | SelfAdaptationModel | NoCorridorModel> where"
	echo "  TumbleWeedModel: is a model that searches for optimal strictness, with former pareto fronts exploring and later exploiting."
	echo "  SelfAdaptationModel: is a model that searches for optimal strictness using normal random number generation."
	echo "  NoAdaptationModel: is a tradational complete random mutation model."
	exit 1
fi

case $1 in
	TumbleWeedModel) 
	swiftc -o run Miscellaneous.swift Tumbleweed\ Model/*.swift Tumbleweed\ Model/Genetic\ Algorithm/*.swift ;;
	SelfAdaptationModel) swiftc -o run Miscellaneous.swift Self\ Adaptation\ Model/*.swift Self\ Adaptation\ Model/Genetic\ Algorithm/*.swift ;;
	NoCorridorModel) swiftc -o run Miscellaneous.swift No\ Corridor\ Model/*.swift No\ Corridor\ Model/Genetic\ Algorithm/*.swift ;;
	*) echo "Usage: $0 <TumbleWeedModel | SelfAdaptationModel | NoCorridorModel> where"
	echo "  TumbleWeedModel: is a model that searches for optimal strictness, with former pareto fronts exploring and later exploiting."
	echo "  SelfAdaptationModel: is a model that searches for optimal strictness using normal random number generation."
	echo "  NoCorridorModel: is a tradational complete random mutation model.";;
esac