| Home           | Previous                    | Next                                     |
|----------------|-----------------------------|------------------------------------------|
| [Home](../../) | [Salt Proxy](../salt_proxy) | [Network Device State](../net_dev_state) |

# Network Device Execution

In our previous section, we brought up two router VMs and very briefly explored
remote execution with the `net.cli` function.  When interacting with routers
that use Salt Proxy with NAPALM, we'll primarily be using the `net` module.
Remember that you can view the documentation of this module by simply typing
`sudo salt '*' sys.doc net` on the Salt Master.
In this module, we'll explore _some_ of the functions in the `net` module.
We'll skip a few, such as `net.mac`, because they aren't supported on our
virtual routers.  We'll skip others simply because covering all of the functions
wouldn't leave much for you to discover on your own.

## `net.cli`

We've already seen `net.cli`, but we should talk about it a little more.  You
can use it to pass normal CLI commands to a router.  Since different vendors run
different operating systems and the commands can be drastically different, it
can be useful to target specific operating systems or groups.  Let's see an
example of `net.cli` in action:

```
$ sudo salt -G os:junos net.cli 'sh ver and haiku' 'sh int terse | match inet'
rtr1:
    ----------
    comment:
    out:
        ----------
        sh int terse | match inet:
            bme0.0                  up    up   inet     128.0.0.1/2
            em0.0                   up    up   inet     10.0.2.15/24
            em1.0                   up    up   inet     192.168.17.31/24
            lo0.0                   up    up   inet
                                               inet6    fe80::200:f:fc00:0
            lo0.16385               up    up   inet
        sh ver and haiku:

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


                    Look, mama, no hands!
                    Only one finger typing.
                    Easy: commit scripts.
    result:
        True
rtr2:
    ----------
    comment:
    out:
        ----------
        sh int terse | match inet:
            bme0.0                  up    up   inet     128.0.0.1/2
            em0.0                   up    up   inet     10.0.2.15/24
            em1.0                   up    up   inet     192.168.17.32/24
            lo0.0                   up    up   inet
                                               inet6    fe80::200:f:fc00:0
            lo0.16385               up    up   inet
        sh ver and haiku:

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


                    IS-IS sleeps.
                    BGP peers are quiet.
                    Something must be wrong.
    result:
        True
```

As you can see, you can also use a pipe to filter command output.  This makes
it easy to easily filter out data across many devices from a single point of
entry.

## `net.arp`

If you need to check for an ARP entry, you can do so easily using the `net.arp`
module.  This module accepts arguments that let you filter the results based on
MAC address or IP address:

```
$ sudo salt -G os:junos net.arp macaddr=08:00:27:C9:A2:A3
rtr2:
    ----------
    comment:
    out:
        |_
          ----------
          age:
              677.0
          interface:
              em1.0
          ip:
              192.168.17.51
          mac:
              08:00:27:C9:A2:A3
    result:
        True
rtr1:
    ----------
    comment:
    out:
        |_
          ----------
          age:
              56.0
          interface:
              em1.0
          ip:
              192.168.17.51
          mac:
              08:00:27:C9:A2:A3
    result:
        True
$ sudo salt -G os:junos net.arp ipaddr=10.0.2.2
rtr2:
    ----------
    comment:
    out:
        |_
          ----------
          age:
              83.0
          interface:
              em0.0
          ip:
              10.0.2.2
          mac:
              52:54:00:12:35:02
    result:
        True
rtr1:
    ----------
    comment:
    out:
        |_
          ----------
          age:
              2.0
          interface:
              em0.0
          ip:
              10.0.2.2
          mac:
              52:54:00:12:35:02
    result:
        True
```

If you don't specify an argument, it will return the complete ARP table.

## `net.traceroute`

Similar to `network.traceroute`, `net.traceroute` lets us run a traceroute from
our routers.  In this example, we'll only target one because the output is
pretty lengthy:

```
$ sudo salt rtr1 net.traceroute 8.8.8.8
rtr1:
    ----------
    comment:
    out:
        ----------
        success:
            ----------
            1:
                ----------
                probes:
                    ----------
                    1:
                        ----------
                        host_name:
                            10.0.2.2
                        ip_address:
                            10.0.2.2
                        rtt:
                            0.339
                    2:
                        ----------
                        host_name:
                            10.0.2.2
                        ip_address:
                            10.0.2.2
                        rtt:
                            0.294
                    3:
                        ----------
                        host_name:
                            10.0.2.2
                        ip_address:
                            10.0.2.2
                        rtt:
                            0.459
            2:
                ----------
                probes:
                    ----------
                    1:
                        ----------
                        host_name:
                            192.168.0.1
                        ip_address:
                            192.168.0.1
                        rtt:
                            3.843
                    2:
                        ----------
                        host_name:
                            192.168.0.1
                        ip_address:
                            192.168.0.1
                        rtt:
                            3.035
                    3:
                        ----------
                        host_name:
                            192.168.0.1
                        ip_address:
                            192.168.0.1
                        rtt:
                            3.343
            3:
                ----------
                probes:
                    ----------
                    1:
                        ----------
                        host_name:
                            96.120.85.5
                        ip_address:
                            96.120.85.5
                        rtt:
                            17.413
                    2:
                        ----------
                        host_name:
                            96.120.85.5
                        ip_address:
                            96.120.85.5
                        rtt:
                            12.909
                    3:
                        ----------
                        host_name:
                            96.120.85.5
                        ip_address:
                            96.120.85.5
                        rtt:
                            12.254
            4:
                ----------
                probes:
                    ----------
                    1:
                        ----------
                        host_name:
                            68.85.93.45
                        ip_address:
                            68.85.93.45
                        rtt:
                            12.81
                    2:
                        ----------
                        host_name:
                            68.85.93.45
                        ip_address:
                            68.85.93.45
                        rtt:
                            16.649
                    3:
                        ----------
                        host_name:
                            68.85.93.45
                        ip_address:
                            68.85.93.45
                        rtt:
                            10.275
            5:
                ----------
                probes:
                    ----------
                    1:
                        ----------
                        host_name:
                            ae-65-ar05.savannah.ga.savannah.comcast.net
                        ip_address:
                            68.86.250.221
                        rtt:
                            12.115
                    2:
                        ----------
                        host_name:
                            ae-65-ar05.savannah.ga.savannah.comcast.net
                        ip_address:
                            68.86.250.221
                        rtt:
                            14.099
                    3:
                        ----------
                        host_name:
                            ae-65-ar05.savannah.ga.savannah.comcast.net
                        ip_address:
                            68.86.250.221
                        rtt:
                            11.74
            6:
                ----------
                probes:
                    ----------
                    1:
                        ----------
                        host_name:
                            ae-20-ar02.southside.fl.jacksvil.comcast.net
                        ip_address:
                            68.87.165.13
                        rtt:
                            19.902
                    2:
                        ----------
                        host_name:
                            ae-20-ar02.southside.fl.jacksvil.comcast.net
                        ip_address:
                            68.87.165.13
                        rtt:
                            40.975
                    3:
                        ----------
                        host_name:
                            ae-20-ar02.southside.fl.jacksvil.comcast.net
                        ip_address:
                            68.87.165.13
                        rtt:
                            21.753
            7:
                ----------
                probes:
                    ----------
                    1:
                        ----------
                        host_name:
                            be-33489-cr02.miami.fl.ibone.comcast.net
                        ip_address:
                            68.86.95.45
                        rtt:
                            28.338
                    2:
                        ----------
                        host_name:
                            be-33489-cr02.miami.fl.ibone.comcast.net
                        ip_address:
                            68.86.95.45
                        rtt:
                            24.831
                    3:
                        ----------
                        host_name:
                            be-33489-cr02.miami.fl.ibone.comcast.net
                        ip_address:
                            68.86.95.45
                        rtt:
                            23.749
            8:
                ----------
                probes:
                    ----------
                    1:
                        ----------
                        host_name:
                            be-12274-pe01.nota.fl.ibone.comcast.net
                        ip_address:
                            68.86.82.154
                        rtt:
                            27.691
                    2:
                        ----------
                        host_name:
                            be-12274-pe01.nota.fl.ibone.comcast.net
                        ip_address:
                            68.86.82.154
                        rtt:
                            23.47
                    3:
                        ----------
                        host_name:
                            be-12274-pe01.nota.fl.ibone.comcast.net
                        ip_address:
                            68.86.82.154
                        rtt:
                            23.475
            9:
                ----------
                probes:
                    ----------
                    1:
                        ----------
                        host_name:
                            as15169-2-c.nota.fl.ibone.comcast.net
                        ip_address:
                            66.208.228.98
                        rtt:
                            24.884
                    2:
                        ----------
                        host_name:
                            as15169-2-c.nota.fl.ibone.comcast.net
                        ip_address:
                            66.208.228.98
                        rtt:
                            24.761
                    3:
                        ----------
                        host_name:
                            as15169-1-c.nota.fl.ibone.comcast.net
                        ip_address:
                            23.30.206.118
                        rtt:
                            20.822
            10:
                ----------
                probes:
                    ----------
                    1:
                        ----------
                        host_name:
                            108.170.249.1
                        ip_address:
                            108.170.249.1
                        rtt:
                            25.097
                    2:
                        ----------
                        host_name:
                            108.170.249.17
                        ip_address:
                            108.170.249.17
                        rtt:
                            33.876
                    3:
                        ----------
                        host_name:
                            108.170.249.1
                        ip_address:
                            108.170.249.1
                        rtt:
                            26.789
            11:
                ----------
                probes:
                    ----------
                    1:
                        ----------
                        host_name:
                            108.170.226.69
                        ip_address:
                            108.170.226.69
                        rtt:
                            19.799
                    2:
                        ----------
                        host_name:
                            108.170.226.9
                        ip_address:
                            108.170.226.9
                        rtt:
                            28.887
                    3:
                        ----------
                        host_name:
                            108.170.228.45
                        ip_address:
                            108.170.228.45
                        rtt:
                            20.972
            12:
                ----------
                probes:
                    ----------
                    1:
                        ----------
                        host_name:
                            google-public-dns-a.google.com
                        ip_address:
                            8.8.8.8
                        rtt:
                            23.106
                    2:
                        ----------
                        host_name:
                            google-public-dns-a.google.com
                        ip_address:
                            8.8.8.8
                        rtt:
                            22.007
                    3:
                        ----------
                        host_name:
                            google-public-dns-a.google.com
                        ip_address:
                            8.8.8.8
                        rtt:
                            25.33
    result:
        True
```

## `net.load_template`

This is where things get interesting.  We can now create configuration templates
and Salt can push them to a device.  Let's try that!  First, let's add a new
file root.  We'll start by creating the directory:

```
$ sudo mkdir /srv/template
$ ls -d /srv/template
/srv/template
```

Now, let's update our Salt Master's `file_roots` in `/etc/salt/master`:

```yaml
# file: /etc/salt/master

file_roots:
  base:
    - /srv/salt/
    - /srv/template/
```

And restart the master with `sudo service salt-master restart` so that it picks
up the changes.

Now, let's create a template at `/srv/template/snmp.j2`:

```yaml
# file: /srv/template/snmp.j2

snmp {
    description {{ salt.grains.get('id') }};
    contact "{{ salt.pillar.get('snmp:contact') }}";
    interface {{ salt.pillar.get('snmp:interface') }};
    community {{ salt.pillar.get('snmp:community') }};
}
```

Now that we have the template, we need to have the pillar data available to fill
out that template.  Let's do that now by creating `/srv/pillar/snmp.sls`:

```yaml
# file: /srv/pillar/snmp.sls

snmp:
  contact: "It's too late for that now."
  interface: em0.0
  community: yaySalt
```

And now let's make sure we associate that pillar with our routers by updating
`/srv/pillar/top.sls`:

```yaml
# file: /srv/pillar/top.sls

base:
  'rtr*':
    - snmp
```

And, of course, refresh the pillar data with
`sudo salt '*' saltutil.refresh_pillar`.  Once that's done, let's try using our
brand new template:

```
$ sudo salt 'rtr*' net.load_template salt://snmp.j2 test=True
rtr1:
    ----------
    already_configured:
        False
    comment:
        Configuration discarded.
    diff:
        [edit]
        +  snmp {
        +      description rtr1;
        +      contact "It's too late for that now.";
        +      interface em0.0;
        +      community yaySalt;
        +  }
    loaded_config:
    result:
        True
rtr2:
    ----------
    already_configured:
        False
    comment:
        Configuration discarded.
    diff:
        [edit]
        +  snmp {
        +      description rtr2;
        +      contact "It's too late for that now.";
        +      interface em0.0;
        +      community yaySalt;
        +  }
    loaded_config:
    result:
        True
```

We can see the diff in the config before we apply it by using `test=True`.  Now,
let's _actually_ apply our template:

```
$ sudo salt 'rtr*' net.load_template salt://snmp.j2
rtr1:
    ----------
    already_configured:
        False
    comment:
    diff:
        [edit]
        +  snmp {
        +      description rtr1;
        +      contact "It's too late for that now.";
        +      interface em0.0;
        +      community yaySalt;
        +  }
    loaded_config:
    result:
        True
rtr2:
    ----------
    already_configured:
        False
    comment:
    diff:
        [edit]
        +  snmp {
        +      description rtr2;
        +      contact "It's too late for that now.";
        +      interface em0.0;
        +      community yaySalt;
        +  }
    loaded_config:
    result:
        True
```

And let's run the same template again to make sure it's still configured:

```
$ sudo salt 'rtr*' net.load_template salt://snmp.j2
rtr2:
    ----------
    already_configured:
        True
    comment:
        Already configured.
    diff:
    loaded_config:
    result:
        True
rtr1:
    ----------
    already_configured:
        True
    comment:
        Already configured.
    diff:
    loaded_config:
    result:
        True
```

And, in case you just don't trust it, let's use `net.cli` to get that section of
the config:

```
$ sudo salt 'rtr*' net.cli 'show config snmp'
rtr1:
    ----------
    comment:
    out:
        ----------
        show config snmp:

            description rtr1;
            contact "It's too late for that now.";
            interface em0.0;
            community yaySalt;
    result:
        True
rtr2:
    ----------
    comment:
    out:
        ----------
        show config snmp:

            description rtr2;
            contact "It's too late for that now.";
            interface em0.0;
            community yaySalt;
    result:
        True
```

> You also could have used the `net.config` function, with the `source=running`
> argument, but that will give you the entire configuration, not just the SNMP
> section.

# Conclusion

In this section, we've looked at a few of the execution modules, including
creating templates and applying them to our routers.  This particular skill will
come in handy in the next module where we'll talk about states.

| Home           | Previous                    | Next                                     |
|----------------|-----------------------------|------------------------------------------|
| [Home](../../) | [Salt Proxy](../salt_proxy) | [Network Device State](../net_dev_state) |
