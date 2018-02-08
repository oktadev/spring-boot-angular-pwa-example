#!/bin/bash
# Warning: this script has only been tested on macOS Sierra. There's a good chance
# it won't work on other operating systems. If you get it working on another OS,
# please send a pull request with any changes required. Thanks!
set -e

### CloudFoundry CLI utilities
CLOUD_DOMAIN=${DOMAIN:-run.pivotal.io}
CLOUD_TARGET=api.${DOMAIN}

function login(){
    cf api | grep ${CLOUD_TARGET} || cf api ${CLOUD_TARGET} --skip-ssl-validation
    cf apps | grep OK || cf login
}

function app_domain(){
    D=`cf apps | grep $1 | tr -s ' ' | cut -d' ' -f 6 | cut -d, -f1`
    echo $D
}

function deploy_service(){
    N=$1
    D=`app_domain $N`
    JSON='{"uri":"http://'$D'"}'
    cf create-user-provided-service $N -p $JSON
}

### Installation

cd `dirname $0`
r=`pwd`
echo $r

## Reset
cf d -f pwa-client
cf d -f pwa-server

cf a

# Deploy the server
cd $r/server
mvn clean package
cf push -p target/*jar pwa-server --no-start --random-route

# Get the URL for the server
serverUri=https://`app_domain pwa-server`

# Deploy the client
cd $r/client
rm -rf dist
# replace the server URL in the client
sed -i -e "s|http://localhost:8080|$serverUri|g" $r/client/src/app/shared/beer/beer.service.ts
npm install && ng build --prod
cd dist
touch Staticfile
echo "pushstate: enabled" >> Staticfile
cf push pwa-client --no-start --random-route
cf set-env pwa-client FORCE_HTTPS true
cf start pwa-client

# Get the URL for the client
clientUri=https://`app_domain pwa-client`

# replace the client URL in the server
sed -i -e "s|http://localhost:4200|$clientUri|g" $r/server/src/main/java/com/example/demo/beer/BeerController.java

# redeploy the server
cd $r/server
mvn package -DskipTests
cf push -p target/*jar pwa-server

# cleanup changed files
# Put the original server URL back in the client
sed -i -e "s|$serverUri|http://localhost:8080|g" $r/client/src/app/shared/beer/beer.service.ts
sed -i -e "s|$clientUri|http://localhost:4200|g" $r/server/src/main/java/com/example/demo/beer/BeerController.java
rm $r/client/src/app/shared/beer/beer.service.ts-e
rm $r/server/src/main/java/com/example/demo/beer/BeerController.java-e

# show apps and URLs
cf apps