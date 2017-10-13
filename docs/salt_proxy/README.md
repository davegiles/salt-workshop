| Home           | Previous                  | Next                                        |
|----------------|---------------------------|---------------------------------------------|
| [Home](../../) | [Schedules](../schedules) | [Network Device Execution](../net_dev_exec) |

# Salt Proxy Minions

We've spent a lot of time talking about how to use Salt to manage a fleet of
Linux servers.  What if we need to manage a device that can't run a Salt Minion
process, though?  The rest of this workshop focuses on managing network devices
that traditionally cannot run a third-party process on them using Salt with the
help of Salt Proxy Minions.

Because the network device cannot run a salt minion, this will not work out of
the box.  It will require some initial configuration, as well as some additional
software on the minions that will also be home to our proxy minions.  For our
examples in this workshop, we will have two routers running Junos.
`1.sminion.learn.com` will run the `salt-proxy` process for both routers.

> There's no requirement to run all proxy processes on the same minion.  We only
> do this for this workshop because extra RAM is required in Ubuntu 14.04 to
> build the appropriate Python packages, whereas with CentOS 7 it simply works
> well with only 512M RAM.  We will set up the configuration so that the proxy
> processes could be spread across multiple minions, but accomplishing that will
> be left as an exercise for the reader.

## Setup

Before we get started, we need to set the routers up.  To help with this, a
helper script has been included.  Simply run `scripts/setupNetwork.sh`:

```
$ scripts/setupNetwork.sh
Bringing machine 'salt_master' up with 'virtualbox' provider...
Bringing machine 'salt_minion_0' up with 'virtualbox' provider...
Bringing machine 'salt_minion_1' up with 'virtualbox' provider...
Bringing machine 'rtr1' up with 'virtualbox' provider...
Bringing machine 'rtr2' up with 'virtualbox' provider...
==> salt_master: Checking if box 'ubuntu/trusty64' is up to date...
==> salt_master: Machine already provisioned. Run `vagrant provision` or use the `--provision`
==> salt_master: flag to force provisioning. Provisioners marked to run always will still run.
==> salt_minion_0: Checking if box 'ubuntu/trusty64' is up to date...
==> salt_minion_0: Machine already provisioned. Run `vagrant provision` or use the `--provision`
==> salt_minion_0: flag to force provisioning. Provisioners marked to run always will still run.
==> salt_minion_1: Checking if box 'centos/7' is up to date...
==> salt_minion_1: Machine already provisioned. Run `vagrant provision` or use the `--provision`
==> salt_minion_1: flag to force provisioning. Provisioners marked to run always will still run.
==> rtr1: Importing base box 'juniper/vqfx10k-re'...
==> rtr1: Matching MAC address for NAT networking...
==> rtr1: Checking if box 'juniper/vqfx10k-re' is up to date...
==> rtr1: Setting the name of the VM: saltstack-cluster_rtr1_1507858630832_49938
==> rtr1: Fixed port collision for 22 => 2222. Now on port 2202.
==> rtr1: Clearing any previously set network interfaces...
==> rtr1: Preparing network interfaces based on configuration...
    rtr1: Adapter 1: nat
    rtr1: Adapter 2: intnet
==> rtr1: Forwarding ports...
    rtr1: 22 (guest) => 2202 (host) (adapter 1)
==> rtr1: Running 'pre-boot' VM customizations...
==> rtr1: Booting VM...
==> rtr1: Waiting for machine to boot. This may take a few minutes...
    rtr1: SSH address: 127.0.0.1:2202
    rtr1: SSH username: vagrant
    rtr1: SSH auth method: private key
==> rtr1: Machine booted and ready!
==> rtr1: Checking for guest additions in VM...
    rtr1: No guest additions were detected on the base box for this VM! Guest
    rtr1: additions are required for forwarded ports, shared folders, host only
    rtr1: networking, and more. If SSH fails on this machine, please install
    rtr1: the guest additions and repackage the box to continue.
    rtr1:
    rtr1: This is not an error message; everything may continue to work properly,
    rtr1: in which case you may ignore this message.
==> rtr2: Importing base box 'juniper/vqfx10k-re'...
==> rtr2: Matching MAC address for NAT networking...
==> rtr2: Checking if box 'juniper/vqfx10k-re' is up to date...
==> rtr2: Setting the name of the VM: saltstack-cluster_rtr2_1507858714817_6309
==> rtr2: Fixed port collision for 22 => 2222. Now on port 2203.
==> rtr2: Clearing any previously set network interfaces...
==> rtr2: Preparing network interfaces based on configuration...
    rtr2: Adapter 1: nat
    rtr2: Adapter 2: intnet
==> rtr2: Forwarding ports...
    rtr2: 22 (guest) => 2203 (host) (adapter 1)
==> rtr2: Running 'pre-boot' VM customizations...
==> rtr2: Booting VM...
==> rtr2: Waiting for machine to boot. This may take a few minutes...
    rtr2: SSH address: 127.0.0.1:2203
    rtr2: SSH username: vagrant
    rtr2: SSH auth method: private key
==> rtr2: Machine booted and ready!
==> rtr2: Checking for guest additions in VM...
    rtr2: No guest additions were detected on the base box for this VM! Guest
    rtr2: additions are required for forwarded ports, shared folders, host only
    rtr2: networking, and more. If SSH fails on this machine, please install
    rtr2: the guest additions and repackage the box to continue.
    rtr2:
    rtr2: This is not an error message; everything may continue to work properly,
    rtr2: in which case you may ignore this message.
Entering configuration mode
configuration check succeeds
commit complete
Exiting configuration mode
Entering configuration mode
configuration check succeeds
commit complete
Exiting configuration mode
```

If you want to actually log into the network devices, you'll need to export the
`SALT_NETWORK` environment variable:

```
$ export SALT_NETWORK=1
$ vagrant ssh rtr1
Last login: Thu Oct 12 12:29:05 2017 from 10.0.2.2
--- JUNOS 15.1X53-D63.9 built 2017-04-01 20:45:26 UTC
{master:0}
vagrant@rtr1>
```

This was done so that the routers are only brought up if you want to go through
this portion of the workshop, in addition to only bringing them up once you get
to this point.

## NAPALM

In order to communicate with our routers, we're going to use NAPALM.
Fortunately, thanks to the fantastic work of Mircea Ulinic, SaltStack ships with
native NAPALM support.  We just need to install the necessary Python
dependencies on the minions that will run the proxy processes.  In our case,
we're only doing this on the CentOS 7 minion.

## Formula Installation

To accomplish our goals, we're going to use two SaltStack formulas: `epel` and
`napalm_install`.  We need the `epel` formula in order to install some of the
packages required by `napalm_install`.  To enable these two formulas, simply
ensure that you have `git` as a `fileserver_backend` and list the repositories
under `gitfs_remotes` in your `/etc/salt/master` configuration on the Salt
Master:

```yaml
fileserver_backend:
  - git
  - roots

gitfs_remotes:
  - https://github.com/saltstack-formulas/epel-formula
  - https://github.com/saltstack-formulas/napalm-install-formula
```

> As mentioned in the section on formulas, this is not a best practice as it
> will leave you vulnerable to unpredictable changes in the upstream negatively
> impacting your SaltStack infrastructure.  Instead, you should fork the
> repositories and use the forks that you control.

As usual, you need to restart the master with `sudo service salt-master restart`
for these changes to take effect.

## CentOS-Specific Changes

Unfortunately, CentOS 7 will report errors because the map lookups for RedHat
indicate the package name `python-pip`.  In CentOS 7, though, the package name
is `python2-pip`.  While it will functionally still work, it does report as a
failure.  So let's fix that by creating a pillar for CentOS 7 minions.  Create
`/srv/pillar/centos.sls` and add the following contents to it:

```yaml
# file: /srv/pillar/centos.sls

napalm:
  # In CentOS, 7 the package for `pip` is `python2-pip`
  # note we're only overiding the junos packages because that's all the
  # workshop uses
  junos:
    - python2-pip
    - python-devel
    - libxml2-devel
    - libxslt-devel
    - gcc
    - openssl
    - openssl-devel
    - libffi-devel
```

> It appears that the `napalm_install` formula currently does not follow best
> common practices with map overrides.  However, this will work.

Now, add this to your Pillar topfile:

```yaml
# file: /srv/pillar/top.sls

base:
  'G@os:CentOS':
    - centos
```

This will ensure our changes only go to a CentOS 7 minion.

## Configuring the NAPALM Formula

Now, we need to tell the `napalm_install` formula what NAPALM Python packages we
need.  In this workshop, we're working solely with Junos, so we'll only
configure the `napalm-junos` Python package to be installed.  Let's do that with
a new pillar file, `/srv/pillar/napalm.sls`:

```yaml
# file: /srv/pillar/napalm.sls

napalm:
  install:
    - junos
```

We're going to be lazy and just apply the pillar to all minions, even though not
all minions will be Salt Proxies.  Let's do that in our pillar topfile,
`/srv/pillar/top.sls`:

```yaml
# file: /srv/pillar/top.sls

base:
  '*':
    - napalm
```

Great!  Now we've made some pillar changes, so let's make sure we get those
pushed down to the minions:

```
$ sudo salt '*' saltutil.refresh_pillar
1.sminion.learn.com:
    True
0.sminion.learn.com:
    True
smaster.learn.com:
    True
$ sudo salt '*' pillar.items
smaster.learn.com:
    ----------
    napalm:
        ----------
        install:
            - junos
0.sminion.learn.com:
    ----------
    napalm:
        ----------
        install:
            - junos
1.sminion.learn.com:
    ----------
    napalm:
        ----------
        install:
            - junos
        junos:
            - python2-pip
            - python-devel
            - libxml2-devel
            - libxslt-devel
            - gcc
            - openssl
            - openssl-devel
            - libffi-devel
    salt_proxy_names:
        - rtr1
        - rtr2
```

Great!  Our pillar work is done for now.  Let's move on to creating a highstate
for these minions!

## Installing NAPALM's Packages

Let's create our high state by adding the following to `/srv/salt/top.sls`:

```yaml
# file: /srv/salt/top.sls

base:
  'G@os_family:RedHat':
    - epel
    - napalm_install
```

Notice that we're only applying the formulas to our RedHat minion: that's
because that's the only place we're going to be running our proxy processes.
Now, let's check out our high state and see if it's what we expect:

```
$ sudo salt '*' state.show_top
smaster.learn.com:
    ----------
0.sminion.learn.com:
    ----------
1.sminion.learn.com:
    ----------
    base:
        - epel
        - napalm_install
```

Great!  Now, let's look at our individual states:

```
$ sudo salt '1*' state.show_sls epel
1.sminion.learn.com:
    ----------
    disable_epel_testing:
        ----------
        __env__:
            base
        __sls__:
            epel
        file:
            |_
              ----------
              name:
                  /etc/yum.repos.d/epel-testing.repo
            |_
              ----------
              pattern:
                  ^enabled=[0,1]
            |_
              ----------
              repl:
                  enabled=0
            - replace
            |_
              ----------
              order:
                  10005
    enable_epel:
        ----------
        __env__:
            base
        __sls__:
            epel
        file:
            |_
              ----------
              name:
                  /etc/yum.repos.d/epel.repo
            |_
              ----------
              pattern:
                  ^enabled=[0,1]
            |_
              ----------
              repl:
                  enabled=1
            - replace
            |_
              ----------
              order:
                  10004
    epel_release:
        ----------
        __env__:
            base
        __sls__:
            epel
        pkg:
            |_
              ----------
              sources:
                  |_
                    ----------
                    epel-release:
                        http://download.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-10.noarch.rpm
            |_
              ----------
              require:
                  |_
                    ----------
                    file:
                        install_pubkey_epel
            - installed
            |_
              ----------
              order:
                  10001
    install_pubkey_epel:
        ----------
        __env__:
            base
        __sls__:
            epel
        file:
            |_
              ----------
              name:
                  /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL
            |_
              ----------
              source:
                  http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7
            |_
              ----------
              source_hash:
                  md5=d41d8cd98f00b204e9800998ecf8427e
            - managed
            |_
              ----------
              order:
                  10000
    set_gpg_epel:
        ----------
        __env__:
            base
        __sls__:
            epel
        file:
            |_
              ----------
              append_if_not_found:
                  True
            |_
              ----------
              name:
                  /etc/yum.repos.d/epel.repo
            |_
              ----------
              pattern:
                  gpgcheck=.*
            |_
              ----------
              repl:
                  gpgcheck=1
            |_
              ----------
              require:
                  |_
                    ----------
                    pkg:
                        epel_release
            - replace
            |_
              ----------
              order:
                  10003
    set_pubkey_epel:
        ----------
        __env__:
            base
        __sls__:
            epel
        file:
            |_
              ----------
              append_if_not_found:
                  True
            |_
              ----------
              name:
                  /etc/yum.repos.d/epel.repo
            |_
              ----------
              pattern:
                  ^gpgkey=.*
            |_
              ----------
              repl:
                  gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL
            |_
              ----------
              require:
                  |_
                    ----------
                    pkg:
                        epel_release
            - replace
            |_
              ----------
              order:
                  10002
$ sudo salt '1*' state.show_sls napalm_install
1.sminion.learn.com:
    ----------
    install_napalm_junos_pkgs:
        ----------
        __env__:
            base
        __sls__:
            napalm_install
        pkg:
            |_
              ----------
              pkgs:
                  - python2-pip
                  - python-devel
                  - libxml2-devel
                  - libxslt-devel
                  - gcc
                  - openssl
                  - openssl-devel
                  - libffi-devel
            - installed
            |_
              ----------
              order:
                  10000
    napalm-junos:
        ----------
        __env__:
            base
        __sls__:
            napalm_install
        pip:
            - installed
            |_
              ----------
              order:
                  10001
```

That's a lot of output, but it all looks good from here!  Let's run the high state!

```
$ sudo salt '1*' state.apply
1.sminion.learn.com:
----------
          ID: install_pubkey_epel
    Function: file.managed
        Name: /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL
      Result: True
     Comment: File /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL updated
     Started: 00:15:35.336930
    Duration: 372.887 ms
     Changes:
              ----------
              diff:
                  New file
              mode:
                  0644
----------
          ID: epel_release
    Function: pkg.installed
      Result: True
     Comment: The following packages were installed/updated: epel-release
     Started: 00:15:36.508130
    Duration: 5137.288 ms
     Changes:
              ----------
              epel-release:
                  ----------
                  new:
                      7-10
                  old:
----------
          ID: set_pubkey_epel
    Function: file.replace
        Name: /etc/yum.repos.d/epel.repo
      Result: True
     Comment: Changes were made
     Started: 00:15:41.648747
    Duration: 28.85 ms
     Changes:
              ----------
              diff:
                  ---
                  +++
                  @@ -5,7 +5,7 @@
                   failovermethod=priority
                   enabled=1
                   gpgcheck=1
                  -gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
                  +gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL

                   [epel-debuginfo]
                   name=Extra Packages for Enterprise Linux 7 - $basearch - Debug
                  @@ -13,7 +13,7 @@
                   metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-debug-7&arch=$basearch
                   failovermethod=priority
                   enabled=0
                  -gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
                  +gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL
                   gpgcheck=1

                   [epel-source]
                  @@ -22,5 +22,5 @@
                   metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-source-7&arch=$basearch
                   failovermethod=priority
                   enabled=0
                  -gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
                  +gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL
                   gpgcheck=1
----------
          ID: set_gpg_epel
    Function: file.replace
        Name: /etc/yum.repos.d/epel.repo
      Result: True
     Comment: No changes needed to be made
     Started: 00:15:41.677854
    Duration: 2.585 ms
     Changes:
----------
          ID: enable_epel
    Function: file.replace
        Name: /etc/yum.repos.d/epel.repo
      Result: True
     Comment: Changes were made
     Started: 00:15:41.680593
    Duration: 2.459 ms
     Changes:
              ----------
              diff:
                  ---
                  +++
                  @@ -12,7 +12,7 @@
                   #baseurl=http://download.fedoraproject.org/pub/epel/7/$basearch/debug
                   metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-debug-7&arch=$basearch
                   failovermethod=priority
                  -enabled=0
                  +enabled=1
                   gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL
                   gpgcheck=1

                  @@ -21,6 +21,6 @@
                   #baseurl=http://download.fedoraproject.org/pub/epel/7/SRPMS
                   metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-source-7&arch=$basearch
                   failovermethod=priority
                  -enabled=0
                  +enabled=1
                   gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL
                   gpgcheck=1
----------
          ID: disable_epel_testing
    Function: file.replace
        Name: /etc/yum.repos.d/epel-testing.repo
      Result: True
     Comment: No changes needed to be made
     Started: 00:15:41.683246
    Duration: 2.448 ms
     Changes:
----------
          ID: install_napalm_junos_pkgs
    Function: pkg.installed
      Result: True
     Comment: 7 targeted packages were installed/updated.
              The following packages were already installed: openssl
     Started: 00:15:41.709676
    Duration: 101639.909 ms
     Changes:
              ----------
              cpp:
                  ----------
                  new:
                      4.8.5-16.el7
                  old:
              gcc:
                  ----------
                  new:
                      4.8.5-16.el7
                  old:
              glibc-devel:
                  ----------
                  new:
                      2.17-196.el7
                  old:
              glibc-headers:
                  ----------
                  new:
                      2.17-196.el7
                  old:
              gpg-pubkey.(none):
                  ----------
                  new:
                      352c64e5-52ae6884,de57bfbe-53a9be98,f4a80eb5-53a7ff4b
                  old:
                      de57bfbe-53a9be98,f4a80eb5-53a7ff4b
              kernel-headers:
                  ----------
                  new:
                      3.10.0-693.2.2.el7
                  old:
              keyutils-libs-devel:
                  ----------
                  new:
                      1.5.8-3.el7
                  old:
              krb5-devel:
                  ----------
                  new:
                      1.15.1-8.el7
                  old:
              libcom_err-devel:
                  ----------
                  new:
                      1.42.9-10.el7
                  old:
              libffi-devel:
                  ----------
                  new:
                      3.0.13-18.el7
                  old:
              libgcrypt-devel:
                  ----------
                  new:
                      1.5.3-14.el7
                  old:
              libgpg-error-devel:
                  ----------
                  new:
                      1.12-3.el7
                  old:
              libkadm5:
                  ----------
                  new:
                      1.15.1-8.el7
                  old:
              libmpc:
                  ----------
                  new:
                      1.0.1-3.el7
                  old:
              libselinux-devel:
                  ----------
                  new:
                      2.5-11.el7
                  old:
              libsepol-devel:
                  ----------
                  new:
                      2.5-6.el7
                  old:
              libverto-devel:
                  ----------
                  new:
                      0.2.5-4.el7
                  old:
              libxml2-devel:
                  ----------
                  new:
                      2.9.1-6.el7_2.3
                  old:
              libxslt:
                  ----------
                  new:
                      1.1.28-5.el7
                  old:
              libxslt-devel:
                  ----------
                  new:
                      1.1.28-5.el7
                  old:
              mpfr:
                  ----------
                  new:
                      3.1.1-4.el7
                  old:
              openssl-devel:
                  ----------
                  new:
                      1:1.0.2k-8.el7
                  old:
              pcre-devel:
                  ----------
                  new:
                      8.32-17.el7
                  old:
              python-devel:
                  ----------
                  new:
                      2.7.5-58.el7
                  old:
              python-setuptools:
                  ----------
                  new:
                      0.9.8-7.el7
                  old:
              python2-pip:
                  ----------
                  new:
                      8.1.2-5.el7
                  old:
              xz-devel:
                  ----------
                  new:
                      5.2.2-1.el7
                  old:
              zlib-devel:
                  ----------
                  new:
                      1.2.7-17.el7
                  old:
----------
          ID: napalm-junos
    Function: pip.installed
      Result: True
     Comment: All packages were successfully installed
     Started: 00:17:25.014289
    Duration: 26266.142 ms
     Changes:
              ----------
              napalm-junos==0.12.0:
                  Installed

Summary for 1.sminion.learn.com
------------
Succeeded: 8 (changed=6)
Failed:    0
------------
Total states run:     8
Total run time: 133.453 s
```

> We ran the high state only against the CentOS minion because that's the only
> minion with any states defined.

Okay!  Now, we need a way to get our proxy processes configured correctly and on
the target minion!

## Salt Proxy State

Okay.  We have most of the prerequisite work done.  Let's whip up a quick Salt
State to deploy the Salt Proxies.  Create the path `/srv/salt/salt_proxy`, and
then create the file `/srv/salt/salt_proxy/init.sls` with these contents:

```yaml
# file: /srv/salt/salt_proxy/init.sls

{% set salt_proxy_names = salt['pillar.get']('salt_proxy_names', []) %}

{% if salt_proxy_names|length %}
salt_proxy_disable_multiprocessing:
  file.managed:
    - name: /etc/salt/proxy
    - contents:
      - "multiprocessing: False"
{% endif %}

{% for name in salt_proxy_names %}
salt_proxy_configure_{{ name }}:
  salt_proxy.configure_proxy:
    - proxyname: {{ name }}
    - start: True
{% endfor %}
```

We'll define the `salt_proxy_names` in the next section.  For now, though, let's
associate this state with every host.  Don't worry--if they don't have the
`salt_proxy_names` pillar set, they won't get this state!  So let's edit
`/srv/salt/top.sls`:

```yaml
# file: /srv/salt/top.sls

base:
  '*':
    - salt_proxy
```

Next up: configuring the values we need!

## Salt Proxy Configuration

Okay.  Before we actually deploy the proxy process, we need to tell that process
how it's going to connect to the routers.  We do this by specifying a driver, a
hostname, a username, and a password.  So let's create two new pillar files:
`/srv/pillar/rtr1.sls` and `/srv/pillar/rtr2.sls`:

```yaml
# file: /srv/pillar/rtr1.sls

proxy:
  proxytype: napalm
  driver: junos
  host: 192.168.17.31
  username: vagrant
  passwd: Vagrant
```

```yaml
# file: /srv/pillar/rtr2.sls

proxy:
  proxytype: napalm
  driver: junos
  host: 192.168.17.32
  username: vagrant
  passwd: Vagrant
```

Now, let's associate them with the names we'll give the proxies in
`/srv/pillar/top.sls:

```yaml
# file: /srv/pillar/top.sls

base:
  'rtr1':
    - rtr1
  'rtr2':
    - rtr2
```

Great!  Now, we need to tell our CentOS minion which proxies it's going to run.
Let's create `/srv/pillar/salt_minion_1.sls`:

```yaml
# file: /srv/pillar/salt_minion_1.sls

salt_proxy_names:
  - rtr1
  - rtr2
```

And let's associate it with only the CentOS minions in `/srv/pillar/top.sls`:

```yaml
base:
  '1.sminion.learn.com':
    - salt_minion_1
```

And, of course, refresh the pillars with
`sudo salt '*' saltutil.refresh_pillar`.

## Deploying the Salt Proxies

Let's start with showing the high state and the `salt_proxy` state for all
hosts:

```
$ sudo salt '*' state.show_top
0.sminion.learn.com:
    ----------
    base:
        - salt_proxy
1.sminion.learn.com:
    ----------
    base:
        - epel
        - napalm_install
        - salt_proxy
smaster.learn.com:
    ----------
    base:
        - salt_proxy
$ sudo salt '*' state.show_sls salt_proxy
1.sminion.learn.com:
    ----------
    salt_proxy_configure_rtr1:
        ----------
        __env__:
            base
        __sls__:
            salt_proxy
        salt_proxy:
            |_
              ----------
              proxyname:
                  rtr1
            |_
              ----------
              start:
                  True
            - configure_proxy
            |_
              ----------
              order:
                  10001
    salt_proxy_configure_rtr2:
        ----------
        __env__:
            base
        __sls__:
            salt_proxy
        salt_proxy:
            |_
              ----------
              proxyname:
                  rtr2
            |_
              ----------
              start:
                  True
            - configure_proxy
            |_
              ----------
              order:
                  10002
    salt_proxy_disable_multiprocessing:
        ----------
        __env__:
            base
        __sls__:
            salt_proxy
        file:
            |_
              ----------
              name:
                  /etc/salt/proxy
            |_
              ----------
              contents:
                  - multiprocessing: False
            - managed
            |_
              ----------
              order:
                  10000
0.sminion.learn.com:
    ----------
smaster.learn.com:
    ----------
```

Excellent!  This should be exactly what we expected.  Let's move on with
applying the high state:

```
$ sudo salt '*' state.apply
0.sminion.learn.com:
----------
          ID: states
    Function: no.None
      Result: False
     Comment: No states found for this minion
     Changes:

Summary for 0.sminion.learn.com
------------
Succeeded: 0
Failed:    1
------------
Total states run:     1
Total run time:   0.000 ms
smaster.learn.com:
----------
          ID: states
    Function: no.None
      Result: False
     Comment: No states found for this minion
     Changes:

Summary for smaster.learn.com
------------
Succeeded: 0
Failed:    1
------------
Total states run:     1
Total run time:   0.000 ms
1.sminion.learn.com:
----------
          ID: install_pubkey_epel
    Function: file.managed
        Name: /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL
      Result: True
     Comment: File /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL is in the correct state
     Started: 00:35:23.285918
    Duration: 354.28 ms
     Changes:
----------
          ID: epel_release
    Function: pkg.installed
      Result: True
     Comment: All specified packages are already installed
     Started: 00:35:24.994314
    Duration: 1940.502 ms
     Changes:
----------
          ID: set_pubkey_epel
    Function: file.replace
        Name: /etc/yum.repos.d/epel.repo
      Result: True
     Comment: No changes needed to be made
     Started: 00:35:26.935354
    Duration: 4.465 ms
     Changes:
----------
          ID: set_gpg_epel
    Function: file.replace
        Name: /etc/yum.repos.d/epel.repo
      Result: True
     Comment: No changes needed to be made
     Started: 00:35:26.940227
    Duration: 2.589 ms
     Changes:
----------
          ID: enable_epel
    Function: file.replace
        Name: /etc/yum.repos.d/epel.repo
      Result: True
     Comment: No changes needed to be made
     Started: 00:35:26.943063
    Duration: 3.153 ms
     Changes:
----------
          ID: disable_epel_testing
    Function: file.replace
        Name: /etc/yum.repos.d/epel-testing.repo
      Result: True
     Comment: No changes needed to be made
     Started: 00:35:26.946389
    Duration: 3.075 ms
     Changes:
----------
          ID: install_napalm_junos_pkgs
    Function: pkg.installed
      Result: True
     Comment: All specified packages are already installed
     Started: 00:35:26.949620
    Duration: 0.862 ms
     Changes:
----------
          ID: napalm-junos
    Function: pip.installed
      Result: True
     Comment: Python package napalm-junos was already installed
              All packages were successfully installed
     Started: 00:35:27.123770
    Duration: 944.511 ms
     Changes:
----------
          ID: salt_proxy_disable_multiprocessing
    Function: file.managed
        Name: /etc/salt/proxy
      Result: True
     Comment: File /etc/salt/proxy updated
     Started: 01:21:38.054391
    Duration: 34.769 ms
     Changes:
              ----------
              diff:
                  ---
                  +++
                  @@ -1,680 +1 @@
                  -##### Primary configuration settings #####
                  -##########################################
                  -# This configuration file is used to manage the behavior of all Salt Proxy
                  -# Minions on this host.
                  -# With the exception of the location of the Salt Master Server, values that are
                  -# commented out but have an empty line after the comment are defaults that need
                  -# not be set in the config. If there is no blank line after the comment, the
                  -# value is presented as an example and is not the default.
                  -
                  -# Per default the minion will automatically include all config files
                  -# from minion.d/*.conf (minion.d is a directory in the same directory
                  -# as the main minion config file).
                  -#default_include: minion.d/*.conf
                  -
                  -# Backwards compatibility option for proxymodules created before 2015.8.2
                  -# This setting will default to 'False' in the 2016.3.0 release
                  -# Setting this to True adds proxymodules to the __opts__ dictionary.
                  -# This breaks several Salt features (basically anything that serializes
                  -# __opts__ over the wire) but retains backwards compatibility.
                  -#add_proxymodule_to_opts: True
                  -
                  -# Set the location of the salt master server. If the master server cannot be
                  -# resolved, then the minion will fail to start.
                  -#master: salt
                  -
                  -# If a proxymodule has a function called 'grains', then call it during
                  -# regular grains loading and merge the results with the proxy's grains
                  -# dictionary.  Otherwise it is assumed that the module calls the grains
                  -# function in a custom way and returns the data elsewhere
                  -#
                  -# Default to False for 2016.3 and 2016.11. Switch to True for 2017.7.0.
                  -# proxy_merge_grains_in_module: True
                  -
                  -# If a proxymodule has a function called 'alive' returning a boolean
                  -# flag reflecting the state of the connection with the remove device,
                  -# when this option is set as True, a scheduled job on the proxy will
                  -# try restarting the connection. The polling frequency depends on the
                  -# next option, 'proxy_keep_alive_interval'. Added in 2017.7.0.
                  -# proxy_keep_alive: True
                  -
                  -# The polling interval (in minutes) to check if the underlying connection
                  -# with the remote device is still alive. This option requires
                  -# 'proxy_keep_alive' to be configured as True and the proxymodule to
                  -# implement the 'alive' function. Added in 2017.7.0.
                  -# proxy_keep_alive_interval: 1
                  -
                  -# By default, any proxy opens the connection with the remote device when
                  -# initialized. Some proxymodules allow through this option to open/close
                  -# the session per command. This requires the proxymodule to have this
                  -# capability. Please consult the documentation to see if the proxy type
                  -# used can be that flexible. Added in 2017.7.0.
                  -# proxy_always_alive: True
                  -
                  -# If multiple masters are specified in the 'master' setting, the default behavior
                  -# is to always try to connect to them in the order they are listed. If random_master is
                  -# set to True, the order will be randomized instead. This can be helpful in distributing
                  -# the load of many minions executing salt-call requests, for example, from a cron job.
                  -# If only one master is listed, this setting is ignored and a warning will be logged.
                  -#random_master: False
                  -
                  -# Minions can connect to multiple masters simultaneously (all masters
                  -# are "hot"), or can be configured to failover if a master becomes
                  -# unavailable.  Multiple hot masters are configured by setting this
                  -# value to "str".  Failover masters can be requested by setting
                  -# to "failover".  MAKE SURE TO SET master_alive_interval if you are
                  -# using failover.
                  -# master_type: str
                  -
                  -# Poll interval in seconds for checking if the master is still there.  Only
                  -# respected if master_type above is "failover".
                  -# master_alive_interval: 30
                  -
                  -# Set whether the minion should connect to the master via IPv6:
                  -#ipv6: False
                  -
                  -# Set the number of seconds to wait before attempting to resolve
                  -# the master hostname if name resolution fails. Defaults to 30 seconds.
                  -# Set to zero if the minion should shutdown and not retry.
                  -# retry_dns: 30
                  -
                  -# Set the port used by the master reply and authentication server.
                  -#master_port: 4506
                  -
                  -# The user to run salt.
                  -#user: root
                  -
                  -# Setting sudo_user will cause salt to run all execution modules under an sudo
                  -# to the user given in sudo_user.  The user under which the salt minion process
                  -# itself runs will still be that provided in the user config above, but all
                  -# execution modules run by the minion will be rerouted through sudo.
                  -#sudo_user: saltdev
                  -
                  -# Specify the location of the daemon process ID file.
                  -#pidfile: /var/run/salt-minion.pid
                  -
                  -# The root directory prepended to these options: pki_dir, cachedir, log_file,
                  -# sock_dir, pidfile.
                  -#root_dir: /
                  -
                  -# The directory to store the pki information in
                  -#pki_dir: /etc/salt/pki/minion
                  -
                  -# Where cache data goes.
                  -# This data may contain sensitive data and should be protected accordingly.
                  -#cachedir: /var/cache/salt/minion
                  -
                  -# Append minion_id to these directories.  Helps with
                  -# multiple proxies and minions running on the same machine.
                  -# Allowed elements in the list: pki_dir, cachedir, extension_modules
                  -# Normally not needed unless running several proxies and/or minions on the same machine
                  -# Defaults to ['cachedir'] for proxies, [] (empty list) for regular minions
                  -# append_minionid_config_dirs:
                  -#   - cachedir
                  -
                  -
                  -
                  -# Verify and set permissions on configuration directories at startup.
                  -#verify_env: True
                  -
                  -# The minion can locally cache the return data from jobs sent to it, this
                  -# can be a good way to keep track of jobs the minion has executed
                  -# (on the minion side). By default this feature is disabled, to enable, set
                  -# cache_jobs to True.
                  -#cache_jobs: False
                  -
                  -# Set the directory used to hold unix sockets.
                  -#sock_dir: /var/run/salt/minion
                  -
                  -# Set the default outputter used by the salt-call command. The default is
                  -# "nested".
                  -#output: nested
                  -#
                  -# By default output is colored. To disable colored output, set the color value
                  -# to False.
                  -#color: True
                  -
                  -# Do not strip off the colored output from nested results and state outputs
                  -# (true by default).
                  -# strip_colors: False
                  -
                  -# Backup files that are replaced by file.managed and file.recurse under
                  -# 'cachedir'/file_backup relative to their original location and appended
                  -# with a timestamp. The only valid setting is "minion". Disabled by default.
                  -#
                  -# Alternatively this can be specified for each file in state files:
                  -# /etc/ssh/sshd_config:
                  -#   file.managed:
                  -#     - source: salt://ssh/sshd_config
                  -#     - backup: minion
                  -#
                  -#backup_mode: minion
                  -
                  -# When waiting for a master to accept the minion's public key, salt will
                  -# continuously attempt to reconnect until successful. This is the time, in
                  -# seconds, between those reconnection attempts.
                  -#acceptance_wait_time: 10
                  -
                  -# If this is nonzero, the time between reconnection attempts will increase by
                  -# acceptance_wait_time seconds per iteration, up to this maximum. If this is
                  -# set to zero, the time between reconnection attempts will stay constant.
                  -#acceptance_wait_time_max: 0
                  -
                  -# If the master rejects the minion's public key, retry instead of exiting.
                  -# Rejected keys will be handled the same as waiting on acceptance.
                  -#rejected_retry: False
                  -
                  -# When the master key changes, the minion will try to re-auth itself to receive
                  -# the new master key. In larger environments this can cause a SYN flood on the
                  -# master because all minions try to re-auth immediately. To prevent this and
                  -# have a minion wait for a random amount of time, use this optional parameter.
                  -# The wait-time will be a random number of seconds between 0 and the defined value.
                  -#random_reauth_delay: 60
                  -
                  -# When waiting for a master to accept the minion's public key, salt will
                  -# continuously attempt to reconnect until successful. This is the timeout value,
                  -# in seconds, for each individual attempt. After this timeout expires, the minion
                  -# will wait for acceptance_wait_time seconds before trying again. Unless your master
                  -# is under unusually heavy load, this should be left at the default.
                  -#auth_timeout: 60
                  -
                  -# Number of consecutive SaltReqTimeoutError that are acceptable when trying to
                  -# authenticate.
                  -#auth_tries: 7
                  -
                  -# If authentication fails due to SaltReqTimeoutError during a ping_interval,
                  -# cause sub minion process to restart.
                  -#auth_safemode: False
                  -
                  -# Ping Master to ensure connection is alive (minutes).
                  -#ping_interval: 0
                  -
                  -# To auto recover minions if master changes IP address (DDNS)
                  -#    auth_tries: 10
                  -#    auth_safemode: False
                  -#    ping_interval: 90
                  -#
                  -# Minions won't know master is missing until a ping fails. After the ping fail,
                  -# the minion will attempt authentication and likely fails out and cause a restart.
                  -# When the minion restarts it will resolve the masters IP and attempt to reconnect.
                  -
                  -# If you don't have any problems with syn-floods, don't bother with the
                  -# three recon_* settings described below, just leave the defaults!
                  -#
                  -# The ZeroMQ pull-socket that binds to the masters publishing interface tries
                  -# to reconnect immediately, if the socket is disconnected (for example if
                  -# the master processes are restarted). In large setups this will have all
                  -# minions reconnect immediately which might flood the master (the ZeroMQ-default
                  -# is usually a 100ms delay). To prevent this, these three recon_* settings
                  -# can be used.
                  -# recon_default: the interval in milliseconds that the socket should wait before
                  -#                trying to reconnect to the master (1000ms = 1 second)
                  -#
                  -# recon_max: the maximum time a socket should wait. each interval the time to wait
                  -#            is calculated by doubling the previous time. if recon_max is reached,
                  -#            it starts again at recon_default. Short example:
                  -#
                  -#            reconnect 1: the socket will wait 'recon_default' milliseconds
                  -#            reconnect 2: 'recon_default' * 2
                  -#            reconnect 3: ('recon_default' * 2) * 2
                  -#            reconnect 4: value from previous interval * 2
                  -#            reconnect 5: value from previous interval * 2
                  -#            reconnect x: if value >= recon_max, it starts again with recon_default
                  -#
                  -# recon_randomize: generate a random wait time on minion start. The wait time will
                  -#                  be a random value between recon_default and recon_default +
                  -#                  recon_max. Having all minions reconnect with the same recon_default
                  -#                  and recon_max value kind of defeats the purpose of being able to
                  -#                  change these settings. If all minions have the same values and your
                  -#                  setup is quite large (several thousand minions), they will still
                  -#                  flood the master. The desired behavior is to have timeframe within
                  -#                  all minions try to reconnect.
                  -#
                  -# Example on how to use these settings. The goal: have all minions reconnect within a
                  -# 60 second timeframe on a disconnect.
                  -# recon_default: 1000
                  -# recon_max: 59000
                  -# recon_randomize: True
                  -#
                  -# Each minion will have a randomized reconnect value between 'recon_default'
                  -# and 'recon_default + recon_max', which in this example means between 1000ms
                  -# 60000ms (or between 1 and 60 seconds). The generated random-value will be
                  -# doubled after each attempt to reconnect. Lets say the generated random
                  -# value is 11 seconds (or 11000ms).
                  -# reconnect 1: wait 11 seconds
                  -# reconnect 2: wait 22 seconds
                  -# reconnect 3: wait 33 seconds
                  -# reconnect 4: wait 44 seconds
                  -# reconnect 5: wait 55 seconds
                  -# reconnect 6: wait time is bigger than 60 seconds (recon_default + recon_max)
                  -# reconnect 7: wait 11 seconds
                  -# reconnect 8: wait 22 seconds
                  -# reconnect 9: wait 33 seconds
                  -# reconnect x: etc.
                  -#
                  -# In a setup with ~6000 thousand hosts these settings would average the reconnects
                  -# to about 100 per second and all hosts would be reconnected within 60 seconds.
                  -# recon_default: 100
                  -# recon_max: 5000
                  -# recon_randomize: False
                  -#
                  -#
                  -# The loop_interval sets how long in seconds the minion will wait between
                  -# evaluating the scheduler and running cleanup tasks. This defaults to a
                  -# sane 60 seconds, but if the minion scheduler needs to be evaluated more
                  -# often lower this value
                  -#loop_interval: 60
                  -
                  -# The grains_refresh_every setting allows for a minion to periodically check
                  -# its grains to see if they have changed and, if so, to inform the master
                  -# of the new grains. This operation is moderately expensive, therefore
                  -# care should be taken not to set this value too low.
                  -#
                  -# Note: This value is expressed in __minutes__!
                  -#
                  -# A value of 10 minutes is a reasonable default.
                  -#
                  -# If the value is set to zero, this check is disabled.
                  -#grains_refresh_every: 1
                  -
                  -# Cache grains on the minion. Default is False.
                  -#grains_cache: False
                  -
                  -# Grains cache expiration, in seconds. If the cache file is older than this
                  -# number of seconds then the grains cache will be dumped and fully re-populated
                  -# with fresh data. Defaults to 5 minutes. Will have no effect if 'grains_cache'
                  -# is not enabled.
                  -# grains_cache_expiration: 300
                  -
                  -# Windows platforms lack posix IPC and must rely on slower TCP based inter-
                  -# process communications. Set ipc_mode to 'tcp' on such systems
                  -#ipc_mode: ipc
                  -
                  -# Overwrite the default tcp ports used by the minion when in tcp mode
                  -#tcp_pub_port: 4510
                  -#tcp_pull_port: 4511
                  -
                  -# Passing very large events can cause the minion to consume large amounts of
                  -# memory. This value tunes the maximum size of a message allowed onto the
                  -# minion event bus. The value is expressed in bytes.
                  -#max_event_size: 1048576
                  -
                  -# To detect failed master(s) and fire events on connect/disconnect, set
                  -# master_alive_interval to the number of seconds to poll the masters for
                  -# connection events.
                  -#
                  -#master_alive_interval: 30
                  -
                  -# The minion can include configuration from other files. To enable this,
                  -# pass a list of paths to this option. The paths can be either relative or
                  -# absolute; if relative, they are considered to be relative to the directory
                  -# the main minion configuration file lives in (this file). Paths can make use
                  -# of shell-style globbing. If no files are matched by a path passed to this
                  -# option then the minion will log a warning message.
                  -#
                  -# Include a config file from some other path:
                  -# include: /etc/salt/extra_config
                  -#
                  -# Include config from several files and directories:
                  -#include:
                  -#  - /etc/salt/extra_config
                  -#  - /etc/roles/webserver
                  -#
                  -#
                  -#
                  -#####   Minion module management     #####
                  -##########################################
                  -# Disable specific modules. This allows the admin to limit the level of
                  -# access the master has to the minion.
                  -#disable_modules: [cmd,test]
                  -#disable_returners: []
                  -#
                  -# Modules can be loaded from arbitrary paths. This enables the easy deployment
                  -# of third party modules. Modules for returners and minions can be loaded.
                  -# Specify a list of extra directories to search for minion modules and
                  -# returners. These paths must be fully qualified!
                  -#module_dirs: []
                  -#returner_dirs: []
                  -#states_dirs: []
                  -#render_dirs: []
                  -#utils_dirs: []
                  -#
                  -# A module provider can be statically overwritten or extended for the minion
                  -# via the providers option, in this case the default module will be
                  -# overwritten by the specified module. In this example the pkg module will
                  -# be provided by the yumpkg5 module instead of the system default.
                  -#providers:
                  -#  pkg: yumpkg5
                  -#
                  -# Enable Cython modules searching and loading. (Default: False)
                  -#cython_enable: False
                  -#
                  -# Specify a max size (in bytes) for modules on import. This feature is currently
                  -# only supported on *nix operating systems and requires psutil.
                  -# modules_max_memory: -1
                  -
                  -
                  -#####    State Management Settings    #####
                  -###########################################
                  -# The state management system executes all of the state templates on the minion
                  -# to enable more granular control of system state management. The type of
                  -# template and serialization used for state management needs to be configured
                  -# on the minion, the default renderer is yaml_jinja. This is a yaml file
                  -# rendered from a jinja template, the available options are:
                  -# yaml_jinja
                  -# yaml_mako
                  -# yaml_wempy
                  -# json_jinja
                  -# json_mako
                  -# json_wempy
                  -#
                  -#renderer: yaml_jinja
                  -#
                  -# The failhard option tells the minions to stop immediately after the first
                  -# failure detected in the state execution. Defaults to False.
                  -#failhard: False
                  -#
                  -# Reload the modules prior to a highstate run.
                  -#autoload_dynamic_modules: True
                  -#
                  -# clean_dynamic_modules keeps the dynamic modules on the minion in sync with
                  -# the dynamic modules on the master, this means that if a dynamic module is
                  -# not on the master it will be deleted from the minion. By default, this is
                  -# enabled and can be disabled by changing this value to False.
                  -#clean_dynamic_modules: True
                  -#
                  -# Normally, the minion is not isolated to any single environment on the master
                  -# when running states, but the environment can be isolated on the minion side
                  -# by statically setting it. Remember that the recommended way to manage
                  -# environments is to isolate via the top file.
                  -#environment: None
                  -#
                  -# If using the local file directory, then the state top file name needs to be
                  -# defined, by default this is top.sls.
                  -#state_top: top.sls
                  -#
                  -# Run states when the minion daemon starts. To enable, set startup_states to:
                  -# 'highstate' -- Execute state.highstate
                  -# 'sls' -- Read in the sls_list option and execute the named sls files
                  -# 'top' -- Read top_file option and execute based on that file on the Master
                  -#startup_states: ''
                  -#
                  -# List of states to run when the minion starts up if startup_states is 'sls':
                  -#sls_list:
                  -#  - edit.vim
                  -#  - hyper
                  -#
                  -# Top file to execute if startup_states is 'top':
                  -#top_file: ''
                  -
                  -# Automatically aggregate all states that have support for mod_aggregate by
                  -# setting to True. Or pass a list of state module names to automatically
                  -# aggregate just those types.
                  -#
                  -# state_aggregate:
                  -#   - pkg
                  -#
                  -#state_aggregate: False
                  -
                  -#####     File Directory Settings    #####
                  -##########################################
                  -# The Salt Minion can redirect all file server operations to a local directory,
                  -# this allows for the same state tree that is on the master to be used if
                  -# copied completely onto the minion. This is a literal copy of the settings on
                  -# the master but used to reference a local directory on the minion.
                  -
                  -# Set the file client. The client defaults to looking on the master server for
                  -# files, but can be directed to look at the local file directory setting
                  -# defined below by setting it to "local". Setting a local file_client runs the
                  -# minion in masterless mode.
                  -#file_client: remote
                  -
                  -# The file directory works on environments passed to the minion, each environment
                  -# can have multiple root directories, the subdirectories in the multiple file
                  -# roots cannot match, otherwise the downloaded files will not be able to be
                  -# reliably ensured. A base environment is required to house the top file.
                  -# Example:
                  -# file_roots:
                  -#   base:
                  -#     - /srv/salt/
                  -#   dev:
                  -#     - /srv/salt/dev/services
                  -#     - /srv/salt/dev/states
                  -#   prod:
                  -#     - /srv/salt/prod/services
                  -#     - /srv/salt/prod/states
                  -#
                  -#file_roots:
                  -#  base:
                  -#    - /srv/salt
                  -
                  -# By default, the Salt fileserver recurses fully into all defined environments
                  -# to attempt to find files. To limit this behavior so that the fileserver only
                  -# traverses directories with SLS files and special Salt directories like _modules,
                  -# enable the option below. This might be useful for installations where a file root
                  -# has a very large number of files and performance is negatively impacted. Default
                  -# is False.
                  -#fileserver_limit_traversal: False
                  -
                  -# The hash_type is the hash to use when discovering the hash of a file in
                  -# the local fileserver. The default is sha256 but sha224, sha384 and sha512
                  -# are also supported.
                  -#
                  -# WARNING: While md5 and sha1 are also supported, do not use it due to the high chance
                  -# of possible collisions and thus security breach.
                  -#
                  -# WARNING: While md5 is also supported, do not use it due to the high chance
                  -# of possible collisions and thus security breach.
                  -#
                  -# Warning: Prior to changing this value, the minion should be stopped and all
                  -# Salt caches should be cleared.
                  -#hash_type: sha256
                  -
                  -# The Salt pillar is searched for locally if file_client is set to local. If
                  -# this is the case, and pillar data is defined, then the pillar_roots need to
                  -# also be configured on the minion:
                  -#pillar_roots:
                  -#  base:
                  -#    - /srv/pillar
                  -#
                  -#
                  -######        Security settings       #####
                  -###########################################
                  -# Enable "open mode", this mode still maintains encryption, but turns off
                  -# authentication, this is only intended for highly secure environments or for
                  -# the situation where your keys end up in a bad state. If you run in open mode
                  -# you do so at your own risk!
                  -#open_mode: False
                  -
                  -# Enable permissive access to the salt keys.  This allows you to run the
                  -# master or minion as root, but have a non-root group be given access to
                  -# your pki_dir.  To make the access explicit, root must belong to the group
                  -# you've given access to. This is potentially quite insecure.
                  -#permissive_pki_access: False
                  -
                  -# The state_verbose and state_output settings can be used to change the way
                  -# state system data is printed to the display. By default all data is printed.
                  -# The state_verbose setting can be set to True or False, when set to False
                  -# all data that has a result of True and no changes will be suppressed.
                  -#state_verbose: True
                  -
                  -# The state_output setting changes if the output is the full multi line
                  -# output for each changed state if set to 'full', but if set to 'terse'
                  -# the output will be shortened to a single line.
                  -#state_output: full
                  -
                  -# The state_output_diff setting changes whether or not the output from
                  -# successful states is returned. Useful when even the terse output of these
                  -# states is cluttering the logs. Set it to True to ignore them.
                  -#state_output_diff: False
                  -
                  -# The state_output_profile setting changes whether profile information
                  -# will be shown for each state run.
                  -#state_output_profile: True
                  -
                  -# Fingerprint of the master public key to validate the identity of your Salt master
                  -# before the initial key exchange. The master fingerprint can be found by running
                  -# "salt-key -F master" on the Salt master.
                  -#master_finger: ''
                  -
                  -
                  -######         Thread settings        #####
                  -###########################################
                  -# Disable multiprocessing support, by default when a minion receives a
                  -# publication a new process is spawned and the command is executed therein.
                  -#multiprocessing: True
                  -
                  -
                  -#####         Logging settings       #####
                  -##########################################
                  -# The location of the minion log file
                  -# The minion log can be sent to a regular file, local path name, or network
                  -# location. Remote logging works best when configured to use rsyslogd(8) (e.g.:
                  -# ``file:///dev/log``), with rsyslogd(8) configured for network logging. The URI
                  -# format is: <file|udp|tcp>://<host|socketpath>:<port-if-required>/<log-facility>
                  -#log_file: /var/log/salt/minion
                  -#log_file: file:///dev/log
                  -#log_file: udp://loghost:10514
                  -#
                  -#log_file: /var/log/salt/minion
                  -#key_logfile: /var/log/salt/key
                  -
                  -# The level of messages to send to the console.
                  -# One of 'garbage', 'trace', 'debug', info', 'warning', 'error', 'critical'.
                  -#
                  -# The following log levels are considered INSECURE and may log sensitive data:
                  -# ['garbage', 'trace', 'debug']
                  -#
                  -# Default: 'warning'
                  -#log_level: warning
                  -
                  -# The level of messages to send to the log file.
                  -# One of 'garbage', 'trace', 'debug', info', 'warning', 'error', 'critical'.
                  -# If using 'log_granular_levels' this must be set to the highest desired level.
                  -# Default: 'warning'
                  -#log_level_logfile:
                  -
                  -# The date and time format used in log messages. Allowed date/time formatting
                  -# can be seen here: http://docs.python.org/library/time.html#time.strftime
                  -#log_datefmt: '%H:%M:%S'
                  -#log_datefmt_logfile: '%Y-%m-%d %H:%M:%S'
                  -
                  -# The format of the console logging messages. Allowed formatting options can
                  -# be seen here: http://docs.python.org/library/logging.html#logrecord-attributes
                  -#
                  -# Console log colors are specified by these additional formatters:
                  -#
                  -# %(colorlevel)s
                  -# %(colorname)s
                  -# %(colorprocess)s
                  -# %(colormsg)s
                  -#
                  -# Since it is desirable to include the surrounding brackets, '[' and ']', in
                  -# the coloring of the messages, these color formatters also include padding as
                  -# well.  Color LogRecord attributes are only available for console logging.
                  -#
                  -#log_fmt_console: '%(colorlevel)s %(colormsg)s'
                  -#log_fmt_console: '[%(levelname)-8s] %(message)s'
                  -#
                  -#log_fmt_logfile: '%(asctime)s,%(msecs)03d [%(name)-17s][%(levelname)-8s] %(message)s'
                  -
                  -# This can be used to control logging levels more specificically.  This
                  -# example sets the main salt library at the 'warning' level, but sets
                  -# 'salt.modules' to log at the 'debug' level:
                  -#   log_granular_levels:
                  -#     'salt': 'warning'
                  -#     'salt.modules': 'debug'
                  -#
                  -#log_granular_levels: {}
                  -
                  -# To diagnose issues with minions disconnecting or missing returns, ZeroMQ
                  -# supports the use of monitor sockets # to log connection events. This
                  -# feature requires ZeroMQ 4.0 or higher.
                  -#
                  -# To enable ZeroMQ monitor sockets, set 'zmq_monitor' to 'True' and log at a
                  -# debug level or higher.
                  -#
                  -# A sample log event is as follows:
                  -#
                  -# [DEBUG   ] ZeroMQ event: {'endpoint': 'tcp://127.0.0.1:4505', 'event': 512,
                  -# 'value': 27, 'description': 'EVENT_DISCONNECTED'}
                  -#
                  -# All events logged will include the string 'ZeroMQ event'. A connection event
                  -# should be logged on the as the minion starts up and initially connects to the
                  -# master. If not, check for debug log level and that the necessary version of
                  -# ZeroMQ is installed.
                  -#
                  -#zmq_monitor: False
                  -
                  -######      Module configuration      #####
                  -###########################################
                  -# Salt allows for modules to be passed arbitrary configuration data, any data
                  -# passed here in valid yaml format will be passed on to the salt minion modules
                  -# for use. It is STRONGLY recommended that a naming convention be used in which
                  -# the module name is followed by a . and then the value. Also, all top level
                  -# data must be applied via the yaml dict construct, some examples:
                  -#
                  -# You can specify that all modules should run in test mode:
                  -#test: True
                  -#
                  -# A simple value for the test module:
                  -#test.foo: foo
                  -#
                  -# A list for the test module:
                  -#test.bar: [baz,quo]
                  -#
                  -# A dict for the test module:
                  -#test.baz: {spam: sausage, cheese: bread}
                  -#
                  -#
                  -######      Update settings          ######
                  -###########################################
                  -# Using the features in Esky, a salt minion can both run as a frozen app and
                  -# be updated on the fly. These options control how the update process
                  -# (saltutil.update()) behaves.
                  -#
                  -# The url for finding and downloading updates. Disabled by default.
                  -#update_url: False
                  -#
                  -# The list of services to restart after a successful update. Empty by default.
                  -#update_restart_services: []
                  -
                  -
                  -######      Keepalive settings        ######
                  -############################################
                  -# ZeroMQ now includes support for configuring SO_KEEPALIVE if supported by
                  -# the OS. If connections between the minion and the master pass through
                  -# a state tracking device such as a firewall or VPN gateway, there is
                  -# the risk that it could tear down the connection the master and minion
                  -# without informing either party that their connection has been taken away.
                  -# Enabling TCP Keepalives prevents this from happening.
                  -
                  -# Overall state of TCP Keepalives, enable (1 or True), disable (0 or False)
                  -# or leave to the OS defaults (-1), on Linux, typically disabled. Default True, enabled.
                  -#tcp_keepalive: True
                  -
                  -# How long before the first keepalive should be sent in seconds. Default 300
                  -# to send the first keepalive after 5 minutes, OS default (-1) is typically 7200 seconds
                  -# on Linux see /proc/sys/net/ipv4/tcp_keepalive_time.
                  -#tcp_keepalive_idle: 300
                  -
                  -# How many lost probes are needed to consider the connection lost. Default -1
                  -# to use OS defaults, typically 9 on Linux, see /proc/sys/net/ipv4/tcp_keepalive_probes.
                  -#tcp_keepalive_cnt: -1
                  -
                  -# How often, in seconds, to send keepalives after the first one. Default -1 to
                  -# use OS defaults, typically 75 seconds on Linux, see
                  -# /proc/sys/net/ipv4/tcp_keepalive_intvl.
                  -#tcp_keepalive_intvl: -1
                  -
                  -
                  -######   Windows Software settings    ######
                  -############################################
                  -# Location of the repository cache file on the master:
                  -#win_repo_cachefile: 'salt://win/repo/winrepo.p'
                  -
                  -
                  -######      Returner  settings        ######
                  -############################################
                  -# Which returner(s) will be used for minion's result:
                  -#return: mysql
                  +multiprocessing: False
----------
          ID: salt_proxy_configure_rtr1
    Function: salt_proxy.configure_proxy
      Result: True
     Comment: salt_proxy_configure_rtr1 config messages
     Started: 00:35:28.072299
    Duration: 741.88 ms
     Changes:
              ----------
              new:
                  Salt Proxy: Started proxy process for rtr1
              old:
                  Salt Proxy: /etc/salt/proxy already exists, skipping
----------
          ID: salt_proxy_configure_rtr2
    Function: salt_proxy.configure_proxy
      Result: True
     Comment: salt_proxy_configure_rtr2 config messages
     Started: 00:35:28.814455
    Duration: 758.871 ms
     Changes:
              ----------
              new:
                  Salt Proxy: Started proxy process for rtr2
              old:
                  Salt Proxy: /etc/salt/proxy already exists, skipping

Summary for 1.sminion.learn.com
-------------
Succeeded: 11 (changed=3)
Failed:     0
-------------
Total states run:     10
Total run time:    4.754 s
ERROR: Minions returned with non-zero exit code
```

> The `ERROR` is actually expected: it shows that there was no state to apply
> to the Ubuntu minions, which is exactly what we should have expected.

Okay.  Great!  Now, let's start poking around!

## Accepting the Keys

First, these are going to look like normal minions in many respects.  Let's make
sure we see their keys and accept them:

```
$ sudo salt-key
Accepted Keys:
0.sminion.learn.com
1.sminion.learn.com
smaster.learn.com
Denied Keys:
Unaccepted Keys:
rtr1
rtr2
Rejected Keys:
$ sudo salt-key -A
The following keys are going to be accepted:
Unaccepted Keys:
rtr1
rtr2
Proceed? [n/Y] y
Key for minion rtr1 accepted.
Key for minion rtr2 accepted.
```

## Running `test.ping`

Now, we should also be able to run `test.ping` against them.  Let's try that
next:

```
$ sudo salt '*' test.ping
0.sminion.learn.com:
    True
smaster.learn.com:
    True
1.sminion.learn.com:
    True
rtr2:
    True
rtr1:
    True
```

## Looking at Grains

These proxy minions also have grains.  Let's take a look at one of the grain
items:

```
$ sudo salt 'rtr*' grains.item os
rtr2:
    ----------
    os:
        junos
rtr1:
    ----------
    os:
        junos
```

## Running Commands

These proxy minions can also have execution functions run against them.  We'll
look at this in more detail in the next module, but let's get a brief glimpse of
this now:

```
$ sudo salt 'rtr*' net.cli 'sh ver'
rtr1:
    ----------
    comment:
    out:
        ----------
        sh ver:

            fpc0:
            --------------------------------------------------------------------------
            Hostname: rtr1
            Model: vqfx-10000
            Junos: 15.1X53-D63.9
            JUNOS Base OS boot [15.1X53-D63.9]
            JUNOS Base OS Software Suite [15.1X53-D63.9]
            JUNOS Online Documentation [15.1X53-D63.9]
            JUNOS Crypto Software Suite [15.1X53-D63.9]
            JUNOS Packet Forwarding Engine Support (qfx-10-f) [15.1X53-D63.9]
            JUNOS Kernel Software Suite [15.1X53-D63.9]
            JUNOS Web Management [15.1X53-D63.9]
            JUNOS Enterprise Software Suite [15.1X53-D63.9]
            JUNOS SDN Software Suite [15.1X53-D63.9]
            JUNOS Routing Software Suite [15.1X53-D63.9]
            JUNOS py-base-i386 [15.1X53-D63.9]
    result:
        True
rtr2:
    ----------
    comment:
    out:
        ----------
        sh ver:

            fpc0:
            --------------------------------------------------------------------------
            Hostname: rtr2
            Model: vqfx-10000
            Junos: 15.1X53-D63.9
            JUNOS Base OS boot [15.1X53-D63.9]
            JUNOS Base OS Software Suite [15.1X53-D63.9]
            JUNOS Online Documentation [15.1X53-D63.9]
            JUNOS Crypto Software Suite [15.1X53-D63.9]
            JUNOS Packet Forwarding Engine Support (qfx-10-f) [15.1X53-D63.9]
            JUNOS Kernel Software Suite [15.1X53-D63.9]
            JUNOS Web Management [15.1X53-D63.9]
            JUNOS Enterprise Software Suite [15.1X53-D63.9]
            JUNOS SDN Software Suite [15.1X53-D63.9]
            JUNOS Routing Software Suite [15.1X53-D63.9]
            JUNOS py-base-i386 [15.1X53-D63.9]
    result:
        True
```

# Conclusion

This was a pretty complex module.  It involved a lot of moving parts: using Salt
formulas; creating a custom Salt state; modifying pillar data; starting up the
routers; and actually deploying everything and verifying that a Salt Proxy
mostly behaves like a normal Salt Minion from an end user's perspective.  In the
next module, we'll look at remote execution modules that can be used with our
routers.

| Home           | Previous                  | Next                                        |
|----------------|---------------------------|---------------------------------------------|
| [Home](../../) | [Schedules](../schedules) | [Network Device Execution](../net_dev_exec) |
