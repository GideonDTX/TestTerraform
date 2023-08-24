# vcn

## Resources

### Bastion

* Creates the `oci_core_network_security_group.bastion` resource even if we don't create bastion instance. This allows other resources to rules for the host whether it exists or not. Then, if the host is brought up in an emergency, everything will work with just an update of the stack that is created this module (without having to update other stacks).
