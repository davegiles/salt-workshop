# SaltStack Workshop

> Note: This has been forked from the upstream repository and is a work in
> progress.  Things are broken, and they're not clear.  So far, only the first
> five modules have been updated.

## Introduction

This repo contains the complete hands on workshop on SaltStack.  It starts with
a basic Salt cluster using Vagrant and then builds from basic concepts to
advanced.  It provides multiple distributions of Linux so that you can see what
managing a multi-distribution environment is like.

## Modules

| Module | Description |
|---|---|
|[Setup](docs/setup)| Setup the local environment so that you can start using SaltStack|
|[Targeting](docs/target)|How to target nodes|
|[Grains](docs/grains)|How to use Grains to get information about systems|
|[YAML](docs/yaml)|Three simple rules to use YAML|
|[Pillar](docs/pillar)|User-defined configuration data|
|[Directory Structure](docs/dir_structure)|The structure of code and data in Salt|
|[Remote execution](docs/remote_execution)|How to fire commands from the master|
|[Jinja](docs/jinja)|An exploration of the templating language for programming Salt|
|[State Files](docs/sls)|Salt States: the convergence of infrastructure|
|[Formula](docs/formula)|Making SaltStack repeatable|
|[Salt Mine](docs/mine)|How to use mine for cross-node data retrieval|
|[Salt Beacons](docs/beacon)|Watching events on minions|
|[Reactor](docs/reactor)|How to create events and actions|
|[Orchestration](docs/orchestrate)|Orchestrate complex workflows|
|[Schedules](#)|Routinely perform a Salt action (Coming Soon)|
|[Salt Proxy](#)|How to use Salt with nodes that can't run a Salt Minion (Coming Soon)|
|[Network Device Execution](#) |Using Salt to run commands on network devices (Coming Soon) |
|[Network Device States](#) |Using Salt to manage states on network devices (Coming Soon) |
