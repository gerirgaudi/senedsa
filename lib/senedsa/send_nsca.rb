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

    @send_nsca = OpenStruct.new
    @send_nsca.bin = 'send_nsca'
    @send_nsca.cfg = nil
    @send_nsca.delim = '\t'
    @send_nsca.to = 10
    @send_nsca.debug = false

    @nsca = OpenStruct.new
    @nsca.hostname = nil
    @nsca.port = 5667

    class << self; attr_accessor :send_nsca, :nsca end

    attr_accessor :send_nsca, :nsca

    class Error < StandardError; end
    class SendNscaError < Error; end

    def initialize(hostname,svc_descr,opts)
      @hostname = hostname
      @svc_descr = svc_descr

      @send_nsca = OpenStruct.new
      @send_nsca.bin = opts[:bin] ? opts[:bin] : SendNsca.send_nsca.bin
      @send_nsca.cfg = opts[:cfg] ? opts[:cfg] : SendNsca.send_nsca.cfg
      @send_nsca.delim = opts[:delim] ? opts[:delim] : SendNsca.send_nsca.delim
      @send_nsca.to = opts[:to] ? opts[:to] : SendNsca.send_nsca.to
      @send_nsca.command = nil

      @nsca = OpenStruct.new
      @nsca.hostname = opts[:nsca_hostname] ? opts[:nsca_hostname] : SendNsca.nsca.hostname
      @nsca.port = opts[:nsca_port] ? opts[:nsca_port] : SendNsca.nsca.port
    end

    def send(rt,svc_output)
      build_command_line
      run_command(rt,svc_output)
    end

    private

      def build_command_line
        c = "#{@send_nsca.bin} -H #{@nsca.hostname}"
        c << " -p #{@nsca.port}" unless @nsca.port.nil?
        c << " -c #{@send_nsca.cfg}" unless @send_nsca.cfg.nil?
        c += " -d '#{@send_nsca.delim}'"
        c << " -t #{@send_nsca.to}"

        @send_nsca.command = c
      end

    def run_command(rt,svc_output)
      begin
        Open3.popen3(@send_nsca.command) do |stdin, stdout, stderr, wait_thr|
          stdin.write("%s\n" % [@hostname,@svc_descr,STATUS[rt],svc_output].join(@send_nsca.delim))
          $stdout.write stdout.gets
          raise SendNscaError, stderr.gets.chomp unless wait_thr.value.exitstatus == 0
        end
      rescue Errno::ENOENT, Errno::EACCES => e
        raise SendNscaError, e.message
      end
    end

  end

end