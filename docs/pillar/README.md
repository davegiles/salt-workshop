| Home           | Previous        | Next                                    |
|----------------|-----------------|-----------------------------------------|
| [Home](../../) | [YAML](../yaml) | [Directory Structure](../dir_structure) |

# Pillar

We have previously covered grains, which are details about a system that Salt
discovers.  In addition to this data, there is another source of information:
configuration data defined by an engineer on the Salt master and exposed to the
relevant nodes.

### Pillars vs. Grains

We briefly need to explain the difference between a grain and a pillar.  While
at first glance they appear to fulfill similar rules, they are drastically
different.  The simplest way to view them is this:

- Grains are things that the minion knows about itself
- Pillars are things that the master assigns to a minion

Consider the case of assigning roles.  One approach is to use grains, and one is
to use pillars.  If you use a pillar, how do you know which minions should have
a given role?  You could manually maintain a list on the master, but this would
not be as good as giving a minion a custom grain that describes its role.  Then,
when you need to assign pillar data, such as what database an API server should
use, you can target the `api_server` role in the pillar topfile.

To put all of this another way:

- Grains are what a minion knows about itself
- Pillars help a minion know how it should operate

## Define a Pillar

Defining a pillar is simple: we just write some YAML and put it in the right
directory.  All pillar data is created on the master, so let's create a file on
the master at `/srv/pillar/webserver.sls`.  Its contents should be the following:

```yaml
# file: /srv/pillar/webserver.sls

web:
  banner: "Hello, world!"
```

That's all there is to defining a pillar!

This is a contrived example, but it will serve our purposes just fine.  We'll
use it later when we go through a series of execution functions to build an
`nginx` server.

## Assign

Okay, great.  We've got a pillar defined.  Now how do we actually do things with
it?  For that, we have to assign the pillar to a minion.  To do that, ensure
that only the minion running Ubuntu has the role of `webserver`.  To verify,
use the `grains.item` function:

```
$ sudo salt '*' grains.item roles
0.sminion.learn.com:
    ----------
    roles:
        - webserver
1.sminion.learn.com:
    ----------
    roles:
smaster.learn.com:
    ----------
    roles:
```

> If you need a refresher on how to make this happen, revisit the
> [Grains](../grains) module.

Once that's done, let's create a Pillar topfile.  The concept of the topfile is
common across many aspects of Salt.  It's basically a way to associate data with
minions.  So, on the master, create the `/srv/pillar/top.sls` file with the
following contents:

```yaml
base:
  - 'G@roles:webserver':
    - webserver
```

Okay!  Great!  Now, let's see if our minion has the `web` pillar variable!

```
$ sudo salt -G 'roles:webserver' pillar.item web
0.sminion.learn.com:
    ----------
    web:
```

Wait!  Where is it?  Well, we still have more work to do.  We have to actually
push the pillar data to the minions.  Let's do that now using the
`saltutil.refresh_pillar` function:

```
$ sudo salt '*' saltutil.refresh_pillar
1.sminion.learn.com:
    True
smaster.learn.com:
    True
0.sminion.learn.com:
    True
```

Okay.  Now, cross your fingers and...:

```
$ sudo salt -G 'roles:webserver' pillar.item web
0.sminion.learn.com:
    ----------
    web:
        ----------
        banner:
            Hello, World!
```

Great!  But is it maybe on our other nodes?  Let's check!

```
$ sudo salt -C 'not G@roles:webserver' pillar.item web
1.sminion.learn.com:
    ----------
    web:
smaster.learn.com:
    ----------
    web:
```

> Salt's targeting is incredibly powerful.  Above, we targeted every minion that
> did not have the `webserver` role.

Success!  Now you know how to create and assign pillars!

## Playing with Pillar

We've already seen how you can show a pillar item above with the `pillar.item`
function.  What if you want to see only a specific value of a pillar item?  We
can do that with the colon separator, like this:

```
$ sudo salt -G 'roles:webserver' pillar.item web:banner
0.sminion.learn.com:
    ----------
    web:banner:
        Hello, World!
```

> This is the same as using a colon separator when looking at a grain item.

We briefly discussed assigning pillar data previously.  Let's change the value
of the banner to something different, though.  Let's make the value of the
`web:banner` pillar `My super awesome web server!`:

```yaml
# file: /srv/pillar/webserver.sls

web:
  banner: My super awesome web server!
```

And now, let's verify that the change is reflected in the minion:

```
$ sudo salt -G 'roles:webserver' pillar.item web:banner
0.sminion.learn.com:
    ----------
    web:banner:
        Hello, World!
```

Oops!  As it turns out, you need to refresh pillar data every time it changes to
ensure the minions have the most current pillar data:

```
$ sudo salt '0*' saltutil.refresh_pillar
0.sminion.learn.com:
    True
```

And let's see if we have what we expect now:

```
$ sudo salt -E '[0-9].s?minion.learn.com' pillar.item web:banner
0.sminion.learn.com:
    ----------
    web:banner:
        My super awesome web server!
1.sminion.learn.com:
    ----------
    web:banner:
```

> Here we use the PCRE target matcher.  It uses a regular expression to match
> nodes.

Excellent!  Our change is reflected!

# Conclusion

We've shown how you can create and assign pillars, as well as a brief sidebar on
the differences between grains and pillars.  Next, we'll start talking about the
Salt directory structure and how it can be modified.

| Home           | Previous        | Next                                    |
|----------------|-----------------|-----------------------------------------|
| [Home](../../) | [YAML](../yaml) | [Directory Structure](../dir_structure) |
