require 'ostruct'
require 'open3'

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
        begin
          cfg_options = YAML.load File.open(cfg_file)
          raise ConfigurationError, "senedsa_config not allowed in configuration file (#{cfg_file})" unless cfg_options[:senedsa_config].nil?
        rescue Psych::SyntaxError => e
          raise StandardError, "syntax error in configuration file #{cfg_file}: #{e.message}"
        rescue Errno::ENOENT, Errno::EACCES => e
          raise StandardError, e.message
        end
        cfg_options
      end

    attr_accessor :send_nsca, :nsca

    class Error < StandardError; end
    class SendNscaError < Error; end
    class ConfigurationError < SendNscaError; end

    def initialize(svc_hostname,svc_descr,options)
      @options = options.nil? ? SendNsca.defaults : SendNsca.defaults.merge(options)
      @options[:svc_hostname] = svc_hostname
      @options[:svc_descr] = svc_descr
    end

    SendNsca.defaults.keys.each do |attr|
      define_method(attr.to_s) { @options[attr.to_sym] }
      define_method(attr.to_s + '=') { |value| @options[attr.to_sym] = value }
    end

    def send(status,svc_output)
      run(status,svc_output)
    end

    private

      def command
        c = "#{send_nsca_binary} -H #{nsca_hostname} -p #{nsca_port} -t #{send_nsca_timeout} -d '#{send_nsca_delim}'"
        c << " -c #{send_nsca_config}" unless send_nsca_config.nil?
        c
      end

      def run(status,svc_output)
        begin
          Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
            stdin.write("%s\n" % [svc_hostname,svc_descr,STATUS[status],svc_output].join(send_nsca_delim))
            $stdout.write stdout.gets
            raise SendNscaError, stderr.gets.chomp unless wait_thr.value.exitstatus == 0
          end
        rescue Errno::ENOENT, Errno::EACCES => e
          raise SendNscaError, e.message
        end
      end
  end
end

