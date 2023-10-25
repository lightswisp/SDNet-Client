require "socket"
require "openssl"

class TLSClient
    @ip : String
    @port : Int32
    @sni : String

    def initialize(ip : String, port : Int32, sni : String)
        @ip = ip
        @port = port
        @sni = sni
    end

    def connect()
        begin
            socket = TCPSocket.new(@ip, @port)
            context = OpenSSL::SSL::Context::Client.new()
            context.verify_mode = OpenSSL::SSL::VerifyMode::NONE
            #context.add_options(OpenSSL::SSL::Options::NO_SSL_V2 | OpenSSL::SSL::Options::NO_SSL_V3 | OpenSSL::SSL::Options::NO_TLS_V1 | OpenSSL::SSL::Options::NO_TLS_V1_1)
            ssl = OpenSSL::SSL::Socket::Client.new(socket, context, true, @sni)
            ssl.sync = true
            return ssl
        rescue e
            puts e
            return nil
        end
    end
end
