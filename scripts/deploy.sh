#!/bin/bash

set -e

echo Deployment

echo IOT_CREDENTIAL_ENDPOINT: $IOT_CREDENTIAL_ENDPOINT
echo IOT_GG_GROUP_NAME: $IOT_GG_GROUP_NAME
echo LAMBDA_FUNCTION_NAME: $LAMBDA_FUNCTION_NAME

apt-get install -y jq curl zip

echo Get temporary credentials from AWS IoT:

AWS_COMMAND="aws"

PRIVATE_KEY=`cat /greengrass/config/config.json | jq -r '.coreThing.keyPath'`
CERTIFICATE=`cat /greengrass/config/config.json | jq -r '.coreThing.certPath'`
ROOT_CA=`cat /greengrass/config/config.json | jq -r '.coreThing.certPath'`
AWS_REGION=`cat /greengrass/config/config.json | jq -r '.coreThing.ggHost | split(".")[2]'`
CREDS=`curl -s --key /greengrass/certs/$PRIVATE_KEY --cacert /greengrass/certs/$ROOT_CA --cert /greengrass/certs/$CERTIFICATE https://$IOT_CREDENTIAL_ENDPOINT:443/role-aliases/iot-gg-dev-pipeline-role/credentials`
export AWS_ACCESS_KEY_ID=`echo $CREDS | jq -r ".credentials.accessKeyId"`
export AWS_SECRET_ACCESS_KEY=`echo $CREDS | jq -r ".credentials.secretAccessKey"`
export AWS_SESSION_TOKEN=`echo $CREDS | jq -r ".credentials.sessionToken"`
echo $AWS_ACCESS_KEY_ID, $AWS_SECRET_ACCESS_KEY, $AWS_SESSION_TOKEN

echo "Zipping..."
rm -f package.zip
zip -rq package.zip *

echo "Uploading to Lambda"
$AWS_COMMAND lambda update-function-code --region $AWS_REGION --function-name $LAMBDA_FUNCTION_NAME --zip-file fileb://`pwd`/package.zip
echo "Publishing new Lambda version"
LAMBDA_PUBLISH_VERSION=`$AWS_COMMAND lambda publish-version --region $AWS_REGION --function-name $LAMBDA_FUNCTION_NAME --query Version --output text`
echo "Updating the alias"
$AWS_COMMAND  lambda update-alias --region $AWS_REGION --name gg-dev-pipeline --function-name $LAMBDA_FUNCTION_NAME --function-version $LAMBDA_PUBLISH_VERSION

GROUP_ID=`$AWS_COMMAND greengrass list-groups --region $AWS_REGION --query "Groups[?Name=='$IOT_GG_GROUP_NAME'].Id" --output text`
GROUP_VERSION_ID=`$AWS_COMMAND greengrass list-groups --region $AWS_REGION --query "Groups[?Name=='$IOT_GG_GROUP_NAME'].LatestVersion" --output text`

echo "Deploying to GG"
$AWS_COMMAND greengrass create-deployment --region $AWS_REGION --group-id $GROUP_ID --deployment-type NewDeployment --group-version-id $GROUP_VERSION_ID
