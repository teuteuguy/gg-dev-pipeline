# gg-donkey-drive

This is Work In Progress lambda function for my Greengrass that implements the dev-pipeline concept.

## Pre-requisites (sorry there are many for now)

TODO:
- Check the buildspec to get the repo from the env vars instead of re-calculating it.
- Check that we are using the CF name everywhere instead of the pipeline name

### Start by setting up the COMMON resources.
cf-common.yml CloudFormation template
Give it a name: ex: gg-dev-pipeline-common 

Manual steps you need to run after the common template:
1. Get the ActivationId and ActivationCode from the Outputs of the Common Cloudformation script
2. Then, on your device (example: Raspberry Pi), install and configure SSM agent.

mkdir /tmp/ssm
sudo curl https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_arm/amazon-ssm-agent.deb -o /tmp/ssm/amazon-ssm-agent.deb
sudo dpkg -i /tmp/ssm/amazon-ssm-agent.deb
sudo service amazon-ssm-agent stop
sudo amazon-ssm-agent -register -code "[ActivationCode]" -id "[ActivationId]" –region "[AWS Region where you ran the Cloudformation script]"
sudo service amazon-ssm-agent start

Note: you will need the AWS Cli to be installed on your device. If you are logged into your device, you can install the cli:
curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "/tmp/awscli-bundle.zip"
unzip awscli-bundle.zip
sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws


### Then setup the custom resources for the given dev function you are working on
cf-gg-dev-pipeline.yml CloudFormation template

Common
3. Create an IAM role "iot-lambda-full-access", with following attached policies:
	* AWSLambdaFullAccess
	* ResourceGroupsandTagEditorReadOnlyAccess
	* AWSGreengrassFullAccess
4. In AWS IoT, create a role-alias named: "lambda-full-access", that references your IAM role "iot-lambda-full-access"


2. Create a CodePipeline.
	1. Github repo as your source
	2. Codebuild, use the Ubuntu Base
		* Add the following IAM role permissions to your CodeBuild IAM service role:
			*  iot:DescribeEndpoint
			*  codepipeline:GetPipeline
			*  ssm:SendCommand
			*  ssm:GetCommandInvocation
			*  tag:GetResources
	3. That's it


6. Create an empty Lambda function (NodeJS for now), publish it, alias it with following name: "gg-dev-pipeline". Give it the following tags:
	* Key: gg-dev-pipeline, Value: [the name of your codepipeline]
	* Key: type, Value: lambda



5. Setup and Install Greengrass on your device (with certificates etc ...)
7. Add the newly created lambda function to your GG group, referencing your alias. And deploy it a first time
8. Install SSM on your device, and run it    
9. Create an SSM document:
	* Name: rpi-build
	* Type: command
	* Document: use file in aws-files/ssm-rpi-build.document.json
10. Once your device has connected to SSM, you need to TAG your ManagedInstance. (Use aws cli: aws ssm add-tags-to-resource ...):
	* Key: gg-dev-pipeline, Value: [Not used, so whatever you want]
	* Key: type, Value: ManagedInstance
	* Key: gg-group, Value: [Your GG Group Name]

## How it works

When you push new code to github, it will get picked up by codepipeline.
Codebuild will run the buildspec.yml file.

Effectively that will find the ManagedInstance (via it's tags) and prepare the necessary environment variables to pass down via SSM to the device.

Then it will call SSM and the rpi-build command to be executed on the device.

The SSM rpi-build command will effectively tell the device to git clone this repo, run npm install.

The scripts/postinstall.sh script will get executed after npm install, effectively packaging up the resulting code, updload it to Lambda, publish an new version, set the alias, and ask GG to redeploy.
