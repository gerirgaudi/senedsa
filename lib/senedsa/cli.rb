require 'optparse'
require 'yaml'

module Senedsa

  class CLI

    ID = File.basename($PROGRAM_NAME).to_sym
    CFGFILE = File.join(ENV['HOME'],"/.#{ID}/config")

    attr_reader :options

    def initialize(arguments)
      @arguments = arguments
      @options = { :debug => false }
    end

    def run
      begin
        configuration_file?(CFGFILE)
        parsed_options?
        arguments_valid?
        options_valid?
      rescue ArgumentError, OptionParser::MissingArgument => e
        output_error e.message, 1
      end
      process_options
      process_arguments
      process_command
    end

    protected

      def configuration_file?(cfg_file)
        begin
          if File.readable? cfg_file
            cfg_options = YAML.load File.open(cfg_file)
            @options.merge!(cfg_options) unless cfg_options.nil?
          end
        rescue Psych::SyntaxError => e
          output_error "syntax error in configuration file #{cfg_file}: #{e.message}", 1
        end
        true
      end

      def parsed_options?
        begin
          opts = OptionParser.new

          opts.banner = "Usage: #{ID} [options] svc_output"
          opts.separator ""
          opts.separator "Specific options:"
          opts.version = VERSION

          opts.on('-V', '--version')                                                                                   { puts VERSION ; exit 0 }
          opts.on('-D', '--debug',                                      "Enable debug output")                         { @options.debug = true }
          opts.on('-H', '--nsca NSCA_HOSTNAME', String,                 "NSCA server hostname")                        { |nsca_hostname| @options[:nsca_hostname] = nsca_hostname }
          opts.on('-p', '--port NSCA_PORT',     Integer,                "NSCA server port")                            { |nsca_port| @options[:nsca_port] = nsca_port}
          opts.on('-t', '--timeout TIMEOUT',    Integer,                "send_nsca connection timeout")                { |timeout| @options[:timeout] = timeout }
          opts.on('-d', '--delim DELIM',        String,                 "send_nsca field delimited")                   { |delim| @options[:delim] = delim }
          opts.on('-c', '--config CONFIG',      String,                 "send_nsca configuration file")                { |config| @options[:config] = config }
          opts.on('-h', '--hostname HOSTNAME',  String,                 "service hostname")                            { |hostname| @options[:hostname] = hostname }
          opts.on('-S', '--service SVC_DESCR',  String,                 "service description")                         { |svc_descr| @options[:svc_descr] = svc_descr }
          opts.on('-s', '--status STATUS',      SendNsca::STATUS.keys,  "Status: #{SendNsca::STATUS.keys.join ' '}")   { |status| @options[:rt] = status }

          opts.on_tail('--help', "Show this message")                                                                  { puts opts; exit 0 }

          if @arguments.size == 0
            puts opts
            exit 0
          end

          opts.parse!(@arguments)
        rescue => e
          output_error e.message, 1
        end
        process_options
      end

      def options_valid?
        raise OptionParser::MissingArgument, "NSCA hostname (-H) must be specified" if @options[:nsca_hostname].nil?
        raise OptionParser::MissingArgument, "service description (-S) must be specified" if @options[:svc_descr].nil?
        raise OptionParser::MissingArgument, "service hostname (-h) must be specified" if @options[:hostname].nil?
        true
      end

      def arguments_valid?
        raise ArgumentError, "must specify svc_output" unless @arguments.size > 0
        true
      end

      def process_options
        true
      end

      def process_arguments
        @arguments = @arguments.join(' ')
      end

      def output_error(message,exitstatus = nil)
        $stderr.write "#{ID}: error: #{message}\n"
        exit exitstatus[0] unless exitstatus.nil?
      end

      def process_command
        begin
          @send_nsca = SendNsca.new @options[:hostname], @options[:svc_descr], :nsca_hostname => @options[:nsca_hostname]
          @send_nsca.send(@options[:rt],@arguments)
        rescue => e
          output_error e.message, 1
        end
        exit 0
      end
  end

end