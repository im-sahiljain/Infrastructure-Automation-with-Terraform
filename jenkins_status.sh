#!/bin/bash



instance_ip=$1
private_key_file=$2

jenkins_status=$(ssh -i "$private_key_file" ec2-user@"$instance_ip" sudo systemctl is-active jenkins)
echo "{\"jenkins_status\":\"$jenkins_status\"}"

