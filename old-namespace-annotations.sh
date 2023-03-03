#!/bin/bash

set -e

if ! command -v oc &> /dev/null; then
    echo "oc command not found. Please make sure OpenShift is installed and oc is in your PATH." >&2
    exit 1
fi

ANNOTATION_NAME="${ANNOTATION_NAME:-splunk.com/index}"
FILE=${1:-"namespaces.txt"}
DRY_RUN=${DRY_RUN:-false}

if [ -z "$FILE" ]; then
    echo "Error: No input file specified." >&2
    exit 1
fi

if [ -z "$ANNOTATION_NAME" ]; then
    echo "Error: No annotation name specified." >&2
    exit 1
fi

while IFS=' ' read -r namespace index_name; do
    if [[ -z "$namespace" || -z "$index_name" ]]; then
        echo "Error: Invalid input file. Each line of the file must contain two fields separated by a space." >&2
        exit 1
    fi

    if [[ $(oc get namespace "$namespace" -o json | jq -r ".metadata.annotations.\"${ANNOTATION_NAME}\"") == "$index_name" ]]; then
        echo "Skipping namespace: $namespace"
    else
        echo "Annotating namespace: $namespace"
        if [ "$DRY_RUN" = true ]; then
            oc annotate namespace "$namespace" "${ANNOTATION_NAME}=${index_name}" --dry-run=client -o yaml
        else
            if ! oc annotate namespace "$namespace" "${ANNOTATION_NAME}=${index_name}" --dry-run=client -o yaml | oc apply -f -; then
                echo "Error: Failed to annotate namespace '$namespace'." >&2
                exit 1
            fi
        fi
    fi
done < "$FILE"