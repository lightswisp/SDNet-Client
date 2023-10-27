require "./tls"

class LocalProxy
    @port : Int32
    @layer_2_nodes_list : Array(Hash(String, String))
    @max_buffer : Int32
    @temp_server : Hash(String, String)

    def initialize(port : Int32, layer_2_nodes_list : Array(Hash(String, String)), max_buffer : Int32)
        @port = port
        @layer_2_nodes_list = layer_2_nodes_list
        @max_buffer = max_buffer
        @proxy = TCPServer.new("0.0.0.0", @port)
        puts "Listening on #{@port}"
        @temp_server = @layer_2_nodes_list.sample
    end

    def is_alive(ssl, request)
        return nil if !ssl
        ptr = LibC.malloc(@max_buffer).as(Pointer(UInt8))
        ssl.puts(request)
        begin         
            read_bytes = ssl.read(ptr.to_slice(@max_buffer))
            response = String.new ptr.to_slice(read_bytes)
            p "IS_ALIVE #{response}"
        rescue
            return nil
        ensure
            p "free() -> #{ptr}"
            LibC.free(ptr)
            GC.collect()
        end
        return response
    end

    def stop()
        @proxy.close
    end

    def handle_client(client)
    
        begin
                temp_data, client_addr = client.receive(@max_buffer) # .as(String)
                return if temp_data.nil? || temp_data.empty?
                temp_data_lines = temp_data.split("\r\n")
                temp_data_first_line = temp_data_lines[0].split(" ")
                client.close if temp_data_first_line.size < 2
                request_method = temp_data_first_line[0]

                request_host, request_port = temp_data_first_line[1].split(":")
    
                if request_method =~ /CONNECT/
                    # CONNECT
                    remote_client = TLSClient.new(@temp_server["ip"], @temp_server["port"].to_i, @temp_server["sni"])
                    ssl = remote_client.connect()
                    if !ssl
                        ssl = force_rotate_and_check()
                    end

                    if header = is_alive(ssl, temp_data)
                        client.puts(header)
                    else    
                        ssl.not_nil!.close
                        client.close
                        return
                    end 

                    spawn do
                        # CLIENT SIDE
                        ptr = LibC.malloc(@max_buffer).as(Pointer(UInt8))
                        begin
                            
                            loop do
                            
                            read_bytes = client.read(ptr.to_slice(@max_buffer))
                            if read_bytes == 0
                                # no more bytes from the client
                                break 
                            end
                            ssl.not_nil!.write(ptr.to_slice(read_bytes))
                            end

                        rescue IO::Error
                            # client has closed the connection
                            next
                        ensure
                            ssl.not_nil!.close 
                            client.close
                            LibC.free(ptr)
                            GC.collect()
                        end
                    end
    
                    spawn do
                        # REMOTE SIDE
                        ptr = LibC.malloc(@max_buffer).as(Pointer(UInt8))
                        begin
                            
                            loop do
                                
                                read_bytes = ssl.not_nil!.read(ptr.to_slice(@max_buffer))
                                if read_bytes == 0
                                    # no more bytes from the remote host
                                    break 
                                end
                                client.write(ptr.to_slice(read_bytes))
                            end

                        rescue IO::Error
                            # remote has closed the connection
                            next
                        ensure
                            ssl.not_nil!.close 
                            client.close
                            LibC.free(ptr)
                            GC.collect()
                        end
                    end
                    
                    Fiber.yield # force the main fiber to sleep in order to switch to other 2 fibers above
    
                    
                else
                    # GET POST PUT DELETE
                    remote_client = TLSClient.new(@temp_server["ip"], @temp_server["port"].to_i, @temp_server["sni"])
                    ssl = remote_client.connect()
                    if !ssl
                        ssl = force_rotate_and_check()
                    end
                    
                    ssl.not_nil!.puts(temp_data)

                    ptr = LibC.malloc(@max_buffer).as(Pointer(UInt8))

                    loop do 
                        read_bytes = ssl.not_nil!.read(ptr.to_slice(@max_buffer))
                        if read_bytes == 0
                            # no more bytes from the remote host
                            break 
                        end                                   
                        client.write(ptr.to_slice(read_bytes))
                    end

                    p "NON CONNECT free() -> #{ptr}"
                    ssl.not_nil!.close      
                    client.close  
                  	LibC.free(ptr)
                    GC.collect()
                end
                

        rescue IO::Error
            client.close
            GC.collect()
            return
        end
    
    end

    def start()
        while client = @proxy.accept?
            spawn handle_client(client)
        end
    end

    def layer_2_is_alive()
        client = TLSClient.new(@temp_server["ip"], @temp_server["port"].to_i, @temp_server["sni"])
		ssl = client.connect
		if ssl
			return ssl 
		end
		return nil
    end

    def force_rotate_and_check()
        ssl = nil

		loop do
			rotated = (@layer_2_nodes_list - [@temp_server]).sample
			@temp_server = rotated
			ssl = layer_2_is_alive()
			break if ssl
			time = [*5..15].sample
            puts "Sleeping for #{time} seconds before taking next server..."
			sleep time
		end

		return ssl
    end

    def rotate()
        spawn do
            loop do
                time = [*3..10].sample
                puts "Sleeping for #{time} minutes before next rotation"
                sleep(time * 60)
                rotated = (@layer_2_nodes_list - [@temp_server]).sample
                @temp_server = rotated
            end
        end
    end
end
