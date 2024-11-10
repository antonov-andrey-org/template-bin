#!/bin/bash -e


set -o allexport
source ./.env
set +o allexport

mysql --host=$SqlAlchemyHost --port=$SqlAlchemyPort --user=$SqlAlchemyUser --password "$@"
