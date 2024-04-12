# tf_opennms_rocky
Install OpenNMS Horizon on Rocky

Please Note that the pq_hba.conf has been set to "trust".  This should be changed in a production environment.

This repo creates a VPC and one EC2 server on AWS using Terraform
The Ansible playbook/opennms is called and deploys OpenNMS Horizon.

The output includes the public ip address of the EC2 server with the port set for opennms.

To access the OpenNMS UI, please use the output string

when destroying the instance, the ip address will have to be removed from the aws_hosts file
