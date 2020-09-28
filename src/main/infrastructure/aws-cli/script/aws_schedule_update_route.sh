#!/bin/sh

# Repeat.
while true 
do 

	# Updates default route.
	aws_update_route --debug || true
	
	# Waits 2 minutes.
	sleep 120

done
