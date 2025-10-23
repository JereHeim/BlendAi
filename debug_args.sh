#!/bin/bash

# Quick debug script to test the argument parsing
echo "Testing argument parsing..."

prompt=""
description=""
reference_image=""
output_dir="/tmp/test_output"

# Parse arguments like the main script does
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo "Help requested"
            exit 0
            ;;
        -d|--description)
            description="$2"
            shift 2
            ;;
        -r|--reference)
            reference_image="$2"
            shift 2
            ;;
        -o|--output)
            output_dir="$2"
            shift 2
            ;;
        *)
            if [ -z "$prompt" ]; then
                prompt="$1"
                echo "Set prompt to: '$prompt'"
            fi
            shift
            ;;
    esac
done

echo "Final values:"
echo "prompt='$prompt'"
echo "description='$description'"
echo "reference_image='$reference_image'"
echo "output_dir='$output_dir'"

if [ -n "$prompt" ]; then
    echo "Would call: generate_model '$prompt' '$description' '$output_dir' '$reference_image'"
else
    echo "ERROR: No prompt provided"
fi