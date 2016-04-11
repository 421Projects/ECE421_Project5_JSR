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
    invariant(@port) {@port.to_i > 1024 && @port.to_i < 65535}

    Contract Game, String, Nat, String => nil
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

    Contract None => Bool
    def hosting?
        return @server_handle.is_a? XMLRPC::Server
    end

    def send_move(move)
        CMDController.instance.game_history[CMDController.instance.turn] = move
        #@move_to_send = move
    end

    def get_move()
        while CMDController.instance.game_history[CMDController.instance.turn] == -1
            # puts "host waiting for client to move for #{CMDController.instance.turn}"
            sleep(1)
        end
        CMDController.instance.game_history[CMDController.instance.turn]
    end


    Contract None => nil
    def start_server()
        # http://ruby-doc.org/stdlib-2.0.0/libdoc/xmlrpc/rdoc/XMLRPC/Server.html
        # add handler for receiving piece placements from connected clients
        @server_handle = XMLRPC::Server.new(port=@port, host=@ip)

        @server_handle.add_handler("send_column_played") do |column_num, turn|
            # puts "got move for #{CMDController.instance.turn}"
            CMDController.instance.game_history[turn] = column_num
            #@move_received = column_num
            true
        end

        @server_handle.add_handler("get_save_request") do
            puts "got save request"
            puts "players #{@game.num_of_players}"
            puts "history #{CMDController.instance.game_history}"
            puts "turn #{CMDController.instance.turn}, starting wait... server side"
            puts "#{CMDController.instance.turn..(CMDController.instance.turn+@game.num_of_players-1)}"
            if CMDController.instance.turn_which_save_was_requested == -1
                start_turn = CMDController.instance.turn
                CMDController.instance.turn_which_save_was_requested = start_turn
            else
                start_turn = CMDController.instance.turn_which_save_was_requested
            end
            puts "#{CMDController.instance.turn_which_save_was_requested}"
            j = 0
            while j < @game.num_of_players
                j = 0
                for turn in start_turn..(start_turn+@game.num_of_players-1)
                    if CMDController.instance.game_history[turn] != -1
                        j += 1
                    end
                end
                puts "currently, j = #{j} and players #{@game.num_of_players} and range #{start_turn..(start_turn+@game.num_of_players-1)} and history #{CMDController.instance.game_history}"
                sleep(1)
            end
            puts "returning server side"
            puts "players #{@game.num_of_players}"
            puts "turn #{CMDController.instance.turn}"
            ret_val = 10
            puts "calcing for client"
            for turn in start_turn..(start_turn+@game.num_of_players-1)
                puts "savers #{CMDController.instance.save_requests_received}"
                if CMDController.instance.game_history[turn] == -3
                    puts "found objector"
                    ret_val = -11
                end
            end
            if ret_val < 0
                CMDController.instance.turn_which_save_was_requested = -1
            end
            ret_val
        end

        @server_handle.add_handler("get_column_played") do |turn|
            while CMDController.instance.game_history[turn] == -1
                # puts "client waiting for host to move #{turn}"
                sleep(1)
            end
            CMDController.instance.game_history[turn]
        end

        @server_handle.add_handler("join_game") do |player_name|
            CMDController.instance.player_id = CMDController.instance.player_id + 1
            this_players_id = CMDController.instance.player_id
            if CMDController.instance.players.size < @game.num_of_players
                CMDController.instance.add_remote_player(player_name)
            end
            while CMDController.instance.players.size < @game.num_of_players or
                 CMDController.instance.players.include?(CMDController.instance.player_playing) == false
                sleep(1)
            end

            # puts "My player id is #{this_players_id}"
            #Marshal.dump([
            YAML::dump([
                           CMDController.instance.game,
                           CMDController.instance.game_started,
                           CMDController.instance.clients_players[this_players_id],
                           CMDController.instance.clients_player_playing_index,
                           CMDController.instance.clients_board,
                           CMDController.instance.turn
                       ])

        end

        @server_handle.set_default_handler do |name, *args|
            raise XMLRPC::FaultException.new(-99, "Method #{name} missing" +
                                                  " or wrong number of parameters!")
        end

        server_thread = Thread.new {@server_handle.serve}
        nil
    end

    Contract String => Any
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
