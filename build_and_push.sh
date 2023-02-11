#!/usr/bin/env bash

# This script shows how to build the Docker image and push it to ECR to be ready for use
# by SageMaker.

# Arguments are image-name and optional tag which defaults to latest
image=$1
tag=$2

if [ "$image" == "" ]
then
    echo "Usage: $0 <image-name> <tag (optional)>"
    exit 1
fi

if [ "$tag" == "" ]
then
    tag="latest"
fi


# Get the account number associated with the current IAM credentials
account=$(aws sts get-caller-identity --query Account --output text)

if [ $? -ne 0 ]
then
    exit 255
fi


# Get the region defined in the current configuration (default to us-west-2 if none defined)
region=$(aws configure get region)
region=${region:-us-west-2}


# Fullname
fullname="${account}.dkr.ecr.${region}.amazonaws.com/${image}:${tag}"
echo ${fullname}


# If the repository doesn't exist in ECR, create it.
aws ecr describe-repositories --repository-names "${image}" > /dev/null 2>&1

if [ $? -ne 0 ]
then
    aws ecr create-repository --repository-name "${image}" > /dev/null
fi


# Get the login command from ECR and execute it directly
aws ecr get-login-password --region "${region}" | docker login --username AWS --password-stdin "${account}".dkr.ecr."${region}".amazonaws.com

aws ecr get-login-password --region "${region}" | docker login --username AWS --password-stdin
763104351884.dkr.ecr."${region}".amazonaws.com


# Build the docker image locally with the image name and then push it to ECR
# with the full name.
docker build  -t ${image} .
docker tag ${image} ${fullname}

docker push ${fullname}
