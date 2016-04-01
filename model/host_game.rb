require 'contracts'
require 'observer'
require "xmlrpc/server"
require "xmlrpc/client"
require_relative 'player/player'
require_relative 'game/game'
require_relative "../controller/commandline_controller"
class HostGame

    include Observable

    include Contracts::Core
    include Contracts::Builtin
    include Contracts::Invariants

    attr_accessor :server_handle

    # http://www.ingate.com/files/422/fwmanual-en/xa10285.html
    invariant(@port) {@port > 1024 && @port < 65535}

    #Contract Game, Nat => nil
    def initialize(game="Connect4", port=8080)
        @game = game
        @port = port
        @server_handle = nil
        @server_thread = nil
        @move_to_send = -1
        @move_received = -1
        nil
    end

    def update(arg)
        # send to client
        if arg.is_a? Integer and
          arg >= 0 and
          arg <= @game.board_width
            @move_to_send = arg
        else
            puts "Notification not approriate: #{arg}"
        end
    end

    def hosting?
        return @server_handle.is_a? XMLRPC::Server
    end

    def send_move(move)
        @move_to_send = move
    end

    def get_move()
        while @move_received == -1
            puts "host waiting for client to move"
            sleep(1)
        end
        move = @move_received
        @move_received = -1
        move
    end


    Contract None => nil
    def start_server()
        # http://ruby-doc.org/stdlib-2.0.0/libdoc/xmlrpc/rdoc/XMLRPC/Server.html
        # add handler for receiving piece placements from connected clients

        @server_handle = XMLRPC::Server.new(@port)

        @server_handle.add_handler("send_column_played") do |column_num|
            @move_received = column_num
            true
        end

        @server_handle.add_handler("get_column_played") do ||
                                                           while @move_to_send == -1
                                                               puts "client waiting for host to move"
                                                               sleep(1)
                                                           end
            move = @move_to_send
            @move_to_send = -1
            puts "sending our move to client: #{move}"
            move
        end

        @server_handle.add_handler("join_game") do |player_name|
            if CMDController.get_number_of_players_playing < 2 #@game.num_of_players
                CMDController.add_remote_player(player_name)
            end
            true
        end

        @server_handle.add_handler("get_players") do |arg|
            puts "sending"
            #            Marshal.dump(CMDController.get_player_names)
            CMDController.get_player_names
        end

        @server_handle.set_default_handler do |name, *args|
            raise XMLRPC::FaultException.new(-99, "Method #{name} missing" +
                                                  " or wrong number of parameters!")
        end

        server_thread = Thread.new {@server_handle.serve}
        nil
    end

    #Contract None => nil
    def join_server()
        # http://ruby-doc.org/stdlib-2.0.0/libdoc/xmlrpc/rdoc/XMLRPC/Server.html
        # add handler for receiving piece placements from connected clients
        @server_handle = XMLRPC::Client.new("127.0.0.1", "/RPC2", @port)
        @server_handle.call("join_game", "funkyMan")
        puts "calling"
        lis = @server_handle.call("get_players", "!")
        puts lis
        return lis
    end

    def send_and_get_move(my_move)
        return @server_handle.call("send_column_played", my_move)
    end


    Contract None => nil
    def close_server()
        if (@server_handle != nil)
            @server_handle.shutdown
        end
        if (@server_thread != nil)
            Thread.kill(@server_thread)
        end
        nil
    end

end
