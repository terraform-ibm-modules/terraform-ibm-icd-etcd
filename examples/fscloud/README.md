# Financial Services Cloud profile example with autoscaling enabled

An end-to-end example that uses the [Profile for IBM Cloud Framework for Financial Services](../../modules/fscloud/) to deploy an instance of IBM Cloud Databases for etcd DB.

The example uses the IBM Cloud Terraform provider to create the following infrastructure:

- A resource group, if one is not passed in.
- An IAM authorization between all etcd database instances in the given resource group, and the Hyper Protect Crypto Services instance that is passed in.
- An IBM Cloud Databases etcd database instance that is encrypted with the Hyper Protect Crypto Services root key that is passed in.
- Autoscaling rules for the IBM Cloud Databases etcd database instance.
- Service Credentials for the etcd database instance.
- A sample virtual private cloud (VPC).
- A context-based restriction (CBR) rule to only allow etcd to be accessible from within the VPC.

:exclamation: **Important:** In this example, only the IBM Cloud Databases for etcd instance complies with the IBM Cloud Framework for Financial Services. Other parts of the infrastructure do not necessarily comply.

## Before you begin

- You need a Hyper Protect Crypto Services instance and root key available in the region that you want to deploy your etcd database instance to.
