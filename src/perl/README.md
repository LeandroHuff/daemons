# Daemon



## Run Perl script as daemon

    Reference: [[How can I run a Perl script as a system daemon in linux? - Stack Overflow](https://stackoverflow.com/questions/766397/how-can-i-run-a-perl-script-as-a-system-daemon-in-linux)]([How can I run a Perl script as a system daemon in linux? - Stack Overflow](https://stackoverflow.com/questions/766397/how-can-i-run-a-perl-script-as-a-system-daemon-in-linux))

    Written by: [Brian D. Foy]([User brian d foy - Stack Overflow](https://stackoverflow.com/users/2766176/brian-d-foy)) at Apr 20, 2009 on stackoverflow.



source directory

/etc/rc.d/init.d

/etc/rc.d/rc.local

The easiest way is to use [Proc::Daemon](http://search.cpan.org/dist/Proc-Daemon/lib/Proc/Daemon.pod).

```perl
#!/usr/bin/perl

use strict;
use warnings;
use Proc::Daemon;

Proc::Daemon::Init;

my $continue = 1;
$SIG{TERM} = sub { $continue = 0 };

while ($continue) {
     #do stuff
}
```

Alternately you could do all of the things Proc::Daemon does:

1. Fork a child and exits the parent process.
2. Become a session leader (which detaches the program from the controlling terminal).
3. Fork another child process and exit first child. This prevents the potential of acquiring a controlling terminal.
4. Change the current working directory to `"/"`.
5. Clear the file creation mask.
6. Close all open file descriptors.



## Integrating into the system:

You need a script like the following (replace `XXXXXXXXXXXX` with the Perl script's name, `YYYYYYYYYYYYYYYYYYY` with a description of what it does, and `/path/to` with path to the Perl script) in `/etc/init.d`.

Since you are using CentOS, once you have the script in `/etc/init.d`, you can just use chkconfig to turn it off or on in the various runlevels.

```bash
#!/bin/bash
#
# XXXXXXXXXXXX This starts and stops XXXXXXXXXXXX
#
# chkconfig: 2345 12 88
# description: XXXXXXXXXXXX is YYYYYYYYYYYYYYYYYYY
# processname: XXXXXXXXXXXX
# pidfile: /var/run/XXXXXXXXXXXX.pid
### BEGIN INIT INFO
# Provides: $XXXXXXXXXXXX
### END INIT INFO

# Source function library.
. /etc/init.d/functions

binary="/path/to/XXXXXXXXXXXX"

[ -x $binary ] || exit 0

RETVAL=0

start() {
    echo -n "Starting XXXXXXXXXXXX: "
    daemon $binary
    RETVAL=$?
    PID=$!
    echo
    [ $RETVAL -eq 0 ] && touch /var/lock/subsys/XXXXXXXXXXXX

    echo $PID > /var/run/XXXXXXXXXXXX.pid
}

stop() {
    echo -n "Shutting down XXXXXXXXXXXX: "
    killproc XXXXXXXXXXXX
    RETVAL=$?
    echo
    if [ $RETVAL -eq 0 ]; then
        rm -f /var/lock/subsys/XXXXXXXXXXXX
        rm -f /var/run/XXXXXXXXXXXX.pid
    fi
}

restart() {
    echo -n "Restarting XXXXXXXXXXXX: "
    stop
    sleep 2
    start
}

case "$1" in
    start)
        start
    ;;
    stop)
        stop
    ;;
    status)
        status XXXXXXXXXXXX
    ;;
    restart)
        restart
    ;;
    *)
        echo "Usage: $0 {start|stop|status|restart}"
    ;;
esac

exit 0
```



## Proc::Daemon

Written by [mpapec]([User mpapec - Stack Overflow](https://stackoverflow.com/users/223226/mpapec)) at Sep 30, 2017 in [How can I run a Perl script as a system daemon in linux? - Stack Overflow](https://stackoverflow.com/questions/766397/how-can-i-run-a-perl-script-as-a-system-daemon-in-linux) post.



If you don't have [Proc::Daemon](http://search.cpan.org/dist/Proc-Daemon/Daemon.pm "Proc::Daemon") as suggested by Chas. Owens, here's how you'd do it by hand:

```perl
sub daemonize {
   use POSIX;
   POSIX::setsid or die "setsid: $!";
   my $pid = fork() // die $!; #//
   exit(0) if $pid;

   chdir "/";
   umask 0;
   for (0 .. (POSIX::sysconf (&POSIX::_SC_OPEN_MAX) || 1024))
      { POSIX::close $_ }
   open (STDIN, "</dev/null");
   open (STDOUT, ">/dev/null");
   open (STDERR, ">&STDOUT");
 }
```

I think the easiest way is to use [daemon](http://libslack.org/daemon/).
 It allows you to run any process as a daemon. This means you don't have  to worry about libraries if you, for example, decided to change to python. To use it, just use:

```bash
daemon myscript args
```

This should be available on most distros, but it might not be installed by default.



## Supervisor

Written by [Ajitabh Pandey]([User Ajitabh Pandey - Stack Overflow](https://stackoverflow.com/users/1213682/ajitabh-pandey)) at Jun 8, 2020 in [How can I run a Perl script as a system daemon in linux? - Stack Overflow](https://stackoverflow.com/questions/766397/how-can-i-run-a-perl-script-as-a-system-daemon-in-linux) post.



I used **supervisor** for running a perl script.

As a system administrator, I like to minimise changes and variations among server and like to stick to core services or bare minimum.

**Supervisor** was already installed and available for a python-flask application running on the same box. So, I just added a conf file for the perl script I wanted to run as a dervice.

Now, I can do:

```bash
supervisorctl start/stop/restart my_perl_script_supervisor_service_name
```





External References:

[daemon](https://libslack.org/daemon/) - Turns other processes into daemons.


