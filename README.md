# Metal Client

Manage Cluster Network Boot and DHCP Files

## Overview

## Installation

### Preconditions

The following are required to run this application:

* OS:     Centos7
* Ruby:   2.6+
* Bundler

### Manual installation

Start by cloning the repo, adding the binaries to your path, and install the gems:

```
git clone https://github.com/openflighthpc/metal-client
cd metal-client
bundle install --without development test --path vendor
```

### Configuration

These application needs a couple of configuration parameters to specify which server to communicate with. Refer to the [reference config](etc/config.yaml.reference) for the required keys. The configs needs to be stored within `etc/config.yaml`.

```
cd /path/to/client
touch etc/config.yaml
vi etc/config.yaml
```

## Basic Usage

The following is a guide on how to build a single node using `metal-client`. This example is for a UEFI node but legacy BIOS base builds are also supported.

```
# First upload the kickstart file
> bin/metal kickstart create foo /path/to/kickstart

# Upload the uefi PXE boot file
> bin/metal uefibootmenu create 01-aa-bb-cc-dd-ee-ff /path/to/uefi-pxe

# Upload the kernel and initial ram disk for the build
> bin/metal bootmethod create foobar
> bin/metal bootmethod upload-kernel foobar /path/to/kernel
> bin/metal bootmethod upload-initrd foobar /path/to/initrd

# Next the node's DHCP subnet needs to be setup. This file needs to include the
# hosts file path returned by the server. The `edit` command can be used to get
# around the chicken and egg problem
> bin/metal dhcpsubnet create bar-subnet /path/to/empty/file

# Now open the subnet and include the "hosts-path" returned above:
> bin/metal dhcpsubnet edit bar-subnet
... Opens in system editor ...
include "/path/to/content/etc/dhcp/current/hosts/subnet.bar-subnet.conf";
... Close the system editor ...

# Finally add the DHCP entry for the host within the subnet
> bin/metal dhcphost create bar-subnet foo-host /path/to/subnet/file

# The node is now ready to be booted and built
```

# Contributing

Fork the project. Make your feature addition or bug fix. Send a pull
request. Bonus points for topic branches.

Read [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

# Copyright and License

Creative Commons Attribution-ShareAlike 4.0 License, see [LICENSE.txt](LICENSE.txt) for details.

Copyright (C) 2019-present Alces Flight Ltd.

You should have received a copy of the license along with this work.
If not, see <http://creativecommons.org/licenses/by-sa/4.0/>.

![Creative Commons License](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)

Metal Client is licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/).

Based on a work at [https://github.com/openflighthpc/openflight-tools](https://github.com/openflighthpc/openflight-tools).

This content and the accompanying materials are made available available
under the terms of the Creative Commons Attribution-ShareAlike 4.0
International License which is available at [https://creativecommons.org/licenses/by-sa/4.0/](https://creativecommons.org/licenses/by-sa/4.0/),
or alternative license terms made available by Alces Flight Ltd -
please direct inquiries about licensing to
[licensing@alces-flight.com](mailto:licensing@alces-flight.com).

Metal Client is distributed in the hope that it will be useful, but
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS OF
TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A PARTICULAR
PURPOSE. See the [Creative Commons Attribution-ShareAlike 4.0
International License](https://creativecommons.org/licenses/by-sa/4.0/) for more
details.
