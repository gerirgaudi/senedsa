require 'open3'
require 'psych'
require 'socket'

module Senedsa

  class SendNsca

    STATUS = {
        :ok       => 0,
        :warning  => 1,
        :critical => 2,
        :unknown  => 3
    }

    @defaults = {
        :send_nsca_binary => 'send_nsca',
        :send_nsca_config => nil,
        :send_nsca_delim => '\t',
        :send_nsca_timeout => 10,
        :nsca_hostname => nil,
        :nsca_port => 5667,
        :svc_hostname => nil,
        :svc_descr => nil,
        :svc_status => nil
    }

    class << self

      attr_accessor :defaults end

      def self.configure(cfg_file)
        cfg_options = {}
        unless cfg_file.nil?
          raise ConfigurationError, "unable to read configuration file #{cfg_file}" unless File.readable? cfg_file
          begin
            cfg_options = Psych.load File.open(cfg_file)
            raise ConfigurationError, "senedsa_config not allowed in configuration file (#{cfg_file})" unless cfg_options[:senedsa_config].nil?
          rescue Psych::SyntaxError => e
            raise ConfigurationError, "syntax error in configuration file #{cfg_file}: #{e.message}"
          rescue Errno::ENOENT, Errno::EACCES => e
           raise ConfigurationError, e.message
          end
        end
        cfg_options
      end

    class Error < StandardError; end
    class SendNscaError < Error; end
    class ConfigurationError < SendNscaError; end
    class InitializationError < SendNscaError; end

    def initialize(*args)

      @options = {}

      case args.size

        when 1
          if args[0].is_a? String
            cfg_file = args[0].nil? ? nil : args[0]
            cfg_options = cfg_file.nil? ? {} : SendNsca.configure(cfg_file)
            hsh_options = {}
          elsif args[0].is_a? Hash
            cfg_file = args[0][:senedsa_config].nil? ? nil : args[0][:senedsa_config]
            cfg_options = cfg_file.nil? ? {} : SendNsca.configure(cfg_file)
            hsh_options = args[0]
          else
            raise InitializationError, "invalid argument types"
          end

        when 2
          raise InitializationError, "invalid argument types" unless args[0].is_a? String and args[1].is_a? String
          cfg_options = SendNsca.configure(@options[:senedsa_config])
          hsh_options = { :svc_hostname => args[0], :svc_descr => args[1] }

        when 3
          raise InitializationError, "invalid argument types" unless args[0].is_a? String and args[1].is_a? String and args[2].is_a? Hash
          cfg_options = SendNsca.configure(args[0][:senedsa_config])
          hsh_options = args[2].merge({ :svc_hostname => args[0], :svc_descr => args[1] })

        else
          raise ArgumentError, "wrong number of arguments"
      end
      @options = SendNsca.defaults.merge(cfg_options).merge(hsh_options)
      @options[:svc_hostname] = Socket.gethostname if @options[:svc_hostname].nil?
    end

    def send(*args)

      svc_status = nil
      svc_output = nil

      case args.size
        when 0
          # svc_status and svc_output should be set on @options
          raise ArgumentError, "svc_status or svc_output not set" if @options[:svc_status].nil? or @options[:svc_output].nil?
          svc_status = @options[:status]
          svc_output = @options[:svc_output]
        when 2
          raise ArgumentError, "invalid svc_status" unless args[0].is_a? Symbol and STATUS.keys.include?(args[0])
          raise ArgumentError, "invalid svc_output" unless args[1].is_a? String
          svc_status = args[0]
          svc_output = args[1]
        else
          raise ArgumentError, "wrong number of arguments"
      end
      SendNsca.defaults.each_key do |option|
        next if [:send_nsca_config, :svc_status, :svc_output].include? option
        raise ArgumentError, "missing send_nsca option #{option}" if @options[option].nil?
      end
      raise ArgumentError, "missing send_nsca svc_status" if svc_status.nil?
      raise ArgumentError, "missing send_nsca svc_output" if svc_output.nil?
      run svc_status, svc_output
    end

    SendNsca.defaults.keys.each do |attr|
      define_method(attr.to_s) { @options[attr.to_sym] }
      define_method(attr.to_s + '=') { |value| @options[attr.to_sym] = value }
    end

    def inspect
      @options
    end

    private

      def command
        c = "#{send_nsca_binary} -H #{nsca_hostname} -p #{nsca_port} -to #{send_nsca_timeout} -d '#{send_nsca_delim}'"
        c << " -c #{send_nsca_config}" unless send_nsca_config.nil?
        c
      end

      def run(svc_status,svc_output)
        begin
          Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
            payload = "%s" % [svc_hostname,svc_descr,STATUS[svc_status],svc_output].join(send_nsca_delim)
            stdin.write("%s\n" % [payload])
            stdin.close
            $stdout.write stdout.gets if STDIN.tty?
            raise SendNscaError, stderr.gets.chomp unless wait_thr.value.exitstatus == 0
          end
        rescue Errno::ENOENT, Errno::EACCES => e
          raise SendNscaError, e.message
        end
      end
  end
end

