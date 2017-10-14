| Home           | Previous                                | Next              |
|----------------|-----------------------------------------|-------------------|
| [Home](../../) | [Directory Structure](../dir_structure) | [Jinja](../jinja) |

# Remote Execution

We'll take a brief tour of remote execution with SaltStack.  It should already
be familiar, but now we're going to look at a few more functions available, as
well as dissect an actual command.

## Ad-Hoc Commands

Sometimes, you may want to run an ad-hoc command on a remote system.  This is
easy with salt using the `cmd.run` function.  Let's use it to `grep` for a
string in a file:

```
$ sudo salt '*' cmd.run 'grep -i version /etc/os-release'
0.sminion.learn.com:
    VERSION="14.04.5 LTS, Trusty Tahr"
    VERSION_ID="14.04"
1.sminion.learn.com:
    VERSION="7 (Core)"
    VERSION_ID="7"
    CENTOS_MANTISBT_PROJECT_VERSION="7"
    REDHAT_SUPPORT_PRODUCT_VERSION="7"
smaster.learn.com:
    VERSION="14.04.5 LTS, Trusty Tahr"
    VERSION_ID="14.04"
```

This was incredibly quick!  Now, let's dissect the command we just ran:

- `sudo`: root privileges are needed to run `salt` by default; this gives us
          that escalation
- `salt`: this is the actual `salt` command
- `*`: this is our target specification
- `cmd`: this is the Salt module where we'll find the function we want to use
- `.`: this separates the module from the function and should be familiar to
       Pythonistas
- `run`: this is the function we want to execute on the nodes that matched our
         target
-`'grep -i version /etc/os-release'`: this is an argument to the `cmd.run`
                                      function that tells the remote system what
                                      command to run.

Most `salt` commands will follow this pattern.  Named arguments are also
possible.  Let's see the previous command with named arguments instead:

```
$ sudo salt '*' cmd.run cmd='grep -i version os-release' cwd=/etc
1.sminion.learn.com:
    VERSION="7 (Core)"
    VERSION_ID="7"
    CENTOS_MANTISBT_PROJECT_VERSION="7"
    REDHAT_SUPPORT_PRODUCT_VERSION="7"
0.sminion.learn.com:
    VERSION="14.04.5 LTS, Trusty Tahr"
    VERSION_ID="14.04"
smaster.learn.com:
    VERSION="14.04.5 LTS, Trusty Tahr"
    VERSION_ID="14.04"
```

This is _almost_ the same command, except that we've told Salt that we want to
run the command from the `/etc` directory using the `cwd` argument, and we
explicitly assigned a value to the `cmd` argument.  But how did we know what
arguments to use?

You have two options.  One is to read the documentation on Salt's website.  But
if you don't want to context switch, you can use `sys.doc` to find the
documentation for any function!  Let's look at `cmd.run`'s documentation now:

```
{% raw %}
$ sudo salt '*' sys.doc cmd.run
cmd.run:

    Execute the passed command and return the output as a string

    Note that ``env`` represents the environment variables for the command, and
    should be formatted as a dict, or a YAML string which resolves to a dict.

    :param str cmd: The command to run. ex: ``ls -lart /home``

    :param str cwd: The current working directory to execute the command in.
      Defaults to the home directory of the user specified by ``runas``.

    :param str stdin: A string of standard input can be specified for the
      command to be run using the ``stdin`` parameter. This can be useful in cases
      where sensitive information must be read from standard input.

    :param str runas: User to run command as. If running on a Windows minion you
      must also pass a password. The target user account must be in the
      Administrators group.

    :param str password: Windows only. Required when specifying ``runas``. This
      parameter will be ignored on non-Windows platforms.

      New in version 2016.3.0

    :param str shell: Shell to execute under. Defaults to the system default
      shell.

    :param bool python_shell: If ``False``, let python handle the positional
      arguments. Set to ``True`` to use shell features, such as pipes or
      redirection.

    :param bool bg: If ``True``, run command in background and do not await or
      deliver it's results

      New in version 2016.3.0

    :param list env: A list of environment variables to be set prior to
      execution.

        Example:

            salt://scripts/foo.sh:
              cmd.script:
                - env:
                  - BATCH: 'yes'

        Warning:

            The above illustrates a common PyYAML pitfall, that **yes**,
            **no**, **on**, **off**, **true**, and **false** are all loaded as
            boolean ``True`` and ``False`` values, and must be enclosed in
            quotes to be used as strings. More info on this (and other) PyYAML
            idiosyncrasies can be found :ref:`here <yaml-idiosyncrasies>`.

        Variables as values are not evaluated. So $PATH in the following
        example is a literal '$PATH':

            salt://scripts/bar.sh:
              cmd.script:
                - env: "PATH=/some/path:$PATH"

        One can still use the existing $PATH by using a bit of Jinja:

            {% set current_path = salt['environ.get']('PATH', '/bin:/usr/bin') %}

            mycommand:
              cmd.run:
                - name: ls -l /
                - env:
                  - PATH: {{ [current_path, '/my/special/bin']|join(':') }}

    :param bool clean_env: Attempt to clean out all other shell environment
      variables and set only those provided in the 'env' argument to this
      function.

    :param str template: If this setting is applied then the named templating
      engine will be used to render the downloaded file. Currently jinja, mako,
      and wempy are supported

    :param bool rstrip: Strip all whitespace off the end of output before it is
      returned.

    :param str umask: The umask (in octal) to use when running the command.

    :param str output_loglevel: Control the loglevel at which the output from
      the command is logged. Note that the command being run will still be logged
      (loglevel: DEBUG) regardless, unless ``quiet`` is used for this value.

    :param int timeout: A timeout in seconds for the executed process to return.

    :param bool use_vt: Use VT utils (saltstack) to stream the command output
      more interactively to the console and the logs. This is experimental.

    :param bool encoded_cmd: Specify if the supplied command is encoded.
      Only applies to shell 'powershell'.

    Warning:
        This function does not process commands through a shell
        unless the python_shell flag is set to True. This means that any
        shell-specific functionality such as 'echo' or the use of pipes,
        redirection or &&, should either be migrated to cmd.shell or
        have the python_shell=True flag set here.

        The use of python_shell=True means that the shell will accept _any_ input
        including potentially malicious commands such as 'good_command;rm -rf /'.
        Be absolutely certain that you have sanitized your input prior to using
        python_shell=True

    CLI Example:

        salt '*' cmd.run "ls -l | awk '/foo/{print \\$2}'"

    The template arg can be set to 'jinja' or another supported template
    engine to render the command arguments before execution.
    For example:

        salt '*' cmd.run template=jinja "ls -l /tmp/{{grains.id}} | awk '/foo/{print \\$2}'"

    Specify an alternate shell with the shell parameter:

        salt '*' cmd.run "Get-ChildItem C:\\ " shell='powershell'

    A string of standard input can be specified for the command to be run using
    the ``stdin`` parameter. This can be useful in cases where sensitive
    information must be read from standard input.:

        salt '*' cmd.run "grep f" stdin='one\\ntwo\\nthree\\nfour\\nfive\\n'

    If an equal sign (``=``) appears in an argument to a Salt command it is
    interpreted as a keyword argument in the format ``key=val``. That
    processing can be bypassed in order to pass an equal sign through to the
    remote shell command by manually specifying the kwarg:

        salt '*' cmd.run cmd='sed -e s/=/:/g'
{% endraw %}
```

That...is a lot of documentation.  And plenty of examples and explanation!  Most
of Salt's modules are thoroughly documented; all are available for perusal from
`sys.doc`.

Now, we know how to look at documentation, but it can also be useful to see what
modules and functions are actually available on a minion.  For that, we have
`sys.list_modules` and `sys.list_functions`.  We'll leave `sys.list_modules` as
an exercise for the reader since its output is so long, but lets have a look at
`sys.list_functions`.

```
$ sudo salt '0*' sys.list_functions 'cmd'                                                                             
0.sminion.learn.com:
    - cmd.exec_code
    - cmd.exec_code_all
    - cmd.has_exec
    - cmd.powershell
    - cmd.retcode
    - cmd.run
    - cmd.run_all
    - cmd.run_bg
    - cmd.run_chroot
    - cmd.run_stderr
    - cmd.run_stdout
    - cmd.script
    - cmd.script_retcode
    - cmd.sdecode
    - cmd.shell
    - cmd.shell_info
    - cmd.shells
    - cmd.tty
    - cmd.which
    - cmd.which_bin
```

## The `network.traceroute` Function

So far, none of this has been truly practical.  What if you want to collect a
traceroute from a collection of hosts?  Salt makes it easy!  Sure, you could
use the `cmd.run` function, but Salt actually provides `network.traceroute`,
so let's use that instead:

```
$ sudo salt '*' network.traceroute 8.8.8.8                                                                             
1.sminion.learn.com:
0.sminion.learn.com:
smaster.learn.com:
```

Salt did something that is ostensibly unexpected here: it fails silently!  Why
is that?  Well, first, let's make sure that we can traceroute from our master:

```
$ traceroute 8.8.8.8
The program 'traceroute' can be found in the following packages:
 * inetutils-traceroute
 * traceroute
Ask your administrator to install one of them
```

Ah!  Well, that makes sense!  Let's see if that's the case with all of our
systems:

```
$ sudo salt '*' pkg.info_installed traceroute
0.sminion.learn.com:
    ----------
    traceroute:
        ----------
        description:
            
        name:
            traceroute
        source:
            traceroute
smaster.learn.com:
    ----------
    traceroute:
        ----------
        description:
            
        name:
            traceroute
        source:
            traceroute
1.sminion.learn.com:
    ERROR: package traceroute is not installed
```

Looks like we're missing the `traceroute` package on all machines!  Let's use
another function from the `pkg` module to install it:

```
$ sudo salt '*' pkg.install traceroute
0.sminion.learn.com:
    ----------
    traceroute:
        ----------
        new:
            1:2.0.20-0ubuntu0.1
        old:
smaster.learn.com:
    ----------
    traceroute:
        ----------
        new:
            1:2.0.20-0ubuntu0.1
        old:
1.sminion.learn.com:
    ----------
    traceroute:
        ----------
        new:
            3:2.0.22-2.el7
        old:
```

Great!  We now have `traceroute` installed!  Let's see about that
`network.traceroute` function now:

```
$ sudo salt '0*' network.traceroute 8.8.8.8                                                                                                
0.sminion.learn.com:
    |_
      ----------
      count:
          1
      hostname:
          10.0.2.2
      ip:
          10.0.2.2
      ms1:
          0.239
      ms2:
          0.116
      ms3:
          0.081
    |_
      ----------
      count:
          2
      hostname:
          192.168.0.1
      ip:
          192.168.0.1
      ms1:
          5.656
      ms2:
          5.753
      ms3:
          5.729
    |_
      ----------
      count:
          3
      hostname:
          96.120.85.5
      ip:
          96.120.85.5
      ms1:
          15.0
      ms2:
          14.986
      ms3:
          14.91
    |_
      ----------
      count:
          4
      hostname:
          xe-4-0-0-sur01.pooler.ga.savannah.comcast.net
      ip:
          68.85.93.45
      ms1:
          16.596
      ms2:
          16.642
      ms3:
          16.557
    |_
      ----------
      count:
          5
      hostname:
          ae-65-ar05.savannah.ga.savannah.comcast.net
      ip:
          68.86.250.221
      ms1:
          29.953
      ms2:
          28.777
      ms3:
          29.702
    |_
      ----------
      count:
          6
      hostname:
          ae-20-ar02.southside.fl.jacksvil.comcast.net
      ip:
          68.87.165.13
      ms1:
          20.015
      ms2:
          18.564
      ms3:
          18.492
    |_
      ----------
      count:
          7
      hostname:
          be-33489-cr02.miami.fl.ibone.comcast.net
      ip:
          68.86.95.45
      ms1:
          28.93
      ms2:
          24.238
      ms3:
          24.134
    |_
      ----------
      count:
          8
      hostname:
          be-12274-pe01.nota.fl.ibone.comcast.net
      ip:
          68.86.82.154
      ms1:
          24.359
      ms2:
          29.378
      ms3:
          29.288
    |_
      ----------
      count:
          9
      hostname:
          as15169-1-c.nota.fl.ibone.comcast.net
      ip:
          23.30.206.118
      ms1:
          29.988
      ms2:
          29.528
      ms3:
          29.322
    |_
      ----------
      count:
          10
      hostname:
          108.170.249.17
      ip:
          108.170.249.17
      ms1:
          30.019
      ms2:
          40.419
      ms3:
          38.793
    |_
      ----------
      count:
          11
      hostname:
          108.170.228.33
      ip:
          108.170.228.33
      ms1:
          39.365
      ms2:
          39.224
      ms3:
          38.274
    |_
      ----------
      count:
          12
      hostname:
          google-public-dns-a.google.com
      ip:
          8.8.8.8
      ms1:
          38.615
      ms2:
          38.697
      ms3:
          23.702
```

> It's left as an exercise for the reader to confirm all nodes respond
> appropriately.  The output is lengthy, so we've only targeted one minion for
> this part of the workshop.

Excellent!  Let's take a look at one more remote execution use case before we
finish this module, though!

## Compound Function Execution

Let's say you have a node or series of nodes and you need to collect some
network diagnostics information.  You can do this with a series of Salt
commands, or you can do it with a single compound command!  Let's take a look!

```
$ sudo salt '0*' \
  network.ping,\
  file.read,\
  network.traceroute,\
  network.arp,\
  network.routes \
  google.com,/etc/resolv.conf,8.8.8.8,,
0.sminion.learn.com:
    ----------
    file.read:
        # Dynamic resolv.conf(5) file for glibc resolver(3) generated by resolvconf(8)
        #     DO NOT EDIT THIS FILE BY HAND -- YOUR CHANGES WILL BE OVERWRITTEN
        nameserver 10.0.2.2
    network.arp:
        ----------
        08:00:27:e7:6c:98:
            192.168.17.100
        52:54:00:12:35:02:
            10.0.2.2
    network.ping:
        PING google.com (216.58.192.110) 56(84) bytes of data.
        64 bytes from mia07s35-in-f14.1e100.net (216.58.192.110): icmp_seq=1 ttl=63 time=24.1 ms
        64 bytes from mia07s35-in-f14.1e100.net (216.58.192.110): icmp_seq=2 ttl=63 time=24.3 ms
        64 bytes from mia07s35-in-f14.1e100.net (216.58.192.110): icmp_seq=3 ttl=63 time=26.7 ms
        64 bytes from mia07s35-in-f14.1e100.net (216.58.192.110): icmp_seq=4 ttl=63 time=23.9 ms
        
        --- google.com ping statistics ---
        4 packets transmitted, 4 received, 0% packet loss, time 3004ms
        rtt min/avg/max/mdev = 23.913/24.799/26.752/1.137 ms
    network.routes:
        |_
          ----------
          addr_family:
              inet
          destination:
              0.0.0.0
          flags:
              UG
          gateway:
              10.0.2.2
          interface:
              eth0
          netmask:
              0.0.0.0
        |_
          ----------
          addr_family:
              inet
          destination:
              10.0.2.0
          flags:
              U
          gateway:
              0.0.0.0
          interface:
              eth0
          netmask:
              255.255.255.0
        |_
          ----------
          addr_family:
              inet
          destination:
              192.168.17.0
          flags:
              U
          gateway:
              0.0.0.0
          interface:
              eth1
          netmask:
              255.255.255.0
        |_
          ----------
          addr_family:
              inet6
          destination:
              fe80::/64
          flags:
              U
          gateway:
              ::
          interface:
              eth0
          netmask:
        |_
          ----------
          addr_family:
              inet6
          destination:
              fe80::/64
          flags:
              U
          gateway:
              ::
          interface:
              eth1
          netmask:
        |_
          ----------
          addr_family:
              inet6
          destination:
              ::/0
          flags:
              !n
          gateway:
              ::
          interface:
              lo
          netmask:
        |_
          ----------
          addr_family:
              inet6
          destination:
              ::1/128
          flags:
              Un
          gateway:
              ::
          interface:
              lo
          netmask:
        |_
          ----------
          addr_family:
              inet6
          destination:
              fe80::a00:27ff:fe29:2f42/128
          flags:
              Un
          gateway:
              ::
          interface:
              lo
          netmask:
        |_
          ----------
          addr_family:
              inet6
          destination:
              fe80::a00:27ff:fe54:735c/128
          flags:
              Un
          gateway:
              ::
          interface:
              lo
          netmask:
        |_
          ----------
          addr_family:
              inet6
          destination:
              ff00::/8
          flags:
              U
          gateway:
              ::
          interface:
              eth0
          netmask:
        |_
          ----------
          addr_family:
              inet6
          destination:
              ff00::/8
          flags:
              U
          gateway:
              ::
          interface:
              eth1
          netmask:
        |_
          ----------
          addr_family:
              inet6
          destination:
              ::/0
          flags:
              !n
          gateway:
              ::
          interface:
              lo
          netmask:
    network.traceroute:
        |_
          ----------
          count:
              1
          hostname:
              10.0.2.2
          ip:
              10.0.2.2
          ms1:
              0.289
          ms2:
              0.169
          ms3:
              0.137
        |_
          ----------
          count:
              2
          hostname:
              192.168.0.1
          ip:
              192.168.0.1
          ms1:
              6.418
          ms2:
              6.496
          ms3:
              6.604
        |_
          ----------
          count:
              3
          hostname:
              96.120.85.5
          ip:
              96.120.85.5
          ms1:
              18.67
          ms2:
              18.633
          ms3:
              18.686
        |_
          ----------
          count:
              4
          hostname:
              xe-4-0-0-sur01.pooler.ga.savannah.comcast.net
          ip:
              68.85.93.45
          ms1:
              19.619
          ms2:
              21.053
          ms3:
              21.029
        |_
          ----------
          count:
              5
          hostname:
              ae-65-ar05.savannah.ga.savannah.comcast.net
          ip:
              68.86.250.221
          ms1:
              21.78
          ms2:
              21.437
          ms3:
              21.637
        |_
          ----------
          count:
              6
          hostname:
              ae-20-ar02.southside.fl.jacksvil.comcast.net
          ip:
              68.87.165.13
          ms1:
              24.624
          ms2:
              18.306
          ms3:
              45.27
        |_
          ----------
          count:
              7
          hostname:
              be-33489-cr02.miami.fl.ibone.comcast.net
          ip:
              68.86.95.45
          ms1:
              26.045
          ms2:
              23.545
          ms3:
              23.999
        |_
          ----------
          count:
              8
          hostname:
              be-12274-pe01.nota.fl.ibone.comcast.net
          ip:
              68.86.82.154
          ms1:
              23.111
          ms2:
              30.992
          ms3:
              31.164
        |_
          ----------
          count:
              9
          hostname:
              as15169-2-c.nota.fl.ibone.comcast.net
          ip:
              66.208.228.98
          ms1:
              31.579
          ms2:
              31.747
          ms3:
              29.406
        |_
          ----------
          count:
              10
          hostname:
              108.170.249.17
          ip:

          ms1:
              31.064
          ms2:
              31.369
          ms3:
              31.038
        |_
          ----------
          count:
              11
          hostname:
              108.170.228.35
          ip:
              108.170.228.35
          ms1:
              30.067
          ms2:
              31.413
          ms3:
              28.605
        |_
          ----------
          count:
              12
          hostname:
              google-public-dns-a.google.com
          ip:
              8.8.8.8
          ms1:
              29.057
          ms2:
              23.452
          ms3:
              23.873
```

Lots of output, but it's a collection of diagnostics information that you can
get upfront from any node without having to go anywhere.  Seems pretty cool!

# Conclusion

We've run the gamut on remote execution, including some pretty cool remote
compound executions.  We've also done a tiny bit of troubleshooting, and we saw
how much easier Salt can make that.  In the next session, we'll go through a
primer on Jinja2, Salt's default templating engine.  This will help us gear up
for some pretty cool Salt States!

| Home           | Previous                                | Next              |
|----------------|-----------------------------------------|-------------------|
| [Home](../../) | [Directory Structure](../dir_structure) | [Jinja](../jinja) |
