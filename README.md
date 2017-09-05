# Casecommons ECS Base Image

This image is a derivative of the Amazon ECS-optimised AMI (currently version 2016.09.g).

It adds the following modifications at build time:

1. Set server timezone to America/Los_Angeles
1. Perform a general package update and install additional useful packages
1. Set the Docker bridge interface subnet to a private (CGNAT) CIDR range (100.64.0.0/24)
1. Upload the [`firstrun.sh`](src/files/firstrun.sh) script to `/home/ec2-user` (see below for details)
1. Stop and disable the docker service, and clean up any docker logs or containers created during the build

## Building the Image

To build the image you must first ensure your AWS security configuration is in place and your environment configured correctly.

This image currently only supports assume role operation, meaning your AWS security configuration must support assuming the role specified via the `AWS_ROLE` setting defined in the [`Makefile`](./Makefile).

To build and publish the image:

```
$ make release
```

A build folder will be created with the following files:

- `manifest.json` - includes information about the produced AMI include AMI identifier
- `build.log` - the build output from the packer build process

To clean up the environment after building the image:

```
$ make clean
```

### Customising the Build

The [`Makefile`](./Makefile) includes a number of configuration variables that allow you to customise the build:

```
# Project variables
export PROJECT_NAME ?= packer

# AWS security settings
AWS_ROLE ?= arn:aws:iam::429614120872:role/remoteAdmin
AWS_SG_NAME ?= packer-$(MY_IP_ADDRESS)-$(TIMESTAMP)
AWS_SG_DESCRIPTION ?= "Temporary security group for Packer"

# Packer settings
export AMI_NAME ?= Casecommons ECS Base Image
export AMI_USERS ?= 123456789012,234567890123
export AMI_REGIONS ?= us-west-1,us-west-2
export APP_VERSION ?= $(TIMESTAMP).$(COMMIT_ID)
export AWS_INSTANCE_TYPE ?= t2.micro
export AWS_DEFAULT_REGION ?= us-west-2
export AWS_SSH_USERNAME ?= ec2-user
export AWS_SOURCE_AMI ?= ami-7abc111a
export TIME_ZONE ?= America/Los_Angeles
...
...
```

### Generating Packer Template

The `make template` command generates the packer template but does not actually run the packer build process, instead simply outputting the generate `packer.json` file to the console.  This is useful for troubleshooting the packer template generation process.

```
$ make template
=> Creating packer image...
Step 1 : FROM alpine
latest: Pulling from library/alpine
...
...
2017-01-20T00:08:54Z ccb09ec4cbe2 confd[7]: INFO Backend set to env
2017-01-20T00:08:54Z ccb09ec4cbe2 confd[7]: INFO Starting confd
2017-01-20T00:08:54Z ccb09ec4cbe2 confd[7]: INFO Backend nodes set to
2017-01-20T00:08:54Z ccb09ec4cbe2 confd[7]: INFO Target config /packer/packer.json out of sync
2017-01-20T00:08:54Z ccb09ec4cbe2 confd[7]: INFO Target config /packer/packer.json has been updated
{
  "variables": {
    "aws_access_key": "{{env `AWS_ACCESS_KEY_ID`}}",
    "aws_secret_key": "{{env `AWS_SECRET_ACCESS_KEY`}}",
    "aws_session_token": "{{env `AWS_SESSION_TOKEN`}}"
  },
  "builders": [
    {
      "type": "amazon-ebs",
      "access_key": "{{user `aws_access_key`}}",
      "secret_key": "{{user `aws_secret_key`}}",
      "token": "{{user `aws_session_token`}}",
      "region": "us-west-2",
      "source_ami": "ami-5b6dde3b",
      "instance_type": "t2.micro",
      "ssh_username": "ec2-user",
      "ami_name": "Casecommons ECS Base Image 20170120130847.b663897",
      "security_group_id": "",
      "associate_public_ip_address": "true",
      "tags": {
        "Name": "Casecommons ECS Base Image",
        "Version": "20170120130847.b663897",
        "Source": "ami-5b6dde3b"
      }
    }
  ],
  "provisioners": [
    {
      "type": "shell",
      "script": "scripts/configure-timezone.sh",
      "environment_vars": [
        "TIME_ZONE=America/Los_Angeles"
      ]
    },
    {
      "type": "shell",
      "script": "scripts/install-os-packages.sh"
    },
    {
      "type": "shell",
      "script": "scripts/set-docker-opts.sh"
    },
    {
      "type": "file",
      "source": "files/firstrun.sh",
      "destination": "/home/ec2-user/firstrun.sh"
    },
    {
      "type": "shell",
      "script": "scripts/configure-cloud-init.sh"
    },
    {
      "type": "shell",
      "script": "scripts/cleanup.sh"
    }
  ],
  "post-processors": [
    {
      "type": "manifest",
      "filename": "manifest.json",
      "strip_path": true
    }
  ]
}
=> Template complete
```

## EC2 Container Instance First Run

The [`firstrun.sh`](src/files/firstrun.sh) script is designed to be executed at creation of an EC2 Container Instance based from this image, and performs the following actions:

- Configures Docker, ECS agent and CloudWatch logs for proxy operation (if `PROXY_URL` is set)
- Configures CloudWatch Logs
- Starts CloudWatch Logs, Docker and ECS agent
- Polls the [ECS agent metadata service](http://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-introspection.html) to determine if the ECS agent has successfully registered with the configured ECS cluster
- Optional pauses if the `PAUSE_TIME` environment variable is set for the number of seconds defined by `PAUSE_TIME`.

The first run script is designed to be used in conjunction with [CloudFormation helper scripts](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-helper-scripts-reference.html) as follows:

- [`cfn-init`](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-init.html) is called from the instance UserData to run the [`firstrun.sh`](src/files/firstrun.sh) script.  The `AWS::CloudFormation::Init` metadata for the instance must inject the environment variables the script requires to run correctly.

- [`cfn-signal`](http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-signal.html) is called from the instance UserData after running `cfn-init` to signal the `SUCCESS` or `FAILURE` of the [`firstrun.sh`](src/files/firstrun.sh) script.  CloudFormation uses this signal to determine if the EC2 Container Instance initialization was successful or failed.

### First Run Script Environment Variables

The [`firstrun.sh`](src/files/firstrun.sh) script expects the following environment variables to be set:

| Environment Variable | Description                                                                                                                                                                                                                                                                                                      | Required | Example                           |
|----------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------|-----------------------------------|
| AUTOSCALING_GROUP    | The name of the autoscaling group that you want present in CloudWatch log groups that the EC2 container instance will publish logs to.                                                                                                                                                                           | Yes      | ApplicationAutoscaling            |
| ECS_CLUSTER          | The name of the ECS cluster that the EC2 container instance belongs to.  This must be set correctly to ensure the EC2 container instance is able to join the correct ECS cluster.  In general you will configure this as a reference to the ECS cluster resource in your stack                                   | Yes      | { "Ref": "ApplicationCluster" }   |
| STACK_NAME           | The name of the CloudFormation stack the EC2 container instance belongs to.  This will be included in CloudWatch log group names that the EC2 container instance will publish logs to. In general, you will configure this using the Fn::Sub intrinsic function referencing the AWS::StackName pseudo parameter. | Yes      | { "Fn::Sub": "${AWS::StackName} } |
| AWS_DEFAULT_REGION   | The region in which the CloudWatch log groups for the EC2 container instance reside.  In general, you will configure this using the Fn::Sub intrinsic function referencing the AWS::Region pseudo parameter.                                                                                                     | Yes      | { "Fn::Sub": "${AWS::Region} }    |
| PROXY_URL            | The URL of the HTTP/HTTPS proxy the EC2 container instance should use.                                                                                                                                                                                                                                           | No       | http://squid.example.org:3128     |
| PAUSE_TIME           | Optional amount of time to pause in seconds before completing the init script and signalling success to CloudFormation.                                                                                                                                                                                          | No       | 60                                |

## Example Configuration

The following sample CloudFormation resource configuration demonstrates how to correctly invoke the ECS agent check script:

```
AutoscalingLaunchConfiguration:
  Metadata:
    AWS::CloudFormation::Init:
      config:
        commands:
          01_first_run:
            command: "sh firstrun.sh"
            env:
              PROXY_URL: { "Ref": "MyVpcProxyURL" }
              ECS_CLUSTER: { "Ref": "ApplicationCluster" }
              AUTOSCALING_GROUP: "Autoscaling"
              STACK_NAME:
                Fn::Sub: "${AWS::StackName}"
              AWS_DEFAULT_REGION:
                Fn::Sub: "${AWS::Region}"
              PAUSE_TIME: 60
            cwd: "/home/ec2-user/"
  Properties:
    UserData:
      Fn::Base64:
        Fn::Join: ["\n", [
          "#!/bin/bash",
          "Fn::Sub": "/opt/aws/bin/cfn-init -v --stack ${AWS::StackName} --resource AutoscalingLaunchConfiguration --region ${AWS::Region} --http-proxy ${MyVpcProxyURL} --https-proxy ${MyVpcProxyURL}"
          "Fn::Sub": "/opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource Autoscaling --region ${AWS::Region} --http-proxy ${MyVpcProxyURL} --https-proxy ${MyVpcProxyURL}"
      ] ]
```

## Release Notes

### Version 0.1.0

- **NEW FEATURE** : Updated makefile for cbp-dev
- **NEW FEATURE** : Added 169.254.170.2 as detailed here http://docs.aws.amazon.com/AmazonECS/latest/developerguide/http_proxy_config.html due to tcp_denied issues with proxy

## License

Copyright (C) 2017.  Case Commons, Inc.

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.

See www.gnu.org/licenses/agpl.html
