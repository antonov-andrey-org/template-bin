#!/bin/bash -e

docker compose up -d --always-recreate-deps --build --force-recreate --remove-orphans
