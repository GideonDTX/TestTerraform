#!/usr/bin/env bash

set -x

#
# Creates a secrets with content from file
#   * will find and use the latest MEK
#

# requires oci command
# requires jq command
# requires base64 command (to convert from regular ASCII to base64 encoded)

usage() {
  echo "Usage:"
  echo
  echo "  For creating new secret:"
  echo "    $0 -c COMPARTMENT_ID -v VAULT_ID -k KEY_ID -n SECRET_NAME -f SECRET_FILE"
  echo
  echo "  For updating existing secret:"
  echo "    $0 -c COMPARTMENT_ID -n SECRET_NAME -f SECRET_FILE [-y]"
  echo 
}

check_for_deps() {
  OCI=$(which oci 2> /dev/null)
  [ -z "${OCI}" ] && echo "Requires oci command" && exit 1
  JQ=$(which jq 2> /dev/null)
  [ -z "$JQ" ] && echo "Requires jq command" && exit 1
  BASE64=$(which base64 2> /dev/null)
  [ -z "${BASE64}" ] && echo "Requires base64 command" && exit 1
}

check_for_args() {
  [ -z "${COMPARTMENT_ID}" -o -z "${SECRET_NAME}" -o -z "${SECRET_FILE}" ] && usage && exit 1
}

while getopts c:n:v:k:f:hy OPTFLAG; do
  case "${OPTFLAG}" in
    c)
      COMPARTMENT_ID="${OPTARG}"
      ;;
    n)
      SECRET_NAME="${OPTARG}"
      ;;
    v)
      VAULT_ID="${OPTARG}"
      ;;
    k)
      KEY_ID="${OPTARG}"
      ;;
    f)
      SECRET_FILE="${OPTARG}"
      ;;
    y)
      CONFIRM_YES=true
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

check_for_deps
check_for_args

export SECRET_NAME
SECRET_NAME_EXISTS=$(${OCI} vault secret list --all --compartment-id ${COMPARTMENT_ID} | $JQ -r '.data[] | select(."secret-name"==env.SECRET_NAME)')
if [ -n "${SECRET_NAME_EXISTS}" ]; then
  LIFECYCLE_STATE=$(echo "${SECRET_NAME_EXISTS}" | $JQ -r '."lifecycle-state"')
  SECRET_ID=$(echo "${SECRET_NAME_EXISTS}" | $JQ -r '.id')
  if [ "${LIFECYCLE_STATE}" != "ACTIVE" ]; then
    echo "Error: Secret name ${BUCKET_NAME} exists in ${COMPARTMENT_ID} and is in an incompatible state: ${LIFECYCLE_STATE}" && exit 1
  else
    if [ "${CONFIRM_YES}" = "true" ]; then
      ${OCI} vault secret update-base64 \
        --secret-id "${SECRET_ID}" \
        --secret-content-content "$(cat ${SECRET_FILE} | ${BASE64} -w 0)"
    else
      read -p "WARNING: This will update existing secret, confirm? (yes/no default: no) " yn
      if [ "${yn}" = "yes" ]; then
        ${OCI} vault secret update-base64 \
          --secret-id "${SECRET_ID}" \
          --secret-content-content "$(cat ${SECRET_FILE} | ${BASE64} -w 0)"
      else
        echo "cancelling update"
      fi
    fi
  fi
else
  # requires vault id and key id
  [ -z "${VAULT_ID}" -o -z "${KEY_ID}" ] && usage && exit 1
  ${OCI} vault secret create-base64 \
    --compartment-id "${COMPARTMENT_ID}" \
    --vault-id "${VAULT_ID}" \
    --key-id "${KEY_ID}" \
    --secret-name "${SECRET_NAME}" \
    --secret-content-content "$(cat ${SECRET_FILE} | ${BASE64} -w 0)"
fi
