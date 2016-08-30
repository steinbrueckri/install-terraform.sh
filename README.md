# install-terraform.sh

Handy script for installing Terraform on Linux
Forked from https://github.com/pinterb/install-terraform.sh

Since I needed to handle more than one "current" version of terraform I slightly modified the original to install and use multiple versions.

The script will download always the latest version (ie the first link listed on the [release page](https://releases.hashicorp.com/terraform/)).

The install path will be `/opt/terraform/<version>`.
A `.terraform` file will be (re)created each time to define a simple wrapper function to be able to use the correct version for each terraform stack.
Be sure to source that in your .bash_profile/.bashrc.

In your stacks just create an empty file with the version number that you want to use for that stack, for example:

    $ cd my_new_stack
    $ touch 0.6.16
    $ terraform plan
    Terraform wrapper: found 0.6.16
    [...]


Will use the terraform executable from `/opt/terraform/0.6.16/terraform`
