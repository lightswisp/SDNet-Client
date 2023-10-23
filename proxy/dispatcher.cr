require "./tls"
require "json"

 class Dispatcher 
    @ip : String
    @port : Int32
    @sni : String

    def initialize(ip : String, port : Int32, sni : String)
        @ip = ip
        @port = port
        @sni = sni
    end

    def get_nodes_list()
        client = TLSClient.new(@ip, @port, @sni)
        client_connection = client.connect()

        if !client_connection
            puts "Failed to connect!"
            return nil
        end

        puts "Connected!"
        puts client_connection.tls_version
    
        client_connection.write ("CLIENT_NEW\n".to_slice)   
        data = client_connection.gets

        if !data
            puts "Failed to retreive data!"
            return nil
        end

        begin
        layer_2_nodes_list = Array(Hash(String, String)).from_json(data)
        rescue
            puts "Failed to parse the data!"
            return nil
        end
        return layer_2_nodes_list
    end
 end