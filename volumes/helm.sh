#!/bin/bash

helm upgrade --install volumes ./

echo "Might need to go on the Longhorn UI and attach the volume to the node."