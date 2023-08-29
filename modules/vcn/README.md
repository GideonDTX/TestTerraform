# vcn


## Notes about Resources

### Route Tables

* The OCI Route Table API apparently does not manage route table entries separately. In both the Terraform and the OCI console, if you change anything (add/remove a route rule) in the route table, the request will remove and recreate the entire list. This would normally not be a problem however, A) the DRG routes have to be added directly by the Cloud Services administrators and B) anyone with just comparment level administrator rights can not remove/add/update them. This means ny further route table updates AFTER the DRG routes are added will have be requested from the Cloud Services administrators and then modified in the module instantiation to match those rules. Otherwise the module update will fail.

### Bastion

* Creates the `oci_core_network_security_group.bastion` resource even if we don't create bastion instance. This allows other resources to rules for the host whether it exists or not. Then, if the host is brought up in an emergency, everything will work with just an update of the stack that is created this module (without having to update other stacks).
