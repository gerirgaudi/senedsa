# OVERVIEW

*Senedsa* is a small utility and library that wraps around the Nagios `send_nsca` binary, which must be available in your system.

# SYNOPSIS

    senedsa [options] svc_output

Options are:

    -V, --version
    -D, --debug                      Enable debug output
    -H, --nsca NSCA_HOSTNAME         NSCA server hostname
    -p, --port NSCA_PORT             NSCA server port
    -t, --timeout TIMEOUT            send_nsca connection timeout
    -d, --delim DELIM                send_nsca field delimited
    -c, --config CONFIG              send_nsca configuration file
    -h, --hostname HOSTNAME          service hostname
    -S, --service SVC_DESCR          service description
    -s, --status STATUS              Status: ok warning critical unknown
        --help                       Show this message
 
Options `-H`, `-h`, `-S` and `-s` are mandatory; `svc_output` need not be quoted: anything passed as an argument is considred part of `svc_output`.
