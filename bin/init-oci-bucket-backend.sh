#!/usr/bin/env bash

#
# Creates a bucket in OCI Object Storage to provide remote state storage to Terraform.
# This is a bootstrap that is needed to get Terraform started. There shouldn't be a
# need to run this in the future. It is provided mostly for reference.
#

# requires jq command

usage() {
  echo "Usage: init-oci-bucket-backend.sh -c COMPARTMENT_ID -n BUCKET_NAME"
}

check_for_deps() {
  JQ=$(which jq 2> /dev/null)
  [ -z "$JQ" ] && echo "Requires jq command" && exit 1
}

check_for_args() {
  [ -z "$COMPARTMENT_ID" -o -z "$BUCKET_NAME" ] && usage && exit 1
}

while getopts c:n:h OPTFLAG; do
  case "${OPTFLAG}" in
    c)
      COMPARTMENT_ID=${OPTARG}
      ;;
    n)
      BUCKET_NAME=${OPTARG}
      ;;
    h)
      usage
      exit
      ;;
    :)
      echo "Error: -${OPTARG} requires an argument"
      exit 1
      ;;
    *)
      echo "Error: Unknown argument provided"
      exit 1
      ;;
  esac
done

check_for_args
check_for_deps

echo "Creating $BUCKET_NAME in $COMPARTMENT_ID"

# check to see if the bucket name already exists in the compartment
export BUCKET_NAME
BUCKET_NAME_EXISTS=$(oci os bucket list --all --compartment-id $COMPARTMENT_ID | jq -r '.data[] | select(.name==env.BUCKET_NAME)')
[ -n "$BUCKET_NAME_EXISTS" ] && echo "Error: Bucket name $BUCKET_NAME already exists in $COMPARTMENT_ID" && exit 1

oci os bucket create \
  --compartment-id $COMPARTMENT_ID \
  --name $BUCKET_NAME \
  --versioning "Enabled" \
  --public-access-type "NoPublicAccess"
