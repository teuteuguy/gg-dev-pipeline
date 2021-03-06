# gg-dev-pipeline boylerplate

This is **Work In Progress** Devops pipeline building for Greengrass Lambda function development.

## TODO:

* Add "click to deploy" buttons for the CF script :)

## Clone/Fork this repo.

The repo will be your boylerplate lambda function.

Once you have forked and you have deployed the below (cloudformation) resources, you have to keep the following files for this to work:

* ./buildspec.yml
* ./Makefile
* scripts/deploy.sh

## Then setup the resources

Deploy the Cloudformation template: **cf-gg-dev-pipeline.yml**.

Give it a name: for example: ***[gg-dev-pipeline]***

### Manual steps you need to run after the common template:

1. Get the ActivationId and ActivationCode from the Outputs of the Common Cloudformation script
2. Then, on your device (example: Raspberry Pi), install and configure SSM agent.

		mkdir /tmp/ssm
		sudo curl https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_arm/amazon-ssm-agent.deb -o /tmp/ssm/amazon-ssm-agent.deb
		sudo dpkg -i /tmp/ssm/amazon-ssm-agent.deb
		sudo service amazon-ssm-agent stop
		sudo amazon-ssm-agent -register -code "[ActivationCode]" -id "[ActivationId]" –region "[AWS Region where you ran the Cloudformation script]"
		sudo service amazon-ssm-agent start

3. You will require the AWS CLI

		curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "/tmp/awscli-bundle.zip"
		unzip awscli-bundle.zip
		sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

4. Setup and Install Greengrass on your device (with GG Core certificates etc ...)
5. You are good to go. Push new code to github and your pipeline will trigger


## How it works

When you push new code to github, it will get picked up by codepipeline.
Codebuild will run the buildspec.yml file.

Effectively that will find the ManagedInstance (via it's tags) and prepare the necessary environment variables to pass down via SSM to the device.

Then it will call SSM to tell your device to build. Effectively telling the device to git clone this repo, run npm install.

The scripts/deploy.sh script will get executed after npm install, effectively packaging up the resulting code, updload it to Lambda, publish a new version, update the alias, and ask GG to redeploy.

# DISCLAIMER
This is work in progress. Use at your own risk!
