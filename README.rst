SSH-EXEC
========

:Author: Christopher A. Snapp <snappca@gmail.com>
:Version: 12.12
:Copyright: GPLv3

**ssh-exec** executes commands on a list of remote hosts; optionally as root

.. contents::

Synopsis
--------

**ssh-exec** [**-hioOpPrR**] [**--help**] [**-c** *count*] [**-f** *commands-file*] [**-F** *hosts-file*] [**-u** *username*] *host1 host2 host3...*


Description
-----------
ssh-exec provides a secure method for automating the execution of scripts
on multiple remote hosts.  The automation can be set to either increment
through the list of hosts or run against multiple hosts concurrently.

Other methods exist for running scripts against remote hosts but they tend
to require the installation of a daemon on each remote host (e.g. Func).

By comparison, ssh-exec is a simple wrapper for standard SSH transactions.
This means there are NO server side modifications required and all
automated scripts are tracked the same as if you had logged into each
system and performed the commands manually.  This is in contrast to Func's
approach where all commands are executed by a privileged 'func' user and
proper accountability is lost.

Password Handling
~~~~~~~~~~~~~~~~~
In order for ssh-exec to accomplish password handling across numerous hosts
it expects a simple convention to be followed.  This convention allows for
you to keep different passwords on all of your systems while keeping it
easy to manage.

Password Patterns
~~~~~~~~~~~~~~~~~
If the password you have provided contains the letter 'X' (upper or lower
case) immediately followed by a digit then the 'X + digit' combination
shall be substituted with the letter from the hostname identified by the
digit with the case dictated by the case of the letter 'X'.

.. Note::
    * The letter 'X' is perfectly valid as part of a password; it is ONLY
      when the letter 'X' is IMMEDIATELY followed by a digit that the
      substitution takes place.
    * If your password pattern does not contain any 'X + digit' combinations
      then the password will be unaltered as it is submitted to each host.
    * Only the first digit immediately following the letter 'X' is used during
      character substitution.
    * Character substitution occurs as if you were typing the password in
      directly; that is, if the character retrieved from the hostname
      is either a digit, period, or hyphen AND the case indicated by the
      letter 'X' is uppercase, then the result would be the same as if you
      pressed the 'shift' key while typing the digit, period, or hyphen.

**Examples** (where hostname is 'example.com')

.. code-block::

    pattern: X1x2X3x4X5    result: ExAmP

    pattern: fooX3barX1x4  result: fooAbarEm

    pattern: foobarX1x8    result: foobarE>

    pattern: fooXbarX1x12  result: fooXbarEe2

Timeouts
~~~~~~~~
ssh-exec expects that each command within your script results in a prompt.

A prompt is recognized by the regular expression:

.. code-block::

    /(>|%|#|\$) $/

Should a command not return to a prompt within the timeout period (default
is 20 seconds) then ssh-exec will abort execution of your script against
that host.

Tokens
~~~~~~
ssh-exec tokens are identified by the hash (#) mark and are used for two
purposes:

    1. Control underlying expect functionality

    2. Identify a custom recipe

Recipes
~~~~~~~
Recipes are custom add-ons created by you to be used as shortcuts to execute
common tasks.

In order to create a recipe you first need to create the ~/.ssh-exec
directory.
Each filename within this directory is an identifier for a custom token.
You can put any script that you would normally type into ssh-exec's stdin
into a file and then use the token syntax to reference it.

You can pass arguments to your recipes by using $arg# syntax (e.g. $arg1,
$arg2..etc.) when creating your recipe.  Then when you call your recipe via
a token, your args are space delimited within your token tag.

**Example:**

.. code-block::

    # create the recipe #
    ~/.ssh-exec/changelog contains:
    echo -e "$(date +%Y%m%d) $arg1 $arg2" >> /var/adm/changelog*

    # call the recipe #
    ssh-exec example.com <<'EOF'
    #changelog cas "here is arg2's content"#
    EOF

.. Tip::
    recipes can contain other recipes


Options
-------
    **-c** *count*
      the number of jobs to run concurrently; default is ``10`` if no value is
      provided

        .. Note::
            While the script will execute in separate threads up to the
            concurrency level you provide, the results will always be
            returned in the order that you originally specified.

    **-d**
      enable debug mode (print ALL output)

    **-f** *file*
      the file containing commands to be executed

    **-F** *file*
      the file containing hosts to be executed against

    **-h**
      display this help and exit

    **--help**
      display formatted help and exit

    **-i**
      convenience mechanism equivalent to passing '``#interact#``'

        .. Note::
            No other commands will be read if this argument is used.
            Additionally, this argument is mutually exclusive with
            -c, -o, and -O.

    **-o**
      log each system's output to a timestamped file(i.e. ``~/ssh-exec.20120131_105929``)

    **-O**
      log each system's output to a separate file within a datestamped directory
      the naming format will be (i.e. ``~/ssh-exec.20120131``)

    **-q**
      enable quiet mode (only prints job status to screen)

    **-Q**
      enable silent mode (no printing of any output to screen)

    **-r**
      run commands as root via '``su -``' authentication

    **-R**
      run commands as root via '``sudo su - root``' authentication

        .. Note::
            You will be prompted for the password necessary for sudo to execute.
            This password will only be used if the server prompts for it.
            This means that if you have NOPASSWD:ALL set in the sudoers file
            you could simply hit 'Enter' when prompted and no password will
            be required.

    **-u** *username*
        the username used during initial ssh login; default is your current
        username

    **-v**
      display version information and exit

    **-V**
      enable verbose output

    **-p**
      prompt for user password; allows for a fallback if key login fails

    **-P**
      prompt for user password; disables spawning of ssh-agent

Built-in Tokens
---------------
    ``#passwd <username>#``
      Inserts the commands for changing the provided username's password.
      If no username is provided, user will default to root.

    ``#expect <pattern>#``
      Explicitly look for a phrase using expect format prior to executing
      the next command.

    ``#interact#``
      This will pause automatic execution and allow you to execute commands
      directly into the console.  When you are finished and would like to
      give control back to automatic execution, simply type #x

        .. Tip::
            * You can pass **one** argument to the interact token, which is useful
              for executing a command just prior to entering interactive mode.

            * You can use ``#interact#`` multiple times within the same script to
              interleave automated script execution with interactive sessions.

    ``#password:<repeat>:<prompt contents>#``
      This token allows you to securely collect password patterns prior to
      runtime and then have them injected the number of times specified
      via the second argument.
      A custom prompt can also be provided as the third argument.

    ``#timeout <duration>#``
      Override the default 20 second timeout that expect uses waiting
      for a prompt.
      Timeout is in seconds; while a value of -1 represents unlimited
      If no value is provided timeout will be reset to 20 seconds

    ``#user#``
      inserts the username that ssh-exec is logging in as

Examples
--------
.. Note::
    Examples are based on execution within a BASH shell

**Executing simple one liners**

For very simple scripts you can just use a here-string (i.e. ``<<<``)

.. code-block::

    ssh-exec example.com <<<'ls -la ~/.ssh'

**Executing multi-line scripts**

For more complex scripts you can simply hit enter and type your script
contents directly into ``STDIN`` followed by ``ctrl-d`` to finish.

If you would like to store your script within your shell's history you
would probably rather use a here-doc (i.e. ``<<'EOF'``).

.. code-block::

    ssh-exec example.com <<'EOF'
    uptime
    cat $HOME/.ssh/authorized_keys
    tail -15 $HOME/.bash_history
    EOF

.. Tip::
    Use quotes around the ``EOF`` delimeter to ensure the shell does not expand any
    variables within your script.

**Execute a command concurrently against multiple systems as root**

.. code-block::

    ssh-exec -r -c example-{1..50}.com <<<'cat /etc/shadow'

**Login to a list of servers for manual maintenance**

.. code-block::

    ssh-exec -r example-{1..50}.com <<<'#interact#'

**Edit the same file interactively on each system as root**

.. code-block::

    ssh-exec -r example-{1..50}.com <<<'#interact "vi /etc/logcheck/logcheck.ignore"#'

**Execute a custom recipe for running a tripwire update; overriding the default concurrency of 10**

.. code-block::

    ssh-exec -r -c 25 example-{1..50}.com <<<'#tripwire#'

**Change root password followed by tripwire update**

.. code-block::

    ssh-exec -r -c example-{1..50}.com <<'EOF'
    #passwd#
    #tripwire#
    EOF

**Change testuser's password followed by tripwire update**

.. code-block::

    ssh-exec -r -c example-{1..50}.com <<'EOF'
    #passwd testuser#
    #tripwire#
    EOF

**Override timeout period for long running script**

.. code-block::

    ssh-exec example.com <<'EOF'
    uptime
    #timeout 25#
    sleep 20; echo 'sleep complete'
    EOF

Installation
------------
    1. ensure the expect and ssh-exec scripts are in your ``$PATH``
    2. copy the examples found in 'recipes' to ``$HOME/.ssh-exec`` (optional)
    3. ``ssh-exec --help`` to learn more

WARNING
-------
    **ssh-exec is only responsible for establishing the connection and**
    **executing the commands you supplied it in the same way as if**
    **you had manually ssh'd in and were typing the commands by hand.**

    **There is NO special handling of the commands on the server side to**
    **account for OS, distribution, or any other required environment**
    **setup.**

    **It is YOUR responsibility to ensure the commands will function**
    **on each of the hosts provided.**

Copyright
---------
Copyright (C) 2012, Christopher A. Snapp <snappca@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
