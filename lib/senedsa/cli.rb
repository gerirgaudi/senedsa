require 'optparse'
require 'yaml'

module Senedsa

  class CLI

    ID = File.basename($PROGRAM_NAME).to_sym
    CFGFILE = File.join(ENV['HOME'],"/.#{ID}/config")

    attr_reader :options

    def initialize(arguments)
      @arguments = arguments
      @cli_options = { :senedsa_config => CFGFILE, :debug => false }
      @options = {}
    end

    def run
      begin
        parsed_options?
        config_options?
        arguments_valid?
        options_valid?
      rescue ArgumentError, OptionParser::MissingArgument, StandardError => e
        output_message e.message, 1
      end
      process_options
      process_arguments
      process_command
    end

    protected
      def parsed_options?
        begin
          opts = OptionParser.new

          opts.banner = "Usage: #{ID} [options] svc_output"
          opts.separator ""

          opts.separator "Senedsa options"
          opts.on('-C', '--config CONFIG',               String,                 "senedsa configuration file")                         { |config|    @cli_options[:senedsa_config] = config }
          opts.separator ""

          opts.separator "NSCA options:"
          opts.on('-H', '--nsca_hostname HOSTNAME',      String,                 "NSCA server hostname")                               { |hostname|  @cli_options[:nsca_hostname] = hostname }
          opts.on('-p', '--nsca_port PORT',              Integer,                "NSCA server port")                                   { |port|      @cli_options[:nsca_port] = port }
          opts.separator ""

          opts.separator "Send_Nsca options:"
          opts.on('-t', '--send_nsca-timeout TIMEOUT',   Integer,                "send_nsca connection timeout")                       { |timeout|   @cli_options[:send_nsca_timeout] = timeout }
          opts.on('-d', '--send_nsca-delim DELIM',       String,                 "send_nsca field delimited")                          { |delim|     @cli_options[:send_nsca_delim] = delim }
          opts.on('-c', '--send_nsca-config CONFIG',     String,                 "send_nsca configuration file")                       { |config|    @cli_options[:send_nsca_config] = config }
          opts.on('-b', '--send_nsca-binary BINARY',     String,                 "send_nsca binary path")                              { |binary|    @cli_options[:send_nsca_binary] = binary }
          opts.separator ""

          opts.separator "Service options:"
          opts.on('-h', '--hostname HOSTNAME',           String,                 "service hostname")                                   { |hostname|  @cli_options[:svc_hostname] = hostname }
          opts.on('-S', '--service SVC_DESCR',           String,                 "service description")                                { |svc_descr| @cli_options[:svc_descr] = svc_descr }
          opts.on('-s', '--status STATUS',               SendNsca::STATUS.keys,  "service status: #{SendNsca::STATUS.keys.join ', '}") { |status|    @cli_options[:svc_status] = status }
          opts.separator ""

          opts.separator "General options:"
          opts.on('-a', '--about',                                               "Display #{ID} information")                          { output_message ABOUT, 0 }
          opts.on('-V', '--version',                                             "Display #{ID} version")                              { output_message VERSION, 0 }
          opts.on_tail('--help',                                                 "Show this message")                                  { output_message opts; exit 0 }

          output_message opts, 0 if @arguments.size == 0

          opts.parse!(@arguments)
        rescue => e
          output_message e.message, 1
        end
      end

      def config_options?
        cfg_options = SendNsca.configure(@cli_options[:senedsa_config])
        raise
        cfg_options.delete(:senedsa_config) unless cfg_options[:senedsa_config].nil?
        @options.merge!(cfg_options)
      end

      def options_valid?
        true
      end

      def arguments_valid?
        raise ArgumentError, "must specify svc_output" unless @arguments.size > 0
        true
      end

      def process_options
        @options.merge!(@cli_options)
        raise OptionParser::MissingArgument, "NSCA hostname (-H) must be specified" if @options[:nsca_hostname].nil?
        raise OptionParser::MissingArgument, "service description (-S) must be specified" if @options[:svc_descr].nil?
        raise OptionParser::MissingArgument, "service hostname (-h) must be specified" if @options[:svc_hostname].nil?
        raise OptionParser::MissingArgument, "service status (-s) must be specified" if @options[:svc_status].nil?
      end

      def process_arguments
        @arguments = @arguments.join(' ')
      end

      def output_message(message, exitstatus=nil)
        m = (! exitstatus.nil? and exitstatus > 0) ? "%s: error: %s" % [ID, message] : message
        $stderr.write "#{m}\n"
        exit exitstatus unless exitstatus.nil?
      end

      def process_command
        begin
          @send_nsca = SendNsca.new @options[:svc_hostname], @options[:svc_descr], @options
          @send_nsca.send(@options[:svc_status],@arguments)
        rescue => e
          output_message e.message, 1
        end
        exit 0
      end
  end

end