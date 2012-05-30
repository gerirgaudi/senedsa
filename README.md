# OVERVIEW

*Senedsa* is a small utility and library that wraps around the Nagios `send_nsca` utility, which must be available in your system. *Senedsa* assumes by default that `send_nsca` is available in your PATH and that `send_nsca`'s configuration file is in its default location. Both of these items can be overriden via options in the configuration file or in the command line.

*Senedsa* is available as a Rubygem: [gem install senedsa](https://rubygems.org/gems/senedsa "Senedsa")

# SYNOPSIS

    senedsa [options] svc_output

Options are as follows:

	Senedsa options
		-c, --config CONFIG              senedsa configuration file

	NSCA options:
    	-H, --nsca_hostname HOSTNAME     NSCA server hostname                              [REQUIRED]
    	-P, --nsca_port PORT             NSCA server port

	Send_Nsca options:
	    -T, --send_nsca_timeout TIMEOUT  send_nsca connection timeout
    	-D, --send_nsca_delim DELIM      send_nsca field delimited
    	-C, --send_nsca_config CONFIG    send_nsca configuration file
    	-B, --send_nsca_binary BINARY    send_nsca binary path

	Service options:
    	-h, --svc_hostname HOSTNAME      service hostname                                  [REQUIRED]
    	-S, --svc_descr DESCR            service description                               [REQUIRED]
    	-s, --svc_status STATUS          service status: ok, warning, critical, unknown    [REQUIRED]

	General options:
		-d, --debug                      Enable debug mode
    	-a, --about                      Display senedsa information
    	-V, --version                    Display senedsa version
            --help                       Show this message
 
With no options or arguments, `senedsa` displays help (as shown above). 

Options `--nsca_hostname`, `--svc_hostname`, `--svc_descr` and `--svc_status` are mandatory (unless specified in the configuration file).

 Finally, `svc_output` need not be quoted: anything passed as an argument is considered part of `svc_output`.

# CONFIGURATION

The priority of options is: command line options `>` configuration file options `>` default options

A YAML-based configuration (default location is `~/.senedsa/config`) can be used to set defaults for any option (except `senedsa_config`), which can then be overriden in the command line. This is useful, for instance, if the `send_nsca` binary is not in the PATH, its configuration file is not in the default location, or so that the NSCA server hostname need not be specified on the command line in every invocation. Use long option names to set the corresponding values:

    ---
    :send_nsca_binary: /usr/local/bin/send_nsca
    :send_nsca_config: /local/etc/nagios/send_nsca.cfg
    :nsca_hostname: nsca.example.com

Thus, we can now run `senedsa` like so:

    senedsa -h myhost.example.com -S mypassiveservice -s ok Everthing ok with myservice
    
In cases where `senedsa` is being used by some external script for a specific host and service (assuming `send_nsca` is in the PATH and the configuration is its standard location), the configuration file `/etc/senedsa/script_service` could be:

	---
	:nsca_hostname: nsca.example.com
	:send_nsca_hostname: my.hostname.example.com
	:send_nsca_descr: script_service
	
Then, the script would invoke `senedsa` as follows:

	senedsa -c /etc/senedsa/script_service -s ok service is doing great

# LIBRARY

To use *Senedsa* as a library, simply:

    require 'senedsa'
    
    svc_hostname = "foo.example.com"
    svc_descr = "sample service description"
    
    begin
      s = SendNsca.new svc_hostname, svc_descr, :nsca_hostname => "nsca.example.com"
      s.send :ok, "Everything ok with my service"
    rescue => e
      # rescue logic
    end
    
## CONSTRUCTORS

*Senedsa* accepts four different constructors, aimed at fitting different situations.

* `(SendNsca) initialize(config_file)`
* `(SendNsca) initialize(config_hash)`
* `(SendNsca) initialize(svc_hostname,svc_descr)`
* `(SendNsca) initialize(svc_hostname,svc_descr,config_hash)`

Where:

* `config_file` is a path to a valid configuration file
* `config_hash` is a hash keyed by long option names with their corresponding values
* `svc_hostname` is the hostname of the service hostname
* `svc_descr` is the service description of the service

An instance does not need all options defined until the `send` method is invoked.

## DEFAULTS

`Senedsa` has sensible defaults for the following options, mostly following `send_nsca`'s documented defaults:

* `nsca_port = 5667`
* `send_nsca_timeout = 10`
* `send_nsca_delim = '\t'`
* `send_nsca_binary = 'send_nsca'`

It is therefore not necessary to set these if your environment doesn't need them changed.

## SETTERS, GETTERS and CONFIGURATION FILES

All options are settable (and gettable) through attribute methods. For instance:

	sn = SendNsca.new "foo.example.com", "web_service"
	sn.nsca_hostname = "nsca.example.com"
	sn.send :ok, "Service ok"
	
Another example:

	sn = SendNsca.new "foo.example.com", "web_service", :nsca_hostname => "nsca.example.com"
	sn.nsca_port = 55667
	sn.send :ok, Service ok"

If you wish to use a configuration file to set some defaults:

	---
	:nsca_hostname: nsca.example.com
	:send_nsca_hostname: my.hostname.example.com

Then:

	config_file = '/etc/senedsa.cfg'
    s = SendNsca.new config_file
    s.svc_descr = "web_service"
    s = s.send :ok, "Everything ok with web_service"

Alternatively you can set defaults in the `SendNsca` class before creating any instances:

    SendNsca.defaults[:nsca_hostname] = "nsca.example.com"
    s = SendNsca.new svc_hostname, svc_descr
    s.send :ok, "Everything ok with my service"

After a SendNsca instance is created, changing the defaults has no effect on said instance. You must then make changes to the instance itself.