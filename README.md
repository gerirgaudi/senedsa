# OVERVIEW

*Senedsa* is a small utility and library that wraps around the Nagios `send_nsca` utility, which must be available in your system. *Senedsa* assumes by default that `send_nsca` is available in your PATH and that `send_nsca`'s configuration file is in its default location. Both of these items can be overriden via options in the configuration file or in the command line.

# SYNOPSIS

    senedsa [options] svc_output

Options are as follows:

	Senedsa options
		-C, --config CONFIG              senedsa configuration file

	NSCA options:
    	-H, --nsca_hostname HOSTNAME     NSCA server hostname                              [REQUIRED]
    	-p, --nsca_port PORT             NSCA server port

	Send_Nsca options:
	    -t, --send_nsca_timeout TIMEOUT  send_nsca connection timeout
    	-d, --send_nsca_delim DELIM      send_nsca field delimited
    	-c, --send_nsca_config CONFIG    send_nsca configuration file
    	-b, --send_nsca_binary BINARY    send_nsca binary path

	Service (svc_) options:
    	-h, --svc_hostname HOSTNAME      service hostname                                  [REQUIRED]
    	-S, --svc_descr DESCR            service description                               [REQUIRED]
    	-s, --svc_status STATUS          service status: ok, warning, critical, unknown    [REQUIRED]

	General options:
    	-a, --about                      Display senedsa information
    	-V, --version                    Display senedsa version
            --help                       Show this message
 
With no options or arguments, `senedsa` displays help (as shown above). Options `-H`, `-h`, `-S` and `-s` are mandatory (unless specified in the configuration file); `svc_output` need not be quoted: anything passed as an argument is considered part of `svc_output`.

# CONFIGURATION

A YAML-based configuration (default location is `~/.senedsa/config`) can be used to set defaults for any option (except `senedsa_config`), which can then be overriden in the command line. This is useful, for instance, if the `send_nsca` binary is not in your PATH, its configuration file is not in the default location, or so that the NSCA server hostname need not be specified on the command line in every invocation. Use long option names to set the corresponding values:

    ---
    :send_nsca_binary: /usr/local/bin/send_nsca
    :send_nsca_config: /local/etc/nagios/send_nsca.cfg
    :nsca_hostname: nsca.example.com

Thus, we can now run `senedsa` like so:

    senedsa -h myhost.example.com -S mypassiveservice -s ok Everthing ok with myservice
    
In extreme cases, where `senedsa is being used by some external script for a specific host and service (assume `send_nsca` is in the PATH and the configuration is its standard location), the configuration file `/etc/senedsa.foo` could be:

	---
	:nsca_hostname: nsca.example.com
	:send_nsca_hostname: my.hostname.example.com
	:send_nsca_descr: script_service
	
Then, the script would invoke `senedsa` as follows:

	senedsa -C /etc/senedsa.foo -s ok service is doing great

# LIBRARY

Using *Senedsa* as a library:

    require 'senedsa/send_nsca'
    
    begin
      @send_nsca = SendNsca.new hostname, svc_descr, :nsca_hostname => nsca.example.com
      @send_nsca.send(:ok,"Everything ok with my service")
    rescue => e
      # rescue logic
    end
    
If you wish to use a configuration file to set defaults:

	---
	:nsca_hostname: nsca.example.com
	:send_nsca_hostname: my.hostname.example.com

Then:

	begin
	  cfg_options = SendNsca.configure(cfg_file)
      @send_nsca = SendNsca.new hostname, svc_descr, cfg_options
      @send_nsca.send(:ok,"Everything ok with my service")
    rescue => e
      # rescue logic
    end

Alternatively, you can set defaults in the `SendNsca` class before creating any instances:

    SendNsca.defaults[:nsca_hostname] = "nsca.example.com"
    @send_nsca = SendNsca.new svc_hostname, svc_descr
    @send_nsca.send :ok, "Everything ok with my service"

After a SendNsca instance is created, changing the defaults has no effect on said instance. You must then make changes to the instance itself:

	@send_nsca = SendNsca.new hostname, svc_descr
	@send_nsca.hostname = "nsca.example.com"
    
If you have multiple services in the same host:

	SendNsca.nsca.hostname = "nsca.example.com"                      # default NSCA server
	SendNsca.send_nsca.binary = "/usr/local/bin/send_nsca"           # default binary location
	SendNsca.send_nsca.config = "/local/etc/nagios/send_nsca.cfg"    # default config location
	
	svc1 = SendNsca.new hostname, "service 1"
	svc2 = SendNsca.new hostname, "service 2"
	
	svc1.send :warning, "Service is flaking out"
	svc2.send :critical, "Service is dead"
	