|Home          |Previous          | Next              |
|--------------|------------------|-------------------|
|[Home](../../)|[Setup](../setup) |[Grains](../grains)|

# Targeting

In the first module when we fired command like `sudo salt '*'` the asterisk mark
meant "execute the Salt function on all nodes."  The asterisk is a wildcard that
represents all of the minions.  In the real world, though, we need to target a
set of nodes which have specific attributes.  Consider the following scenarios
that you might encounter as someone who is managing 100s, or even just a handful,
of machines:

* I want to find out the status of Nginx service on all webservers
* I want to replace a small string in a config file on all the database servers

It is also common to classify things on multiple conditions:

2 conditions: 

* I want to find out all machines which are running Ubuntu the AWS region
  `us-east-1`

3 conditions:

* I want to upgrade all RHEL 7 systems that are also application servers and
  running Java 7 to Java 8, but if they're running Java 6, do nothing

What about managing vulnerabilities?

* I want to query all Windows systems with version `XYZ` of a specific patch
  installed so I can fix these systems before a malicious actor compromises them

## Targeting strategies

There are multiple ways you can target minions in Salt. Let's look at a few.

To target only systems running Ubuntu, we can use grain targeting and a grain
called `os`:

```
$ sudo salt -G 'os:Ubuntu' test.ping

1.sminion.learn.com:
    True
0.sminion.learn.com:
    True
smaster.learn.com:
    True
```

> For now, just know that grains are like information about a system.  We'll
> look at grains in more detail in the next section.

We can also filter based on the subnet using the -S flag:

```
$ sudo salt -S '192.168.17.80' test.ping

smaster.learn.com:
    True
```

> If you changed your `SALT_SUBNET` environment variable, don't forget to change
> it to match in the command above.

If you have more than one condition, then you can use the compound targeting
option (-C).  In the condition, use the flags followed by `@` to specify the
filtering. In following example we check if the subnet matches and also that the
`os` grain is Ubuntu:

```
$sudo salt -C 'S@192.168.17.80 and G@os:Ubuntu' test.ping

smaster.learn.com:
    True
```

You can also use glob matching.  In the following example, we are targeting all
nodes with a range of numbers between `0` and `9` in the name:

```
$ sudo salt '*[0-9]*' test.ping

0.sminion.learn.com:
    True
1.sminion.learn.com:
    True
```

If you want a specific list of nodes, you can use the `-L` flag.

```
$ sudo salt -L '0.sminion.learn.com,1.sminion.learn.com' test.ping

1.sminion.learn.com:
    True
0.sminion.learn.com:
    True
```

We can also use regex matching to target nodes with `-E`:

```
$ sudo salt -E '^smaster.*$' test.ping

smaster.learn.com:
    True
```

In this section, we've learned about the various targeting options.  In the next
section, we'll explore grains.

|Home          |Previous          | Next              |
|--------------|------------------|-------------------|
|[Home](../../)|[Setup](../setup) |[Grains](../grains)|
