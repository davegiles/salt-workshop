| Home           | Previous       | Next                   |
|----------------|----------------|------------------------|
| [Home](../../) | [Home](../../) | [Targeting](../target) |

# Setup

The setup uses a simple Vagrant multi-box setup to play around with SaltStack.
You need Vagrant and VirtualBox working on your machine to follow this workshop.
You can install both from the links below:

## Prerequisites

- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- [Vagrant](https://www.vagrantup.com/downloads.html)

> The Vagrant command needs to be run from root directory of this project.

Before you run Vagrant up, change following parameters in `Vagrantfile`
according to your needs or preferences. I typically start 1 master and 2 nodes,
with 2GB for Master and 1GB for nodes based on what I need to build.

## Configure

You can configure these values by setting the following variables.  This shows
the defaults.

```
export MASTER_MEMORY=2048
export MINION_MEMORY=512
export MASTER_INSTANCES=1
export MINION_INSTANCES=2
```

## Run

Now run `vagrant up`, which will download the base boxes, and then setup the
cluster.  If you don't have the base boxes, the download can take some time
based on connection speed.

Once `vagrant up` completes successfully, you should see one master and multiple
minions based on your configuration.  With the default configuration here is
what you should see:

```
$ vagrant status
Current machine states:

salt_master                running (virtualbox)
salt_minion_0              running (virtualbox)
salt_minion_1              running (virtualbox)
```

You can get into any box by using the `vagrant ssh` command:

```
$ vagrant ssh salt_master
vagrant@smaster:~$
```

## Salt Verification

Once you are in the master box, you should see the incoming key requests for the
minions waiting for approval. What this means is that the minions are pointing
to this master and asking for one time approval for them to be managed by this
master.

To manage keys in SaltStack, we use the `salt-key` command.

> Salt commands need to be run as `root`.  Throughout this tutorial, we will use
> `sudo` so that you can explicitly see when `root` is required.

```
$ sudo salt-key
Accepted Keys:
Denied Keys:
Unaccepted Keys:
0.sminion.learn.com
1.sminion.com
smaster.learn.com
Rejected Keys:
```

Let's accept all the incoming keys because we trust these minions:

```
$ sudo salt-key -A
The following keys are going to be accepted:
Unaccepted Keys:
0.sminion.learn.com
1.sminion.learn.com
smaster.learn.com
Proceed? [n/Y] Y
Key for minion 0.sminion.learn.com accepted.
Key for minion 1.sminion.learn.com accepted.
Key for minion smaster.learn.com accepted.
```

Once you have accepted the keys, you will see them in accepted section:

```
$ sudo salt-key
Accepted Keys:
0.sminion.learn.com
1.sminion.learn.com
smaster.learn.com
Denied Keys:
Unaccepted Keys:
Rejected Keys:
```

In a typical production setup where you might be managing hunderds or thousands
of nodes, manually accepting keys can be painful.  You may not want to
automatically accept all keys, but you may also want some a sane and secure way
to validate that you are getting requests from authorized machines.  There are
multiple ways to handle this, but this is left as an exercise for the reader.
For a starting point, try reading
(here)[https://docs.saltstack.com/en/latest/topics/tutorials/preseed_key.html].

> If you actually want to automatically accept all minion keys, you can do so by
> modifying your Salt Master's configuration: 

```
# file: /etc/salt/master.conf

# Enable auto_accept, this setting will automatically accept all incoming
# public keys from the minions. Note that this is insecure.
#auto_accept: False
```

Now that we've accepted all minions' keys, it's time to do a quick
verification that all nodes are reachable using Salt's `test.ping` module:

```
$ sudo salt '*' test.ping
smaster.learn.com:
    True
1.sminion.learn.com:
    True
0.sminion.learn.com:
    True
```

> Your shell might not require you to escape the `*`, but you should do so
> anyway as a matter of best common practice in case you ever run `salt` in a
> shell that treats `*` as a glob.  You can escape it with either `'*'` or
> `\*`.
 
In essence what we are doing in above statement is checking if all nodes are
reachable.  But let's discuss a few details:

- `'*'` : This is called targeting.  By using an asterisk, we are targeting all
          nodes that are managed by this master.  We will look at targeting in
          more detail in the next section.

- `test.ping`: We are calling the ping function in test module here.  Salt has
               many kinds of modules, and test is an execution module. There can
               be state modules for applying states, grains modules for
               gathering grains data, and so on.  Overall, the structure is same
               for all modules: `module_name.function_name`.

In this section, we accepted minion keys using the `salt-key` command, and then
we verified that the minions were reachable by the master.  Next, we'll take a
look at targeting.

| Home           | Previous       | Next                   |
|----------------|----------------|------------------------|
| [Home](../../) | [Home](../../) | [Targeting](../target) |
