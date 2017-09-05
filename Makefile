# Project variables
export PROJECT_NAME ?= packer

# AWS security settings
AWS_ROLE ?= arn:aws:iam::334274607422:role/admin
AWS_SG_NAME ?= packer-$(firstword $(subst /, ,$(MY_IP_ADDRESS)))-$(TIMESTAMP)
AWS_SG_DESCRIPTION ?= "Temporary security group for Packer"

# Packer settings
export PACKER_VERSION ?= 0.12.3
export AMI_NAME ?= Casecommons ECS Base Image
export AMI_USERS ?=
export AMI_REGIONS ?=
export APP_VERSION ?= $(TIMESTAMP).$(COMMIT_ID)
export AWS_INSTANCE_TYPE ?= t2.micro
export AWS_DEFAULT_REGION ?= us-east-1
export AWS_SSH_USERNAME ?= ec2-user
export AWS_SOURCE_AMI ?= ami-04351e12

# Common settings
include Makefile.settings

.PHONY: release template clean

# Builds image using packer
release:
	@ ${INFO} "Starting packer build..."
	@ $(if $(or $(AWS_PROFILE),$(AWS_DEFAULT_PROFILE)),$(call assume_role,$(AWS_ROLE)),)
	@ ${INFO} "Creating packer security group..."
	@ $(call create_packer_security_group,$(AWS_SG_NAME),$(AWS_SG_DESCRIPTION),$(MY_IP_ADDRESS),$(AWS_VPC_ID))
	@ ${INFO} "Creating packer image..."
	@ docker-compose $(RELEASE_ARGS) build $(PULL_FLAG) packer
	@ ${INFO} "Running packer build..."
	@ docker-compose $(RELEASE_ARGS) up packer
	@ ${INFO} "Deleting packer security group..."
	@ $(call delete_packer_security_group,$(AWS_SG_NAME))
	@ ${INFO} "Deleted packer security group..."
	@ $(call check_exit_code,$(RELEASE_ARGS),packer)
	@ rm -rf build
	@ mkdir -p build
	@ docker cp $$(docker-compose $(RELEASE_ARGS) ps -q packer):/packer/manifest.json build/
	@ docker cp $$(docker-compose $(RELEASE_ARGS) ps -q packer):/packer/build.log build/
	@ $(call transform_manifest,build/manifest.json,build/images.json)
	@ ${INFO} "Build complete"

# Generates packer template to stdout
template:
	@ ${INFO} "Creating packer image..."
	@ docker-compose $(RELEASE_ARGS) build $(PULL_FLAG) packer 2>/dev/null
	@ ${INFO} "Creating packer template..."
	@ docker-compose $(RELEASE_ARGS) run packer cat /packer/packer.json 2>/dev/null
	@ ${INFO} "Template complete"

# Cleans environment
clean:
	${INFO} "Destroying release environment..."
	@ docker-compose $(RELEASE_ARGS) down -v 2>/dev/null || true
	${INFO} "Removing dangling images..."
	@ $(call clean_dangling_images,$(PROJECT_NAME))
	${INFO} "Clean complete"