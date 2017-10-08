| Home           | Previous            | Next                |
|----------------|---------------------|---------------------|
| [Home](../../) | [Grains](../grains) | [Pillar](../pillar) |

# Yaml

YAML stands for Yet Another Marup Language.  It is exactly what its name
indicates: a markup language used to define data.  YAML, at its most fundamental
level, allows us to create key-value pairs.  We have a particular value, and we
need to store it in something so that we can more easily reference that value
later.

Salt renders the YAML data into Python objects during execution.  To help you in
your Salt journey, I've compiled a list of three simple rules when writing YAML.

## Rule 0

First and foremost, you should understand storing "scalars."  A scalar in YAML
is essentially any value that is not a dictionary or a list (covered later).
Any simple, non-nested, non-collection key-value pair is a scalar.  To put it
another way, if it's one and only one thing, it's probably a scalar.  Let's look
at some YAML for clarification:

```yaml
first_name: Tyler
last_name: Christiansen
age: 30

# Python equivalent
## first_name = 'Tyler'
## last_name = 'Christiansen'
## age = 30
```

## Rule 1

In YAML, the data we are storing is hierarchical.  To help us organize the data
as humans, we use spaces and every level is separated by two spaces.  You can
see this in the following example:

```yaml
country:
  usa:
    states:
      - MA
      - OR
      - CA
```

> You don't have to use two space; you can use four.  However many you use,
> though, be consistent.  Spacing with YAML tends to a common mistake.  It's
> not just for the convenience of humans--certain data structures rely on
> spacing for semantic meaning.

## Rule 2

When we need to store more complex data structures, we use dictionaries.  The
syntax is simple: the key and value are separated by a colon (`:`).  You can
nest the dictionaries to build complex and real-world data structures. In such
cases the value of one key can be another key-value pair and so on.

```yaml
name:
  first: Tyler
  last: Christiansen

# Python dictionary equivalent:
## name = {
##     'first': 'Tyler',
##     'last': 'Christiansen'
## }
```

> Technically, where YAML is concerned, this particular nested data structure
> is actually called a "mapping."  We will call them dictionaries, though, in
> an effort to make the concept easy to understand for those familiar with
> Python.

Here's an example of a nested data structure using a dictionary:

```yaml
country:
  usa:
    states:
      - MA
      - OR
      - CA

# Python equivalent
## country = {
##     'usa': {
##         'states': [
##             'MA',
##             'OR',
##             'CA'
##         ]
##     }
## }
```

## Rule 3

The third thing to know is that lists are created by using `-` under a key.
Lists can also be nested, so an item in a list could be a list as well.

```yaml
grocery_list:
  - milk
  - bread
  - apples
  - oranges

# Python equivalent
## grocery_list = ['milk', 'bread', 'apples', 'oranges']
```

And a nested list example:

```yaml
users_and_passwords:
  - [bob, password123]
  - [joe, octobertwentysix]
  
# Python equivalent
## users_and_passwords = [
##     ['bob', 'password123'],
##     ['joe', 'octobertwentysix']
## ]
```

## Conclusion

YAML is generally simple if you follow these three basic rules.  In the real
world, data structures can quickly become complicated.  We'll look at access the
values of a YAML data structure when we start looking at Jinja.  Before that,
though, we'll want to look at pillars next.

| Home           | Previous            | Next                |
|----------------|---------------------|---------------------|
| [Home](../../) | [Grains](../grains) | [Pillar](../pillar) |
