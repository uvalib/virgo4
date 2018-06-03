# lib/uva/networks.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ipaddr'
require 'uva'

module UVA

  # UVA::Networks
  #
  module Networks

    include UVA

    # Configuration file listing local ("on Grounds") subnets.
    LOCAL_SUBNET_CONFIG = 'config/subnets.yml'

    # =========================================================================
    # :section: Module methods
    # =========================================================================

    module ModuleMethods

      extend self

      # The name of the current server host.
      #
      # @return [String]
      #
      def host_server
        Socket.gethostname
      end

      # make_ip_addr
      #
      # @param [String, IPAddr] addr
      # @param [Symbol, nil]    method    For log error messages.
      #
      # @return [String]
      #
      def make_ip_addr(addr, method = nil)
        IPAddr.new(addr)
      rescue => e
        Log.error(method, e, addr)
      end

      # Load local subnets the YAML configuration file.
      #
      # @param [String] path            Relative or absolute path to the file.
      #                                 (default: self#LOCAL_SUBNET_CONFIG).
      #
      # @return [Array<IPAddr>]         Zero or more local subnets.
      #
      def load_local_subnets(path = nil)
        path ||= LOCAL_SUBNET_CONFIG
        result = Config.load(path) || []
        result.map { |subnet| make_ip_addr(subnet, __method__) }.compact
      end

      # NOTE: Loads configuration information at startup.
      LOCAL_ADDRESS_RANGES = load_local_subnets.deep_freeze

      # An array of local ("on Grounds") IP address ranges.
      #
      # @return [Array<IPAddr>]
      #
      # == Usage Notes
      # The configuration file must be present at startup and is not
      # re-evaluated if it is modified.
      #
      def local_subnets
        LOCAL_ADDRESS_RANGES
      end

    end

    include ModuleMethods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # The IP address of the current session.
    #
    # @param [ActionDispatch::Request, nil] req             Default: current
    #                                                         request.
    # @param [TrueClass, FalseClass, nil]   ignore_forged   If *true*, return
    #                                                         the true IP
    #                                                         address even if
    #                                                         :forged_ip is
    #                                                         present in
    #                                                         `session`.
    #
    # @return [String, nil]
    #
    # == Usage Notes
    # - If not in production, URL parameter "forged_ip=..." can be used to test
    # behavior as if the request was originating from the given IP address
    # instead of the client's current IP address.
    #
    # - Use `get_current_ip(true)` for the true IP address (even if :forged_ip
    # is present in `session`.)
    #
    def get_current_ip(req = nil, ignore_forged = nil)
      if [true, false].include?(req)
        ignore_forged = req
        req = nil
      end
      req ||= (@request if defined?(@request))
      req ||= (request  if defined?(request))
      ip_addr =
        if req.is_a?(ActionDispatch::Request)
          req.env['HTTP_X_REAL_IP'].presence || req.env['REMOTE_ADDR'].presence
        end
      if !ignore_forged && (forged_ip = session[:forged_ip]).present?
        Log.info {
          ip_addr ?
            "Overriding #{ip_addr.inspect} with #{forged_ip.inspect}" :
            "Using forged IP address #{forged_ip.inspect}"
        }
        ip_addr = forged_ip
      elsif !ip_addr
        if req
          Log.warn(__method__, "#{req.inspect} unexpected")
        else
          Log.info(__method__, 'no request')
        end
      end
      ip_addr
    end

    # Indicate whether the given IP address is within a private address space
    # (for local development).
    #
    # @param [String] ip_addr         Default: `get_current_ip`.
    #
    def private_subnet?(ip_addr = nil)
      ip_addr ||= get_current_ip
      ActionDispatch::RemoteIp::TRUSTED_PROXIES.any? do |subnet|
        subnet.include?(ip_addr)
      end
    end

    # Indicate whether an IP address is on a local ("on Grounds") subnet.
    #
    # @param [String] ip_addr         Default: `get_current_ip`.
    #
    # == Usage Notes
    # If not in production, URL parameter "forged_ip=..." can be used to test
    # behavior as if the request was originating from the given IP address
    # instead of the client's current IP address.
    #
    def local_subnet?(ip_addr = nil)
      ip_addr ||= get_current_ip
      return true if private_subnet?(ip_addr)
      ip = make_ip_addr(ip_addr, __method__)
      local_subnets.any? { |subnet| subnet.include?(ip) }
    end

    # Indicate whether an IP address is on a local ("on Grounds") subnet.
    #
    # @param [String] ip_addr         Default: `get_current_ip`.
    #
    # @see self#local_subnet?
    #
    alias_method :on_grounds?, :local_subnet?

  end

end

__loading_end(__FILE__)
