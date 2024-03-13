#!/bin/bash -e

set -o allexport
source ./.env
set +o allexport
if [[ $SqlAlchemyQueryArgs == ssl_ca* ]];
then
mysql --host=$SqlAlchemyHost \
      --port=$SqlAlchemyPort \
      --ssl-ca=mysql.crt \
      --ssl-mode=VERIFY_IDENTITY \
      --user=$SqlAlchemyUser \
      --password "$@"
else
mysql --host=$SqlAlchemyHost \
      --port=$SqlAlchemyPort \
      --user=$SqlAlchemyUser \
      --password "$@"
fi
