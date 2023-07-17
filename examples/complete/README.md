# Complete example with BYOK encryption, autoscaling, and service credential creation

An end-to-end example that provisions the following infrastructure:

- A resource group, if one is not passed in.
- A Key Protect instance with a root key.
- An instance of Databases for etcd with BYOK encryption and autoscaling.
- Service credentials for the database instance.
