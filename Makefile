# Makefile

# Define the swift compiler
SWIFTC = swiftc

# Define the output binary name
OUTPUT = run

# Define source files for each model
TUMBLEWEED_SOURCES = Miscellaneous.swift Tumbleweed\ Model/*.swift Tumbleweed\ Model/Genetic\ Algorithm/*.swift
TUMBLEWEEDREDUX_SOURCES = Miscellaneous.swift Tumbleweed\ Model\ Redux/*.swift Tumbleweed\ Model\ Redux/Genetic\ Algorithm/*.swift
SELFADAPTATION_SOURCES = Miscellaneous.swift Self\ Adaptation\ Model/*.swift Self\ Adaptation\ Model/Genetic\ Algorithm/*.swift
SELFADAPTATIONLSD_SOURCES = Miscellaneous.swift SelfAdaptationLSD/*.swift SelfAdaptationLSD/Genetic\ Algorithm/*.swift
NOCORRIDOR_SOURCES = Miscellaneous.swift No\ Corridor\ Model/*.swift No\ Corridor\ Model/Genetic\ Algorithm/*.swift

# Default target
.PHONY: help
help:
	@echo "Usage: make <TumbleWeedModel | SelfAdaptationModel | SelfAdaptationLSD | NoCorridorModel>"
	@echo "  TumbleWeedRedux: is a reduced model that searches for optimal strictness, with former pareto fronts exploring and later exploiting."
	@echo "  TumbleWeedModel: is a model that searches for optimal strictness, with former pareto fronts exploring and later exploiting."
	@echo "  SelfAdaptationModel: is a model that searches for optimal strictness using normal random number generation."
	@echo "  SelfAdaptationLSD: is a model that searches for optimal strictness using LSD like random number generator."
	@echo "  NoCorridorModel: is a traditional complete random mutation model."

# Targets for each model
.PHONY: TumbleWeedModel
TumbleWeedModel:
	$(SWIFTC) -o $(OUTPUT) $(TUMBLEWEED_SOURCES)
.PHONY: TumbleWeedRedux
TumbleWeedRedux:
	$(SWIFTC) -o $(OUTPUT) $(TUMBLEWEEDREDUX_SOURCES)
.PHONY: SelfAdaptationModel
SelfAdaptationModel:
	$(SWIFTC) -o $(OUTPUT) $(SELFADAPTATION_SOURCES)

.PHONY: SelfAdaptationLSD
SelfAdaptationLSD:
	$(SWIFTC) -o $(OUTPUT) $(SELFADAPTATIONLSD_SOURCES)

.PHONY: NoCorridorModel
NoCorridorModel:
	$(SWIFTC) -o $(OUTPUT) $(NOCORRIDOR_SOURCES)
