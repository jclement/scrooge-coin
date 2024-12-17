#!/bin/bash

ENV_FILE=".env"

if [ ! -f "$ENV_FILE" ]; then
    echo "$ENV_FILE does not exist. Creating a default $ENV_FILE."
    cp env-sample $ENV_FILE
fi