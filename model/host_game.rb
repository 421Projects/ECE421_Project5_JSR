require 'contracts'
require 'observer'
require 'yaml'
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
    def initialize(game=Connect4.new, ip="127.0.0.1", port=8080, url_extension="/RPC2")
        @game = game
        @port = port
        @ip = ip
        @url_extension = url_extension
        @server_handle = nil
        @server_thread = nil
        @move_to_send = -1
        @move_received = -1
        nil
    end

    def hosting?
        return @server_handle.is_a? XMLRPC::Server
    end

    def send_move(move)
        CMDController.game_history[CMDController.turn] = move
        #@move_to_send = move
    end

    def get_move()
        while CMDController.game_history[CMDController.turn] == -1
            puts "host waiting for client to move for #{CMDController.turn}"
            sleep(1)
        end
        CMDController.game_history[CMDController.turn]
    end


    Contract None => nil
    def start_server()
        # http://ruby-doc.org/stdlib-2.0.0/libdoc/xmlrpc/rdoc/XMLRPC/Server.html
        # add handler for receiving piece placements from connected clients

        @server_handle = XMLRPC::Server.new(@port)

        @server_handle.add_handler("send_column_played") do |column_num, turn|
            # puts "got move for #{CMDController.turn}"
            CMDController.game_history[turn] = column_num
            #@move_received = column_num
            true
        end

        @server_handle.add_handler("get_column_played") do |turn|
            while CMDController.game_history[turn] == -1
                puts "client waiting for host to move #{turn}"
                sleep(1)
            end
            CMDController.game_history[turn]
        end

        @server_handle.add_handler("join_game") do |player_name|
            CMDController.player_id = CMDController.player_id + 1
            this_players_id = CMDController.player_id
            if CMDController.get_number_of_players_playing < @game.num_of_players
                CMDController.add_remote_player(player_name)
            end
            while CMDController.get_number_of_players_playing < @game.num_of_players or
                 CMDController.players.include?(CMDController.player_playing) == false
                sleep(1)
            end

            puts "My player id is #{this_players_id}"
            #Marshal.dump([
            YAML::dump([
                           CMDController.game,
                           CMDController.game_started,
                           CMDController.clients_players[this_players_id],
                           CMDController.clients_player_playing_index,
                           CMDController.clients_board
                       ])
        end

        @server_handle.set_default_handler do |name, *args|
            raise XMLRPC::FaultException.new(-99, "Method #{name} missing" +
                                                  " or wrong number of parameters!")
        end

        server_thread = Thread.new {@server_handle.serve}
        nil
    end

    #Contract None => nil
    def join_server(player_name)
        # http://ruby-doc.org/stdlib-2.0.0/libdoc/xmlrpc/rdoc/XMLRPC/Server.html
        # add handler for receiving piece placements from connected clients
        @server_handle = XMLRPC::Client.new(@ip, @url_extension, @port)
        game_attributes = @server_handle.call("join_game", player_name)
        return YAML::load(game_attributes)
    end

    Contract None => nil
    def close_server()
        if (@server_handle != nil and @server_handle.respond_to? :shutdown)
            @server_handle.shutdown
        end
        if (@server_thread != nil)
            Thread.kill(@server_thread)
        end
        nil
    end

end
