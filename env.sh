#!/bin/bash

# Pulls in jars for atom lib.
export ATOM_EXT_DIR=/home/jason/Applications/atom-ext

# Atom Project source.
export ATOM_SRC_DIR=/home/jason/Projects/atom

# Source directory for connector projects.
export CON_SRC_DIR=/home/jason/Projects/connectors

# Base dir for boomi app.
export PLATFORM_BOOMI_DIR=/usr/local/boomi/boomi-base

# Plaform directory for connector installs.
export PLATFORM_CONNECTOR_DIR=${PLATFORM_BOOMI_DIR}/connector

# The updates directory for the platform.
export PLATFORM_UPDATES_DIR=${PLATFORM_BOOMI_DIR}/updates

#The connector descriptor dir.
export PLATFORM_CONN_DESC_DIR=${PLATFORM_BOOMI_DIR}/cache/connConfig

# The base directory of the platform.
export PLATFORM_BASE_DIR=/usr/local/boomi/jetty-base

# The platorm application directory.
export PLATFORM_DEPLOY_DIR=${PLATFORM_BASE_DIR}/webapps/ROOT

