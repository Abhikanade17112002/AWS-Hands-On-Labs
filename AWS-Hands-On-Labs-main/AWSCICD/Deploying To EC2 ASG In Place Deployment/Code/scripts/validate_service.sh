#!/bin/bash
set -e
# Check if the application is responding
curl -f http://localhost:8080/actuator/health || exit 1
echo "ValidateService hook completed."