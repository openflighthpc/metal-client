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
{
  "type"=>"kickstarts",
  "id"=>"foo",
  "size"=><size>,
  "system-path"=>"/some/path/to/kickstarts/foo.ks",
  "uploaded"=>true,
  "payload"=>"<kickstart-file-content>",
  "download_url"=>"http://example.com/kickstarts/foo/blob"
}
# NOTE: The download_url can be curled to directly download the kickstart file
# There is no authorization on this route so it can be used in the PXE boot

# Upload the uefi PXE boot file
> bin/metal uefibootmenu create 01-aa-bb-cc-dd-ee-ff /path/to/uefi-pxe
{
  "type"=>"uefis",
  "id"=>"01-aa-bb-cc-dd-ee-ff",
  "payload"=>"<uefi-file-content>",
  "size"=><size>,
  "system-path"=>"/path/to/efi/grub.cfg/grub.cfg-01-aa-bb-cc-dd-ee-ff",
  "uploaded"=>true
}

# Upload the kernel and initial ram disk for the build
> bin/metal bootmethod create foobar
{
  "type"=>"boot-methods",
  "id"=>"foobar",
  "complete"=>false,
  "kernel-system-path"=>"/some/path/to/boot/kernel-foobar",
  "initrd-system-path"=>"/some/path/to/boot/initrd-foobar",
  "kernel-size"=>0,
  "initrd-size"=>0,
  "kernel-uploaded"=>false,
  "initrd-uploaded"=>false
}
> bin/metal bootmethod upload-kernel foobar /path/to/kernel
> bin/metal bootmethod upload-initrd foobar /path/to/initrd
{
  "type"=>"boot-methods",
  "id"=>"foobar",
  "complete"=>true,
  "kernel-system-path"=>"/some/path/to/boot/kernel-foobar",
  "initrd-system-path"=>"/some/path/to/boot/initrd-foobar",
  "kernel-size"=><kernel-size>,
  "initrd-size"=><initrd-size>,
  "kernel-uploaded"=>true,
  "initrd-uploaded"=>true
}

# Next the node's DHCP subnet needs to be setup. This file needs to include the
# hosts file path returned by the server. The `edit` command can be used to get
# around the chicken and egg problem
> bin/metal dhcpsubnet create bar-subnet /path/to/empty/file
{
  "type"=>"dhcp-subnets",
  "id"=>"bar-subnet",
  "payload"=>"",
  "size"=>0,
  "system-path"=>
   "/path/to/content/etc/dhcp/current/subnets/bar-subnet.conf",
  "uploaded"=>true,
  "hosts-path"=>
   "/path/to/content/etc/dhcp/current/hosts/subnet.bar-subnet.conf"}
 }

# Now open the subnet and include the "hosts-path" returned above:
> bin/metal dhcpsubnet edit bar-subnet
... Opens in system editor ...
include "/path/to/content/etc/dhcp/current/hosts/subnet.bar-subnet.conf";
... Close the system editor ...

# Finally add the DHCP entry for the host within the subnet
> bin/metal dhcphost create bar-subnet foo-host /path/to/subnet/file
{
  "type"=>"dhcp-hosts",
  "id"=>"bar-subnet.foo-host",
  "payload"=>"<dhcp-host-content>",
  "size"=><size>,
  "system-path"=>
   "/opt/flight/opt/metal-server/var/etc/dhcp/current/hosts/bar-subnet/foo-host.conf",
  "uploaded"=>true
}

# The node is now ready to be booted and built
```

## Known Issues

### Update a record with the same file

When a record is updated with the same file content, the `payload` is not sent with the request. This triggers an error condition on the server resulting in error along these lines. This is a known bug which will be fixed in future implementations of the server.

```
> metal kickstart update foo /tmp/test 
metal: The payload attribute is required with this request
```

This error can also be raised during an `edit` if the file hasn't changed.

### Full error handling has not been implemented

There will be cases where the server response with various error codes: `400`, `401`, `403`, `409`, and occasionally `500`. Generic error handling is provided by the underlining `JsonApiClient` and does not completely align with the server's usage. This is particularly apparent when `409` is raised.

Full error handling will be implemented when the server `response` specification has been updated.

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
