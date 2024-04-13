# tf_opennms_rocky
Install OpenNMS Horizon on Rocky Linux

Please Note that the pq_hba.conf has been set to "trust".  This should be changed in a production environment.

This repo creates a VPC and one EC2 server on AWS using Terraform
The Ansible playbook/opennms is called and deploys OpenNMS Horizon with all necessary dependencies.

The output includes the public ip address of the EC2 server with the port set for opennms.

To access the OpenNMS UI, please use the output string provided when Terraform apply has been completed.

When destroying the instance, the ip address of the dstroyed will have to be removed from the aws_hosts file.
