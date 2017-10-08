# SaltStack Workshop

> Note: This has been forked from the upstream repository and is a work in
> progress.  Things are broken, and they're not clear.  So far, only the first
> three modules have been updated.

## Introduction

This repo contains the complete hands on workshop on SaltStack.  It starts with
a basic Salt cluster using Vagrant and then builds form basic concepts to
advanced.

## Modules

| Module | Description |
|---|---|
|[Setup](docs/setup)| Setup the local environment so that you can start using Saltstack cluster|
|[Targeting](docs/target)|How to target nodes from a large cluster of nodes|
|[Grains](docs/grains)| How to use Grains to get information of systems|
|[YAML](docs/yaml)|Three simple rules to use YAML|
|[Pillar](docs/pillar)|User defined configuration data|
|[Directory Structure](docs/dir_structure)|The structure of code and data in Salt|
|[Remote execution](docs/remote_execution)|How to fire commands from the master|
|[Jinja](docs/jinja)|Templating language for programming Salt|
|[State Files](docs/sls)|Salt States which converge infrastructure|
|[Formula](docs/formula)|The logical units of the Saltstack|
|[Salt Mine](docs/mine)|How to use mine for cross node data retrieval|
|[Salt Beacons](docs/beacon)|Beacons for watching things|
|[Reactor](docs/reactor)|How to create events and actions|
|[Orchestration](docs/orchestrate)|Orchestrate complex workflows|
