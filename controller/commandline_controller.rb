require_relative "../model/board"
require_relative "../model/player/localPlayer/local_ai_player"
require_relative "../model/player/remotePlayer/remote_ai_player"
require_relative "../model/player/localPlayer/local_real_player"
require_relative "../model/player/remotePlayer/remote_real_player"
require_relative "../model/game/game"
require_relative "../model/host_game"
require_relative "../model/mysql_adapter"
require_relative "../model/local_file_storage"
require 'contracts'
require 'observer'
require "xmlrpc/server"
require "singleton"

class CMDController

    include Singleton
    include Observable
    include Contracts::Core
    include Contracts::Builtin
    include Contracts::Invariants

    class CommandNotSupported < StandardError
    end
    class ModeNotSupported < StandardError
    end
    class AICountError < StandardError
    end


    #Contract ArrayOf[Object] => Any
    def initialize()
        original_dir = Dir.pwd
        Dir.chdir(__dir__)

        classes_before = ObjectSpace.each_object(Class).to_a
        Dir["../model/game/*"].each {|file|
            require_relative file
        }
        Dir.chdir(original_dir)

        classes_after = ObjectSpace.each_object(Class).to_a
        @modes_loaded = classes_after - classes_before

        @game_started = false
        @observer_views = []
        @players = []
        @clients_players = Hash.new
        @board = nil
        @clients_board = nil
        @player_playing = nil
        @clients_player_playing_index = nil
        @AI_players = 0
        # http://docs.ruby-lang.org/en/2.0.0/Hash.html
        @game_history = Hash.new(-1)
        @turn = 1
        @online_mode = false
        @player_name = nil
        @player_id = 1
        @save_requests_received = Hash.new(0)
        @turn_which_save_was_requested = -1
        @continuing_game = false
    end

    attr_accessor :modes_loaded, :game, :game_started, :players, :clients_players,
                  :player_playing, :clients_player_playing_index,
                  :board, :clients_board, :game_history, :turn, :online_mode,
                  :observer_views, :player_id, :save_requests_received,
                  :continuing_game, :turn_which_save_was_requested

    Contract None => String
    def get_player_playings_name
        return @player_playing.to_s
    end

    Contract None => Bool
    def human_player_playing?
        return @player_playing.is_a? LocalRealPlayer
    end

    Contract None => Bool
    def record_game?
        for player in @players
            return false if player.instance_of? LocalAIPlayer or
                player.instance_of? RemoteAIPlayer
        end
        return true
    end

    Contract None => Bool
    def ai_player_playing?
        return @player_playing.is_a? LocalAIPlayer
    end

    def remote_player_playing?
        return @player_playing.is_a? RemotePlayer
    end

    def get_player_names
        player_list = []
        for p in @players
            player_list.push(p.name)
        end
        return player_list
    end

    def hosting?
        return @server.hosting?
    end

    def get_server
        return @server
    end

    def add_remote_player(player_decided_name)
        player_name = @names.pop
        player_pattern = @patterns.pop
        changed
        notify_observers("Message: #{player_decided_name} has joined.")
        # puts "adding player #{player_name}"
        re = RemoteRealPlayer.new(player_name, player_pattern, player_decided_name)
        for obj in @observer_views
            re.add_observer(obj)
        end
        @players.push(re)

        for i in 2..@game.num_of_players
            if player_id == i
                re = LocalRealPlayer.new(player_name, player_pattern, player_decided_name)
                @clients_players[i].push(re)
            else
                re = RemoteRealPlayer.new(player_name, player_pattern, player_decided_name)
                @clients_players[i].push(re)
            end
        end
    end

    def create_hosted_game(game, given_host="127.0.0.1", given_port=50525) # No AIs, atm
        begin
            gameClazz = Object.const_get(game) # Game
        rescue StandardError
            raise ModeNotSupported
        end

        if gameClazz.superclass == Game
            @game = gameClazz.new()
            for i in 2..@game.num_of_players
                @clients_players[i] = []
            end
            @game_started = true
            @patterns = @game.patterns
            @names = @game.pieces
            changed
            notify_observers("Message: Starting server on host: #{given_host} "+
                             "and port #{given_port}.")
            @server = HostGame.new(game=@game, host=given_host, port=given_port)

            @server.start_server()
            player_name = @names.pop
            player_pattern = @patterns.pop

            if (@player_name == nil)
                changed
                notify_observers("gimme name!!!")
                while (@player_name == nil)
                    sleep(0.5)
                end
            end

            re = LocalRealPlayer.new(player_name, player_pattern, @player_name)
            for obj in @observer_views
                re.add_observer(obj)
            end
            @players.push(re)

            re = RemoteRealPlayer.new(player_name, player_pattern, @player_name)
            for i in 2..@game.num_of_players
                @clients_players[i].push(re)
            end

            # @player_name = nil

            while @players.size < @game.num_of_players #2 # number of players
                # puts "waiting... for players"
                sleep(1)
            end
            # puts "got players"

            @board = nil
            storage_handler = LocalFileStorage.new #("#{@player_name}_game_records.yml")
            @players.sort! {|p1,p2| p1.to_s <=> p2.to_s}
            for key, value in @clients_players
                @clients_players[key] = value.sort {|p1,p2| p1.to_s <=> p2.to_s}
            end
            key = "|#{@game.title}|"
            for player in @players
                key += "#{player}|"
            end
            if storage_handler.load(key)
                puts "Saved game found. Do you want to continue it?"
                if gets.chomp.include? "y"
                    game_state = storage_handler.load(key)
                    storage_handler.delete(key)

                    @board = game_state['board']
                    piece_order = game_state['piece_order']
                    for player, piece in @players.zip(piece_order)
                        player.piece = piece
                    end
                    for key, value in @clients_players
                        for player, piece in value.zip(piece_order)
                            player.piece = piece
                        end
                        @clients_players[key] = value
                    end
                    @board.delete_observers()
                    @clients_board = @board.copy
                    @clients_board.delete_observers()
                    @turn = game_state['turn']

                    first_players_index = @turn % @game.num_of_players
                end
            end
            if @board == nil
                # puts "nothing found or you sayd no"
                puts "Starting new game"
                @board = Board.new(@game.board_width, @game.board_height)
                @clients_board = Board.new(@game.board_width, @game.board_height)
                first_players_index = 1 # rand(0..(@players.size-1))
            end
            for obj in @observer_views
                @board.add_observer(obj)
            end

            @player_playing = @players[first_players_index]
            @clients_player_playing_index = first_players_index
        # puts "(HOST) My players are #{@players}"
        # puts "(HOST) size #{@players.size}"
        # puts "(HOST) My player playing is #{@player_playing}"
        else
            raise StandardError, "#{gameClazz} not a Game."
        end
        return @game
    end

    Contract String, Maybe[Integer] => Game
    def create_game(game, ai_players=0)
        if ai_players.to_i.to_s == ai_players.to_s and
          ai_players.to_i >= 0 and
          ai_players.to_i <= 2
            @AI_players = ai_players
        else
            raise AICountError, "Only two AIs supported."
        end
        begin
            gameClazz = Object.const_get(game) # Game
        rescue StandardError
            raise ModeNotSupported
        end
        if gameClazz.superclass == Game
            @game = gameClazz.new()
            @game_started = true
            #patterns = [@game.p1_patterns, @game.p2_patterns]
            #names = [@game.p1_piece, @game.p2_piece]
            @patterns = @game.patterns
            @names = @game.pieces
            for i in 0..(@AI_players-1)
                if @players.size < @game.num_of_players and
                   @players.size <= 2
                    ai = LocalAIPlayer.new(@names[i], @patterns[i],
                                           @names[i+1] || @names[0], @patterns[i+1] || @patterns[0])
                    @player_playing = ai
                    for obj in @observer_views
                        ai.add_observer(obj)
                    end
                    @players.push(ai)
                end
            end

            while @players.size < @game.num_of_players #2 # number of players
                if (@player_name == nil)
                    self.changed
                    self.notify_observers("gimme name!!!")
                    while (@player_name == nil)
                        sleep(0.5)
                    end
                end
                re = LocalRealPlayer.new(@names.pop, @patterns.pop, @player_name)
                for obj in @observer_views
                    re.add_observer(obj)
                end
                @players.push(re)

                @player_name = nil
            end
            # puts "done getting name #{@players}"

            @board = nil
            storage_handler = LocalFileStorage.new #("#{@player_name}_game_records.yml")
            @players.sort! {|p1,p2| p1.to_s <=> p2.to_s}
            for key, value in @clients_players
                @clients_players[key] = value.sort {|p1,p2| p1.to_s <=> p2.to_s}
            end
            key = "|#{@game.title}|"
            for player in @players
                key += "#{player}|"
            end
            if storage_handler.load(key)
                puts "Saved game found. Do you want to continue it?"
                if gets.chomp.include? "y"
                    game_state = storage_handler.load(key)
                    storage_handler.delete(key)

                    @board = game_state['board']
                    piece_order = game_state['piece_order']
                    for player, piece in @players.zip(piece_order)
                        player.piece = piece
                    end
                    for key, value in @clients_players
                        for player, piece in value.zip(piece_order)
                            player.piece = piece
                        end
                        @clients_players[key] = value
                    end
                    @board.delete_observers()
                    @turn = game_state['turn']

                    first_players_index = @turn % @game.num_of_players
                end
            end
            if @board == nil
                puts "nothing found or you sayd no"
                @board = Board.new(@game.board_width, @game.board_height)
                @clients_board = Board.new(@game.board_width, @game.board_height)
                first_players_index = 1 # rand(0..(@players.size-1))
            end

            for obj in @observer_views
                @board.add_observer(obj)
            end

            @player_playing = @players[first_players_index]
        else
            raise StandardError, "#{gameClazz} not a Game."
        end
        return @game
    end

    Contract Maybe[Int] => nil
    def take_turn(arg)
        if @player_playing.is_a? LocalAIPlayer
            @player_playing.play(@board)
        elsif @player_playing.is_a? RemoteRealPlayer
            @player_playing.play(@board)
        else
            @player_playing.last_column_played = arg
            if arg != -2 and arg != -3
                @board.set_piece(arg, @player_playing.piece)
            end
            if @online_mode
                if self.hosting?
                    @server.send_move(arg)
                else
                    get_server.server_handle.call("send_column_played", arg, @turn)
                end
            end
        end

        # puts "arg is #{arg}"
        # puts "last_column played = #{@player_playing.last_column_played}"
        if @player_playing.is_a? RemoteRealPlayer and
           @player_playing.last_column_played == -2
            puts "Partner wishes to save game. Type in -2 to save or -3 to reject."
        end
        if @board.analyze(@player_playing.pattern_array)
            # game over, no need to switch turns
            @player_playing.set_win_status(true)
        elsif @board.all_pieces_played?
            return nil
        else # switch turns
            @turn = @turn + 1
            @player_playing = @players[@players.index(@player_playing)+1]
            if @player_playing == nil
                @player_playing = @players[0]
            end
            # if @player_playing.is_a? RemoteRealPlayer
            #     @player_playing.send_move(arg)
            # end
        end
        nil
    end

    Contract None => Board
    def get_board()
        return @board
    end

    Contract Nat => nil
    def set_AIs(count)
        @AI_players = count
        nil
    end

    def connect_to_mysql()
        if @mysql_handler == nil
            @mysql_handler = MySQLAdapter.new
            for obj in @observer_views
                @mysql_handler.add_observer(obj)
            end
            @mysql_handler.connect()
        end

        return @mysql_handler.connected?
    end

    def get_hs_table
        if self.connect_to_mysql
            return @mysql_handler.get_table_sorted_by_points
        else
            nil
        end

        # if @mysql_handler != nil and @mysql_handler.connected?
        #     return @mysql_handler.get_table_sorted_by_points
        # else
        #     if @mysql_handler == nil
        #         @mysql_handler = MySQLAdapter.new
        #         if @mysql_handler.connected?
        #             return @mysql_handler.get_table_sorted_by_points
        #         else
        #             nil
        #         end
        #     end
        # end
        nil
    end

    def update_hs_records(player_that_won)
        if self.connect_to_mysql == false
            return nil
        end


        # if @mysql_handler == nil
        #     @mysql_handler = MySQLAdapter.new
        #     if @mysql_handler == nil
        #         return
        #     end
        # end
        winning_player = []
        losing_players = []
        for player in @players
            if @mysql_handler.player_exists?(player.to_s) == false
                @mysql_handler.add_player(player.to_s)
            end

            if player.to_s == player_that_won
                puts "found winning player #{player}"
                winning_player.push(player.to_s)
            else
                losing_players.push(player.to_s)
            end
        end

        if winning_player.any?
            for player in winning_player
                @mysql_handler.add_win_for_player(player)
            end
            for player in losing_players
                @mysql_handler.add_loss_for_player(player)
            end
        else
            for player in @players
                @mysql_handler.add_tie_for_player(player)
            end
        end
    end

    Contract ArrayOf[String] => nil
    def handle_event(commands)
        case commands
        when Array
            if commands[0].respond_to?("to_i") and
              commands[0].to_i.to_s == commands[0] and
              @game_started
                take_turn(commands[0].to_i)
                if commands[0].to_i == -2
                    if self.online_mode
                        if self.hosting?
                            if @turn_which_save_was_requested == -1
                                start_turn = @turn - 1
                                @turn_which_save_was_requested = start_turn
                            else
                                start_turn = @turn_which_save_was_requested
                            end
                            j = 0
                            while j < @game.num_of_players
                                j = 0
                                for turn in start_turn..(start_turn+@game.num_of_players-1)
                                    if CMDController.instance.game_history[turn] != -1
                                        j += 1
                                    end
                                end
                                # puts "didnt make it, j = #{j} and players #{@game.num_of_players} and range #{start_turn..(start_turn+@game.num_of_players-1)} and history #{CMDController.instance.game_history}"
                                sleep(1)
                            end
                            # puts "returning"
                            # puts "players #{@game.num_of_players}"
                            # puts "savers #{CMDController.instance.save_requests_received}"
                            # puts "turn #{CMDController.instance.turn}"
                            ret_val = 10
                            # puts "calcing for host"
                            for turn in start_turn..(start_turn+@game.num_of_players-1)
                                puts "savers #{CMDController.instance.save_requests_received}"
                                if CMDController.instance.game_history[turn] == -3
                                    # puts "found objector"
                                    ret_val = -11
                                end
                            end

                            if ret_val > 0
                                @turn = @turn_which_save_was_requested
                                self.handle_event(["save"])
                                puts "saving game"
                            else
                                puts "save request rejected!"
                                @turn_which_save_was_requested = -1
                            end
                        else
                            begin
                                ret_val = get_server.server_handle.call("get_save_request")
                                if ret_val > 0
                                    @turn = @turn_which_save_was_requested
                                    self.handle_event(["save"])
                                    puts "saving game"
                                else
                                    puts "save request rejected!"
                                    @turn_which_save_was_requested = -1
                                end
                            rescue Errno::ECONNRESET
                                @turn = @turn_which_save_was_requested
                                self.handle_event(["save"])
                                puts "saving game"
                            end
                        end
                    else
                        @turn = @turn - 1
                        self.handle_event(["save"])
                        puts "saving local game"
                    end
                end
            elsif commands[0].respond_to?("downcase")
                if commands[0].downcase.include? "name"
                    if (commands[1].size <= 10)
                        @player_name = commands[1]
                    else
                        #c = self.new
                        changed
                        notify_observers("Message: Name too long. Max 10 chars.")
                        sleep(1)
                        exit(0)
                    end
                elsif commands[0].downcase.include? "new" or
                     commands[0].downcase.include? "create"
                    ai_count = Integer(commands[2]) rescue nil
                    begin
                        gameClazz = Object.const_get(commands[1]) # Game
                    rescue NameError => ne
                        raise ne, "#{commands[1]} mode not found."
                    end
                    if gameClazz.superclass == Game
                        create_game(commands[1], ai_count)
                        online_mode = false
                    else
                        raise ModeNotSupported,"#{commands[1]} mode not supported."
                    end
                elsif commands[0].downcase.include? "host"
                    # commands[1] = "Connect4"
                    # given_host = commands[2]
                    # given_port = Integer(commands[3]) rescue nil
                    given_host = "127.0.0.1"
                    given_port = 50525
                    commands[1] = "Connect4"
                    begin
                        gameClazz = Object.const_get(commands[1]) # Game
                    rescue NameError => ne
                        raise ne, "#{commands[1]} mode not found."
                    end
                    if gameClazz.superclass == Game and
                      given_host != nil and
                      given_port != nil
                        create_hosted_game(commands[1], given_host, given_port)
                        @online_mode = true
                    elsif gameClazz.superclass == Game
                        create_hosted_game(commands[1])
                        @online_mode = true
                    else
                        raise ModeNotSupported,"#{commands[1]} mode not supported."
                    end
                elsif commands[0].downcase.include? "join"
                    # commands[1] = "Connect4"
                    # given_host = commands[2]
                    # given_port = Integer(commands[3]) rescue nil
                    given_host = "127.0.0.1"
                    given_port = 50525
                    commands[1] = "Connect4"
                    begin
                        gameClazz = Object.const_get(commands[1]) # Game
                    rescue StandardError
                        raise ModeNotSupported
                    end
                    if gameClazz.superclass == Game
                        @game = gameClazz.new()
                        if (@player_name == nil)
                            changed
                            notify_observers("gimme name!!!")
                            while (@player_name == nil)
                                sleep(0.5)
                            end
                        end
                        @server = HostGame.new(game=@game, host=given_host, port=given_port)
                        @game, @game_started, @players, players_index, @board, @turn = @server.join_server(@player_name)
                        @player_playing = @players[players_index]
                        # @player_name = nil
                        # puts "My players are #{@players}"
                        # puts "size #{@players.size}"
                        # puts "My player playing is #{@player_playing}"
                        @online_mode = true
                        for obj in @observer_views
                            @board.add_observer(obj)
                        end
                        for re in @players
                            for obj in @observer_views
                                re.add_observer(obj)
                            end
                        end

                    else
                        raise StandardError, "#{gameClazz} not a Game."
                    end

                elsif commands[0].downcase.include? "save"
                    @clients_players[1] = @players
                    key = "|#{@game.title}|"
                    for player in @players
                        key += "#{player}|"
                    end
                    piece_order = []
                    for p in @players
                        piece_order.push(p.piece)
                    end

                    game_state = {
                        "board" => @board,
                        "turn" => @turn,
                        "piece_order" => piece_order
                    }
                    storage_handler = LocalFileStorage.new #("#{@player_name}_game_records.yml")
                    storage_handler.save(key,game_state)
                    self.handle_event(['reset'])

                elsif commands[0].downcase.include? "continue"
                    @continuing_game = true
                # key = "|"
                # for player in @players
                #     key += "#{player}|"
                # end
                # storage_handler = LocalFileStorage.new("#{@player_name}_game_records.yml")
                # game_state = storage_handler.load(key)

                # @board = game_state['board']
                # @turn = game_state['turn']

                elsif commands[0].downcase.include? "restart" or
                     commands[0].downcase.include? "reset"
                    if self.record_game? and commands[1] != nil
                        if self.online_mode
                            if self.hosting?
                                self.update_hs_records(commands[1])
                            end
                        else
                            self.update_hs_records(commands[1])
                        end
                    end

                    @players = []
                    @board = nil
                    @player_playing = nil
                    @game_started = false
                    if @online_mode
                        @server.close_server()
                        @online_mode = false
                    end
                elsif commands[0].downcase.include? "ai"
                    take_turn(0)
                elsif commands[0].downcase.include? "remote"
                    take_turn(0)
                else
                    raise CommandNotSupported, "#{commands} not supported."
                end
            else
                raise CommandNotSupported, "#{commands} not supported."
            end
        else
            raise CommandNotSupported, "#{commands} not supported."
        end
        nil
    end

end
