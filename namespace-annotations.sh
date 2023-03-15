#!/bin/bash

# Script to annotate OpenShift namespaces with an index name using a specified annotation key.


set -o errexit
set -o pipefail
set -o nounset

cleanup() {
  exit_code=$?
  if [ $exit_code -ne 0 ]; then
    echo "An error occurred. Exiting with code $exit_code." >&2
  else
    echo "Script completed successfully."
  fi
}

trap cleanup EXIT

usage() {
  echo "Usage: $0 [--file FILE] [--annotation-key KEY] [--annotation-value VALUE] [--dry-run]"
  echo "  --file FILE: input file containing a list of namespaces and index names (default: namespaces.txt)"
  echo "  --annotation-key KEY: key for the annotation that stores the index name (default: splunk.com/index)"
  echo "  --annotation-value VALUE: value to annotate the namespaces with (if not specified, reads from input file)"
  echo "  --dry-run: boolean flag indicating whether to perform a dry run (default: false)"
}

# Set default values for parameters
FILE="namespaces.txt"
ANNOTATION_KEY="splunk.com/index"
ANNOTATION_VALUE=""
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -f|--file)
      FILE="$2"
      shift 2
      ;;
    -a|--annotation-key)
      if ! echo "$2" | grep -qE '^[a-zA-Z_][a-zA-Z0-9_]*$'; then
        echo "Invalid annotation key: $2" >&2
        exit 1
      fi
      ANNOTATION_KEY="$2"
      shift 2
      ;;
    -v|--annotation-value)
      ANNOTATION_VALUE="$2"
      shift 2
      ;;
    -d|--dry-run)
      DRY_RUN=true
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "Invalid option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

# Check that required commands are installed
if ! command -v oc >/dev/null 2>&1; then
  echo >&2 "Error: 'oc' command not found. Aborting."
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo >&2 "Error: 'jq' command not found. Aborting."
  exit 1
fi

# Check that input file exists
if [ ! -f "$FILE" ]; then
  echo "Error: Input file '$FILE' not found." >&2
  usage
  exit 1
fi

# Loop through namespaces and annotate them if necessary
while read -r line; do
  # Skip empty lines or lines with only whitespace
  if [[ -z "${line// /}" ]]; then
    continue
  fi

  #namespace=$(echo "$line" | cut -d' ' -f1)
  #index_name=$(echo "$line" | cut -d' ' -f2-)
  
  
  namespace=$(echo "$line" | awk '{print $1}')
  index_name=$(echo "$line" | awk '{$1=""; print substr($0, 2)}')

  # Check for valid input
  if [[ -z "$namespace" ]]; then
    echo "Error: Invalid input file. Each line of the file must contain at least one field separated by a space." >&2
    usage
    exit 1
  fi

 #current_annotation=$(oc get namespace "$namespace" -o json | jq -r ".metadata.annotations.\"${ANNOTATION_KEY}\"" || true)
      
  # Get the current annotation value
  current_annotation=$(oc get namespace "$namespace" -o json | grep -oP "(?<=\"$ANNOTATION_KEY\": \")[^\"]*" || true)

  # Check if the current annotation value matches the one in the input file
  if [[ "$current_annotation" == "$index_name" ]]; then
    echo "Namespace '$namespace' already has the '$ANNOTATION_KEY' annotation with the value '$index_name'. Skipping."
    continue
  else
    if [ "$DRY_RUN" = true ]; then
      echo "Dry run: Annotating namespace '$namespace' with the '$ANNOTATION_KEY' annotation and value '$index_name'."
      oc annotate namespace "$namespace" "${ANNOTATION_KEY}=${index_name}" --dry-run=client -o yaml || true
    else
      echo "Updating namespace '$namespace' with the new '$ANNOTATION_KEY' annotation value '$index_name'."
      if ! oc annotate namespace "$namespace" "${ANNOTATION_KEY}=${index_name}"; then
        echo "Error: Failed to annotate namespace '$namespace'." >&2 || true
        continue
      fi
    fi
  fi
done < "$FILE"

