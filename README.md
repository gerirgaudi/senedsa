# OVERVIEW

*Senedsa* is a small utility and library that wraps around the Nagios `send_nsca` utility, which must be available in your system. *Senedsa* assumes `send_nsca` is available in your PATH and that `send_nsca`'s configuration file is available in its default location. Both of these items can be overriden via options in the configuration file or in the command line.

# SYNOPSIS

    senedsa [options] svc_output

Options are:

    -V, --version
    -H, --nsca NSCA_HOSTNAME         NSCA server hostname
    -p, --port NSCA_PORT             NSCA server port
    -t, --timeout TIMEOUT            send_nsca connection timeout
    -d, --delim DELIM                send_nsca field delimited
    -b, --binary BINARY				 send_nsca binary path
    -c, --config CONFIG              send_nsca configuration file
    -h, --hostname HOSTNAME          service hostname
    -S, --service SVC_DESCR          service description
    -s, --status STATUS              Status: ok warning critical unknown
        --help                       Show this message
 
With no options or arguments, `senedsa` displays help (as shown above). Options `-H`, `-h`, `-S` and `-s` are mandatory (unless specified in the configuration file); `svc_output` need not be quoted: anything passed as an argument is considered part of `svc_output`.

# CONFIGURATION

A YAML-based configuration can be created at `~/.senedsa/config` to set defaults for any option, which can then be overriden in the command line. This is useful, for instance, if the `send_nsca` binary is not in your PATH, its configuration file is not in the default location, or so that the NSCA server hostname need not be specified on the command line in every incovation:

    ---
    :binary: /usr/local/bin/send_nsca
    :config: /local/etc/nagios/send_nsca.cfg
    :nsca_hostname: nsca.example.com

Thus, we can now run `senedsa` like so:

    senedsa -h myhost.example.com -S mypassiveservice -s ok Everthing ok with myservice

Any option can be specified in the configuration file.

# LIBRARY

Using *Senedsa* as a library:

    require 'senedsa/send_nsca'
    
    begin
      @send_nsca = SendNsca.new hostname, svc_descr, :nsca_hostname => nsca.example.com
      @send_nsca.send(:ok,"Everything ok with my service")
    rescue => e
      # rescue logic
    end
    
Note that the configuration file does not (yet) apply when using Senedsa as a library. If you wish to set defaults for any of the fields, you can do the following:

    SendNsca.nsca.hostname = "nsca.example.com"
    @send_nsca = SendNsca.new hostname, svc_descr
    @send_nsca.send(:ok,"Everything ok with my service")

After a SendNsca instance is created, changing the defaults has no effect on said instance. You must then make changes to the instance itself:

	@send_nsca = SendNsca.new hostname, svc_descr
	@send_nsca.nsca.hostname = "nsca.example.com"
    
If you have multiple services in the same host:

	SendNsca.nsca.hostname = "nsca.example.com"                      # default NSCA server
	SendNsca.send_nsca.binary = "/usr/local/bin/send_nsca"           # default binary location
	SendNsca.send_nsca.config = "/local/etc/nagios/send_nsca.cfg"    # default config location
	
	svc1 = SendNsca.new hostname, "service 1"
	svc2 = SendNsca.new hostname, "service 2"
	
	svc1.send(:warning, "Service is flaking out")
	svc2.send(:criticalm "Service is dead")
	
# STATUS

The SendNsca interface for `initialize` and `send` is stable. The interface to set default options is not, especially as the configuration file capability is moved into the library itself.
