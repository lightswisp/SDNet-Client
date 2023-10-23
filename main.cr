require "webview"
require "json"
require "option_parser"
require "./template/main"
require "./proxy/proxy"
require "./proxy/dispatcher"

MAX_BUFFER = 1024
LOCAL_PORT = 8080
OPTIONS = {:cli => false} of Symbol => String | Bool

OptionParser.parse do |parser|
    parser.banner = "Usage: client [arguments]"
    parser.on("-c", "--cli", "CLI Interface, the default is GUI") { OPTIONS[:cli] = true }
    parser.on("-a ADDR", "--address=ADDR", "Specifies the address of dispatcher") { |addr| OPTIONS[:ip] = addr }
    parser.on("-p PORT", "--port=PORT", "Specifies the port of dispatcher") { |port| OPTIONS[:port] = port }
    parser.on("-s SNI", "--sni=SNI", "Specifies the server name indication of dispatcher") { |sni| OPTIONS[:sni] = sni }
    parser.on("-h", "--help", "Show this help") do
      puts parser
      exit
    end
    parser.invalid_option do |flag|
      STDERR.puts "ERROR: #{flag} is not a valid option."
      STDERR.puts parser
      exit(1)
    end
  end

{% if flag?(:win32) %}
@[Link("user32")]
lib Win32
    fun GetConsoleWindow() : Int32*
    fun ShowWindow(hWnd : Int32*, nCmdShow : Int32)
end

unless OPTIONS[:cli]
    handle = Win32.GetConsoleWindow()
    Win32.ShowWindow(handle, 0) # hide console
end
# Windows
{% end %}

def main()

    unless OPTIONS[:cli]
        gui_main()
    else
        cli_main()
    end
end

def cli_main()
    begin
            ip = OPTIONS[:ip].to_s
            port = OPTIONS[:port].to_s
            sni = OPTIONS[:sni].to_s
            dispatcher = Dispatcher.new(ip, port.to_i, sni)
            nodes = dispatcher.get_nodes_list()
            if nodes
                ret = {"message" => "Listening on 8080"}.to_json
                proxy = LocalProxy.new(LOCAL_PORT, nodes, MAX_BUFFER)
                
                proxy.not_nil!.rotate()
                proxy.not_nil!.start()

            end
    rescue KeyError
        puts "Some options are missing!"
        puts "Exiting..."
        exit(1)
    end
end

def gui_main()
    process = nil
    html = MAIN_TEMPLATE
    wv = Webview.window(350, 410, Webview::SizeHints::FIXED, "SDNet Client", true)
    wv.html = html
    wv.bind("proxy_connect", Webview::JSProc.new { |args|
            ret = {"message" => "error!"}.to_json

            ip = args[0].to_s
            port = args[1].to_s
            sni = args[2].to_s

            unless ip.empty? || port.empty? || sni.empty?
                {% if flag?(:win32) %}
                    process = Process.new("sdnet.exe", ["--cli", "-a", ip, "-p", port, "-s", sni])
                {% elsif flag?(:linux) %}
                    process = Process.new("sdnet", ["--cli", "-a", ip, "-p", port, "-s", sni])
                {% end %}
                ret = {"message" => "Listening on 8080"}.to_json
            end

            JSON::Any.new(ret)
    })

    wv.bind("proxy_disconnect", Webview::JSProc.new {
        ret = {"message" => "error!"}.to_json
        if process 
            pid = process.not_nil!.pid.to_s
            {% if flag?(:win32) %}
            Process.new("taskkill", ["/F", "/PID", pid])
            {% elsif flag?(:linux) %}
                process.not_nil!.signal(Signal::KILL)
            {% end %}
            
            ret = {"message" => "ok"}.to_json
        end

        JSON::Any.new(ret)
    })

    wv.run
    wv.destroy

    # taskill the proxy if it was launched, so that it doesn't hang after closing the main window

end

main()


















