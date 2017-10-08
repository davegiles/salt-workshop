|Home          |Previous                | Next              |
|--------------|------------------------|-------------------|
|[Home](../../)|[Targeting](../target) |[YAML](../yaml)    |

# Grains

Grains are pieces of information about the systems in your cluster that Salt
discovers when it starts the Salt Minion on the node.  The grain attribute
contains information about the OS, kernel, and other system attributes.

In addition to the built in Grains, you can also add custom grains to a node.
These can be used for classification.  For example, some teams add a `roles`
grain to the system and then assign roles such as `webserver`, `dbserver`,
and so on.

A grain can be a value or a list of values based on the nature of the grain
attribute. Let's get to some hands-on examples!

## Built In Grains

Built-in grains are pieces of information that Salt itself discovers.  These are
typically related to the kernel, system, and other information based on the OS.

To list grains that are present on a node, we can use the `ls` function on the
`grains` module:

```
$ sudo salt '*1*' grains.ls
1.sminion.learn.com:
    - SSDs
    - biosreleasedate
    - biosversion
    - cpu_flags
    - cpu_model
    - cpuarch
    - disks
    - dns
    - domain
    - fqdn
    - fqdn_ip4
    - fqdn_ip6
    - gid
    - gpus
    - groupname
    - host
    - hwaddr_interfaces
    - id
    - init
    - ip4_interfaces
    - ip6_interfaces
    - ip_interfaces
    - ipv4
    - ipv6
    - kernel
    - kernelrelease
    - locale_info
    - localhost
    - lsb_distrib_codename
    - lsb_distrib_description
    - lsb_distrib_id
    - lsb_distrib_release
    - machine_id
    - manufacturer
    - master
    - mdadm
    - mem_total
    - nodename
    - num_cpus
    - num_gpus
    - os
    - os_family
    - osarch
    - oscodename
    - osfinger
    - osfullname
    - osmajorrelease
    - osrelease
    - osrelease_info
    - path
    - pid
    - productname
    - ps
    - pythonexecutable
    - pythonpath
    - pythonversion
    - saltpath
    - saltversion
    - saltversioninfo
    - server_id
    - shell
    - uid
    - username
    - uuid
    - virtual
    - zmqversion
 ```

If we want to see the values of the grains as well, we can use the `items`
function on the `grains` module.  The output is fairly long, so I have truncated
it here:

```
$ sudo salt '*1*' grains.items
1.sminion.learn.com:
    ----------
    SSDs:
    biosreleasedate:
        12/01/2006
    biosversion:
        VirtualBox
    cpu_flags:
        - fpu
        - vme
        - de
        - pse
        - tsc
        - msr
        - pae
        - mce
        - cx8
        - apic
        - sep
        - mtrr
        - pge
        - mca
        - cmov
        - pat
        - pse36
        - clflush
        - mmx
        - fxsr
        - sse
        - sse2
        - syscall
        - nx
        - rdtscp
        - lm
        - constant_tsc
        - rep_good
        - nopl
        - xtopology
        - nonstop_tsc
        - pni
        - pclmulqdq
        - monitor
        - ssse3
        - cx16
        - sse4_1
        - sse4_2
        - movbe
        - popcnt
        - aes
        - xsave
        - avx
        - rdrand
        - lahf_lm
        - abm
        - 3dnowprefetch
        - rdseed
    cpu_model:
        Intel(R) Core(TM) i7-7700HQ CPU @ 2.80GHz
    cpuarch:
        x86_64
    disks:
        - sda
        - ram0
        - ram1
        - ram2
        - ram3
        - ram4
        - ram5
        - ram6
        - ram7
        - ram8
        - ram9
        - loop0
        - loop1
        - loop2
        - loop3
        - loop4
        - loop5
        - loop6
        - loop7
        - ram10
        - ram11
        - ram12
        - ram13
        - ram14
        - ram15
    dns:
        ----------
        domain:
        ip4_nameservers:
            - 10.0.2.3
        ip6_nameservers:
        nameservers:
            - 10.0.2.3
        options:
        search:
            - infracloud.com
        sortlist:
    domain:
        sminion.learn.com
    fqdn:
        1.sminion.learn.com
    fqdn_ip4:
        - 127.0.0.1
    fqdn_ip6:
        - ::1
    gid:
        0
    gpus:
        |_
          ----------
          model:
              VirtualBox Graphics Adapter
          vendor:
              unknown
    groupname:
        root
    host:
        1
    hwaddr_interfaces:
        ----------
        eth0:
            08:00:27:ce:e5:3b
        eth1:
            08:00:27:36:47:bd
        lo:
            00:00:00:00:00:00
    id:
        1.sminion.learn.com
    init:

```

To list only specific grains, you can pass them as arguments to the
`grains.item` function:

```
$ sudo salt '*1*' grains.item os_family osfinger
1.sminion.learn.com:
    ----------
    os_family:
        Debian
    osfinger:
        Ubuntu-14.04
```

> Note that this function does not contain the `s` at the end of `item`!

You can get grains back from everything in the infrastructure, regardless of
the operating system, as long as the system is managed by this Salt master:

```
$ sudo salt '*' grains.item os
0.sminion.learn.com:
    ----------
    os:
        Ubuntu
smaster.learn.com:
    ----------
    os:
        Ubuntu
1.sminion.learn.com:
    ----------
    os:
        CentOS
```

## Custom Grains

Salt will automatically discover grains based on a wide variety of defaults.
However, you may want custom grains for your minions.  This data can be quite
extensive and incredibly useful.  We'll take a look at configuring custom grains
next.

### Configuring Custom Grains

The grains for a node can be configured in two different ways.  One way is to
configure the minion file located at `/etc/salt/minion` and modify the grains
section there.  The following snippet shows the grains configuration example
commented in the minion configuration file.

```
# file: /etc/salt/minion

# Custom static grains for this minion can be specified here and used in SLS
# files just like all other grains. This exmple sets 4 custom grains, with
# the 'roles' grain having two values that can be matched against.
#grains:
#  roles:
#    - webserver
#    - memcache
#  deployment: datacenter4
#  cabinet: 13
#  cab_u: 14-15
#
```

As you can see, the roles grain is a list, whereas the deployment and other
grains have a single value.  Let's uncomment these values and save the file.
Take careful note of the formatting of this data: this is YAML, and YAML is
picky.

> We will discuss YAML in greater detail in the next section.

After modification, the grain section looks like this:

```
# file: /etc/salt/minion

# Custom static grains for this minion can be specified here and used in SLS
# files just like all other grains. This exmple sets 4 custom grains, with
# the 'roles' grain having two values that can be matched against.
grains:
  roles:
    - webserver
    - memcache
  deployment: datacenter4
  cabinet: 13
  cab_u: 14-15
```

For the changes to take effect, we'll have to restart the `salt-minion`.  On Ubuntu:

```
sudo service salt-minion restart
```

On Centos:

```
sudo systemctl restart salt-minion
```

The grains can also be configured in `/etc/salt/minion.d/grains`.  The
configuration and effect are the same, but it gives you additional flexibility
for maintaining a clean and simple configuration. 

### Verifying Custom Grains

If you followed the previous section, then you should have a number of new,
custom grains.  We can validate their presence on the same node using
`salt-call`:

```
$ sudo salt-call grains.item deployment roles cabinet cab_u
local:
    ----------
    deployment:
        datacenter4
    roles:
        - webserver
        - memcache
    cabinet: 13
    cab_u: 14-15
```

> `salt-call` is a command for running Salt functions on the local system
> without involving the master.

Now if we switch to the master, we can use this custom grain for filtering the
same we used the built-in grains!

```
$ sudo salt -G 'roles:webserver' test.ping
0.sminion.learn.com:
    True
1.sminion.learn.com:
    True

$ sudo salt -G 'roles:memcache' test.ping
0.sminion.learn.com:
    True
1.sminion.learn.com:
    True

$ sudo salt '0.sminion.learn.com' grains.item roles
0.sminion.learn.com:
    ----------
    roles:
        - webserver
        - memcache 
```

As you can see from the above commands, when the grain is a list of values, it
is matched as long as the value we specified exists in the list.

Finally, if a grain is set only on certain nodes, you will get blank value for
other nodes for that grain:

```
$ sudo salt '*' grains.item deployment
0.sminion.learn.com:
    ----------
    deployment:
        datacenter4
1.sminion.learn.com:
    ----------
    deployment:
        datacenter4
smaster.learn.com:
    ----------
    deployment:
```

In this section, we learned what grains are and how to examine and use them.
Up next, we'll start digging into YAML, one of the fundamental markup languages
used by SaltStack.

|Home          |Previous                | Next              |
|--------------|------------------------|-------------------|
|[Home](../../)|[Targeting](../target) |[YAML](../yaml)    |
