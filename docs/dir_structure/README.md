| Home           | Previous            | Next                                    |
|----------------|---------------------|-----------------------------------------|
| [Home](../../) | [Pillar](../pillar) | [Remote Execution](../remote_execution) |

> Note: This module is fairly long.  Perhaps it makes more sense to break the
> section on PKI into its own module.  Not sure.

# Salt Directory Structure

Although we haven't discussed some of the items that we'll be bringing up in
this module, we've already seen that there are a number of places where Salt
stores configuration of some sort.  It's important that we get a handle on the
Salt directory structure before we move forward.

## Basics

We'll go into more detail on these, but here are the high points to keep in
mind:

| Path              | Purpose                                                       |
|-------------------|---------------------------------------------------------------|
| `/etc/salt`       | General configuration for the master, minion, or proxy minion |
| `/srv/salt`       | Master only; stores states                                    |
| `/srv/pillar`     | Master only; stores pillars                                   |
| `/var/cache/salt` | Stores data cached by Salt                                    |

## The `/etc/salt` Directory

We'll start with `/etc/salt`, since this is our first stop toward a production
SaltStack infrastructure.  In this section, we'll start with a directory pattern
common to both Salt Masters and Salt Minions.  Next, we'll cover some
Minion-specific configuration.  We'll wrap the section of by talking about the
Salt Master's configuration.

### Common Patterns

First, it's important to know that in Salt's general configuration directory,
`/etc/salt`, we follow a common Unix configuration file pattern.  We have a
top-level configuration file--`/etc/salt/master` for the master and
`/etc/salt/minion` for the minion.  Next, we have a special directory that can
contain additional configuration files.  These directories are
`/etc/salt/master.d/` and `/etc/salt.minion.d/`.

Inside of these special directories, we can have as many configuration files as
we want, and Salt will automatically merge them together into one massive
configuration at run-time.

### PKI

Next, we have Salt's PKI directories.  These exist at `/etc/salt/pki/`, and they
contain private and public keys used to authenticate nodes.  Two sub-directories
of exist: `/etc/salt/pki/master/` and `/etc/salt/pki/minion`.  Let's look at
`/etc/salt/pki/minion` on `salt_minion_0` first as its a little bit simpler.

```
$ sudo ls -l /etc/salt/pki/minion/
total 12
-rw-r--r-- 1 root root  450 Oct  8 01:12 minion_master.pub
-r-------- 1 root root 1674 Oct  8 01:01 minion.pem
-rw-r--r-- 1 root root  450 Oct  8 01:01 minion.pub
```

Here's a table that explains those files:

| Filename            | Purpose                                  |
|---------------------|------------------------------------------|
| `minion_master.pub` | The public key of the Salt Master        |
| `minion.pem`        | The private key of the local Salt Minion |
| `minion.pub`        | The public key of the local Salt Minion  |

Each minion and master maintains a list of accepted keys.  If the keys change,
the affected minion(s) will no longer talk to the Salt Master because something
is no longer trusted.  We can easily verify this if we delete the key on the
Minion, restart the process, and look at the output of `salt-key` on the Master.

First, delete the key on the Minion and restart it:

```
$ sudo rm /etc/salt/pki/minion/minion.{pem,pub}
$ sudo ls -l /etc/salt/pki/minion/
total 4
-rw-r--r-- 1 root root 450 Oct  8 01:12 minion_master.pub
$ service salt-minion restart
```

> On `salt_minion_1`, the command to restart the Minion is
> `systemctl restart salt-minion`

Now, pop over to the Salt Master and try to ping the minions.  Then, look at the
keys:

```
$ sudo salt '*' test.ping
smaster.learn.com:
    True
1.sminion.learn.com:
    True
0.sminion.learn.com:
    Minion did not return. [No response]
$ sudo salt-key
Accepted Keys:
0.sminion.learn.com
1.sminion.learn.com
smaster.learn.com
Denied Keys:
0.sminion.learn.com
Unaccepted Keys:
Rejected Keys:
```

You can see that the `salt_minion_0` didn't respond.  That's not entirely
accurate, though.  If you look at the `salt-key` output, you can see that we now
have an entry for `0.sminion.learn.com` twice, and one of them is `Denied`!
This means that the Salt Master received a communications attempt from something
that identified itself as `0.sminion.learn.com`, but that its public key no
longer matched an entry that Salt had already accepted.  So let's fix this!

```
# First, print the keys
$ sudo salt-key -p 0.sminion.learn.com
Accepted Keys:
0.sminion.learn.com:  -----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsCxSVh4qUDFY3oKScQqA
vCWIbzZE1QNl7sQVqw4WLLw/6Th9zC86rdeVdEBXvUURyFNktpiJf+f7vgelAFqC
VhztxfTgTrBTxlwFXKVuHz3l9EQaRbZZ3T/K58S3h/29SuH1pAZORfjH87xEK62U
qAfgWdHAltw7mpH5vTMLlBfOKxHNy0mZvo2/y3ZYBhCg3P+YPQbifpHimP+Eefyt
AQ1Q2JALTYcdKH1o4Y+qzVO3WLVOrguQfYGblYamgAZ4iqmCK8nOYHrjs0RjgJSt
Se6oMOMnitZHxTFGO8H8WX4IRo/lv+aSTIVTxGR16778Skzq5skPn6t5AU+b24N6
6wIDAQAB
-----END PUBLIC KEY-----
Denied Keys:
0.sminion.learn.com:  -----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAjPX4kFjtGn+t8/gt6hc3
3fMxhdDQKDRAMXseC1ts4lXS2y8cNdlE4CvczoE1kCzxaWcEc8bxn1Ogmo161fr7
wVY3u+vXrV4CrdkWKRo2M/y3YQJNMAYtXKCda3LB0ar5Qu0LEiBacc43qOhd7xFs
goNJ9vlTrAAdGyzEJBdqE83oTkF3ZBlpTJimqUG6NotpPbdaH8oSMd8zv5D0pXKg
/6iL7t7HfGHo23D9jykmrGjjzhPOLp6vmS5vuccaPV46Jl7Zxr/ZUAfz95oCwLXJ
THEYobZ8gx8RvpnjUlhYDjUOliRW6Fr3XZDQ1x7SHk3ZM8Zzx4GT7aJdf9snEbTD
bwIDAQAB
-----END PUBLIC KEY-----

# Okay, we went back and double-checked our minion, and we know that the `Denied`
# key is legit.  So let's add the new one (and in the process delete the old)
$ sudo salt-key -A --include-denied
The following keys are going to be accepted:
Denied Keys:
0.sminion.learn.com
Proceed? [n/Y] y
Key for minion 0.sminion.learn.com accepted.
$ sudo salt-key
Accepted Keys:
0.sminion.learn.com
1.sminion.learn.com
smaster.learn.com
Denied Keys:
Unaccepted Keys:
Rejected Keys:
```

Great!  Now that we've talked about keys on the Minion, let's move on to the
Salt Master and check out what's going on there.  Note that our Salt Master is
_also_ a Salt Minion, so it also has a `/etc/salt/pki/minion/` directory.  We're
going to ignore that, though, and look strictly at `/etc/salt/pki/master/`.

> Although our Salt Master is also a Salt Minion, this is not a requirement.
> You can deploy a Salt Master without deploying a Minion to the same machine.

```
$ sudo ls -lR /etc/salt/pki/master
/etc/salt/pki/master:
total 28
-r-------- 1 root root 1678 Oct  8 00:59 master.pem
-rw-r--r-- 1 root root  450 Oct  8 00:59 master.pub
drwxr-xr-x 2 root root 4096 Oct  8 17:09 minions
drwxr-xr-x 2 root root 4096 Oct  8 00:59 minions_autosign
drwxr-xr-x 2 root root 4096 Oct  8 17:09 minions_denied
drwxr-xr-x 2 root root 4096 Oct  8 17:08 minions_pre
drwxr-xr-x 2 root root 4096 Oct  8 00:59 minions_rejected

/etc/salt/pki/master/minions:
total 12
-rw-r--r-- 1 root root 450 Oct  8 17:09 0.sminion.learn.com
-rw-r--r-- 1 root root 450 Oct  8 01:11 1.sminion.learn.com
-rw-r--r-- 1 root root 450 Oct  8 01:21 smaster.learn.com

/etc/salt/pki/master/minions_autosign:
total 0

/etc/salt/pki/master/minions_denied:
total 0

/etc/salt/pki/master/minions_pre:
total 0

/etc/salt/pki/master/minions_rejected:
total 0
```

You can see that the Salt Master uses this directory structure to keep track of
keys.  The sub-directories contain keys relevant to that part of the `salt-key`
output.  In addition, we have `/etc/salt/pki/master/master.pem` and
`/etc/salt/pki/master/master.pub`.  These are the Master's private and public
keys.  If we were to regenerate those, the minions would no longer respond to
the master--even though the master had accepted their keys!  Let's do that, too.

```
$ sudo rm /etc/salt/pki/master/master.{pem,pub}
$ sudo service salt-master restart
salt-master stop/waiting
salt-master start/running, process 22653
$ sudo salt-key
Accepted Keys:
0.sminion.learn.com
1.sminion.learn.com
smaster.learn.com
Denied Keys:
Unaccepted Keys:
Rejected Keys:
$ sudo salt '*' test.ping
0.sminion.learn.com:
    Minion did not return. [No response]
1.sminion.learn.com:
    Minion did not return. [No response]
smaster.learn.com:
    Minion did not return. [No response]
$ sudo grep 'Invalid master key' /var/log/salt/minion
SaltClientError: Invalid master key
SaltClientError: Invalid master key
```

You can see now that although the Master has accepted the keys of the minions,
the minions have detected that the Master's key changed and have refused to
communicate with it further.  Restoring proper operation is left as an exercise
for the reader.

> Hint: Delete the master public key on the minions and restart the minion.
 
### Salt Minion Configuration

Let's look at the Salt Minion's configuration.  It's actually incredibly simple.
All it actually requires is a key `master` with a value of a hostname or IP
address that the minion can resolve to reach the master!  In our example, that's
all we really have besides the `grains` key we added previously.  We also have
`/etc/salt/minion.d/_schedule.conf`, which schedules a Salt Mine run on a
interval.  We aren't going to talk about either of those right now, though.
Both scheduling and the Salt Mine have their own modules.

### Salt Master Configuration

The Salt Master's configuration is significantly more involved.  You can set the
TCP ports used, whether or not to use IPv6, file descriptor limits, worker
threads, and so on.  Most of this is out of scope for this workshop, and the
configuration file is extremely well-documented.  We will, however, talk about
two specific configuration options: `file_roots` and `pillar_roots`.

First, let's look at `file_roots`:

```yaml
# The file server works on environments passed to the master, each environment 
# can have multiple root directories, the subdirectories in the multiple file 
# roots cannot match, otherwise the downloaded files will not be able to be
# reliably ensured. A base environment is required to house the top file.
# Example:
file_roots:
  base:
    - /srv/salt/
    - /vagrant/salt/srv/salt
```

Pretty self-explanatory, right?  You can have environments, and they can point
to different locations on disk.  We won't talk about environments in this
workshop, but they're really just ways to segregate data.  This is where things
like your states and templates will go.  Note that pillar data doesn't go here.

So where does pillar data go?  Well, let's look at `pillar_roots`!

```yaml
# Salt Pillars allow for the building of global data that can be made selectively
# available to different minions based on minion grain filtering. The Salt
# Pillar is laid out in the same fashion as the file server, with environments,
# a top file and sls files. However, pillar data does not need to be in the
# highstate format, and is generally just key/value pairs.
pillar_roots:
  base:
    - /srv/pillar
    - /vagrant/salt/srv/pillar
```

Again, the documentation inside of a Salt configuration file is excellent.
This is where your pillar data is stored, and it can also have environments.

As with the Minion configuration, you can place files in `/etc/salt/master.d/`
and they will get merged into a single configuration file.  This is great for
managing and maintaining large or complex configurations.

### Using the `/etc/salt/*.d/` Directories

It's import to understand that all of these configuration files are YAML, and
that when you make use of the `/etc/salt/master.d/` and `/etc/salt/minion.d/`
directories to help you manage your configuration, Salt will merge the
configurations together.  What can happen is that you define the same key in
multiple files, and then a potentially unpredictable result is used.  It is
critical when using this strategy that you do not overwrite keys.

## The `/srv/salt/` Directory

This directory serves non-pillar data, like Salt States or templates.  Once a
file or folder exists here, it can be accessed via a special Salt URI at
`salt://`.  If this doesn't make sense right now, don't worry.  We'll see more
of it throughout this workshop, particularly when we start looking at Salt
States.

At a minimum, your states will need a `top.sls` here.  That topfile must then
associate states as appropriate.

## The `/srv/pillar/` Directory

This directory serves pillar data.  Normally, you don't directory reference
files here; you just access the pillar data.

Similar to the `/srv/salt/` directory, you need a `top.sls` here.  It is what
assigns pillar data to specific minions.  From there, you can use
sub-directories to your heart's content, as long as you reference the relative
path correctly in the topfile.

## The `/var/cache/salt/` Directory

You should almost never have to interact with data here.  This is data that is
internal to Salt's workings, and while it can sometimes be helpful for debugging
(particularly when using GitFS), we won't be looking at it in this workshop.

## Conclusion

We've covered most of the common directories in a SaltStack implementation.
It's important to remember that you can set your own `file_roots` and
`pillar_roots`, so a production deployment may have different directories than
are listed here, but their purpose is still the same.  In some deployments,
`git` might be used to serve files.  In this case, you may not even have a
`file_roots` or `pillar_roots`!

We've also covered Salt's PKI.  Although we didn't look at the internals, we did
look at some things that can happen and how Salt maintains security and
integrity when communicating with nodes--whether it's on the minion's side or
the master's.

Next up, we'll look at remote execution.  We've done a little bit of this with
the `test.ping`, `pillar.item`, and `grains.item` functions.  However, we'll
start looking at other remote execution modules and functions that allow you to
perform meaningful work on a system!

| Home           | Previous            | Next                                    |
|----------------|---------------------|-----------------------------------------|
| [Home](../../) | [Pillar](../pillar) | [Remote Execution](../remote_execution) |
