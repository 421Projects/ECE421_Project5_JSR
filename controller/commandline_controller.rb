require_relative "../model/board"
require_relative "../model/player/localPlayer/local_ai_player"
require_relative "../model/player/remotePlayer/remote_ai_player"
require_relative "../model/player/localPlayer/local_real_player"
require_relative "../model/player/remotePlayer/remote_real_player"
require_relative "../model/game/game"
require_relative "../model/host_game"
require 'contracts'
require 'observer'
require "xmlrpc/server"

class CMDController

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


    Contract ArrayOf[Object] => Any
    def self.initialize(observer_views)
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
        @observer_views = observer_views.to_a
        @players = []
        @clients_players = Hash.new
        @board = nil
        @clients_board = nil
        @player_playing = nil
        @clients_player_playing_index = nil
        @AI_players = 0
        @previous_play = -1
        # http://docs.ruby-lang.org/en/2.0.0/Hash.html
        @game_history = Hash.new(-1)
        @turn = 1
        @online_mode = false
        @player_id = 1 # starting with host player
    end

    Contract None => ArrayOf[Class]
    def self.get_mode_files_loaded
        @modes_loaded
    end

    def self.get_number_of_players_playing
        @players.size
    end

    def self.game
        @game
    end

    def self.game_started
        @game_started
    end

    def self.players
        @players
    end

    def self.clients_players
        @clients_players
    end

    def self.player_playing
        @player_playing
    end

    def self.clients_player_playing_index
        @clients_player_playing_index
    end

    def self.board
        @board
    end

    def self.clients_board
        @clients_board
    end

    def self.game_history
        @game_history
    end

    def self.turn
        @turn
    end

    def self.online_mode
        @online_mode
    end

    Contract None => String
    def self.get_player_playings_name
        return @player_playing.to_s
    end

    Contract None => Bool
    def self.human_player_playing?
        return @player_playing.is_a? LocalRealPlayer
    end

    Contract None => Bool
    def self.ai_player_playing?
        return @player_playing.is_a? LocalAIPlayer
    end

    def self.remote_player_playing?
        return @player_playing.is_a? RemotePlayer
    end

    Contract None => Bool
    def self.game_started?
        @game_started
    end

    def self.get_player_names
        player_list = []
        for p in @players
            player_list.push(p.name)
        end
        return player_list
    end

    def self.hosting?
        return @server.hosting?
    end

    def self.send_and_get_move_from_server(column_num)
        return @server.send_and_get_move(column_num)
    end

    def self.get_server
        return @server
    end

    def self.player_id
        return @player_id
    end
    def self.player_id=(arg)
        @player_id = arg
    end

    def self.add_remote_player()
        player_name = @names.pop
        player_pattern = @patterns.pop
        puts "adding player #{player_name}"
        re = RemoteRealPlayer.new(player_name, player_pattern)
        for obj in @observer_views
            re.add_observer(obj)
        end
        @players.push(re)

        for i in 2..@game.num_of_players
            if player_id == i
                re = LocalRealPlayer.new(player_name, player_pattern)
                @clients_players[i].push(re)
            else
                re = RemoteRealPlayer.new(player_name, player_pattern)
                @clients_players[i].push(re)
            end
        end
    end

    def self.create_hosted_game(game) # No AIs, atm
        c = self.new
        for obj in @observer_views
            c.add_observer(obj)
        end
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
            #patterns = [@game.p1_patterns, @game.p2_patterns]
            #names = [@game.p1_piece, @game.p2_piece]
            @patterns = @game.patterns
            @names = @game.pieces
            @server = HostGame.new(@game)
            @server.start_server()
            # for i in 0..(@AI_players-1)
            #     if @players.size < @game.num_of_players and
            #        @players.size <= 2
            #         ai = LocalAIPlayer.new(names[i], patterns[i],
            #                           names[i+1] || names[0], patterns[i+1] || patterns[0])
            #         @player_playing = ai
            #         for obj in @observer_views
            #             ai.add_observer(obj)
            #         end
            #         @players.push(ai)
            #     end
            # end

            player_name = @names.pop
            player_pattern = @patterns.pop
            re = LocalRealPlayer.new(player_name, player_pattern)
            for obj in @observer_views
                re.add_observer(obj)
            end
            #re.add_observer(@server)
            #@server.add_observer(re)
            @players.push(re)

            re = RemoteRealPlayer.new(player_name, player_pattern)
            for i in 2..@game.num_of_players
                @clients_players[i].push(re)
            end
            #@clients_players.push(re)

            while @players.size < @game.num_of_players #2 # number of players
                # puts "waiting... for players"
                sleep(1)
            end
            # puts "got players"

            @board = Board.new(@game.board_width, @game.board_height)
            @clients_board = Board.new(@game.board_width, @game.board_height)
            for obj in @observer_views
                @board.add_observer(obj)
            end

            # http://stackoverflow.com/questions/4395095/how-to-generate-a-random-number-between-a-and-b-in-ruby
            first_players_index = rand(0..(@players.size-1))
            @player_playing = @players[first_players_index]
            @clients_player_playing_index = first_players_index
            puts "(HOST) My players are #{@players}"
            puts "(HOST) size #{@players.size}"
            puts "(HOST) My player playing is #{@player_playing}"
        else
            raise StandardError, "#{gameClazz} not a Game."
        end
        return @game
    end

    Contract String, Maybe[Integer] => Game
    def self.create_game(game, ai_players=0)
        c = self.new
        for obj in @observer_views
            c.add_observer(obj)
        end
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
                re = LocalRealPlayer.new(@names.pop, @patterns.pop)
                for obj in @observer_views
                    re.add_observer(obj)
                end
                @players.push(re)
            end

            @board = Board.new(@game.board_width, @game.board_height)
            for obj in @observer_views
                @board.add_observer(obj)
            end

            if @player_playing == nil
                @player_playing = @players.shuffle[0]
            end
        else
            raise StandardError, "#{gameClazz} not a Game."
        end
        return @game
    end

    Contract Maybe[Nat] => nil
    def self.take_turn(arg)
        if arg == nil
            return arg
        end
        if @player_playing.is_a? LocalAIPlayer
            @player_playing.play(@board)
        elsif @player_playing.is_a? RemoteRealPlayer
            @player_playing.play(@board, @previous_play)
        else
            @board.set_piece(arg, @player_playing.piece)
            if @online_mode
                if self.hosting?
                    @server.send_move(arg)
                else
                    CMDController.get_server.server_handle.call("send_column_played", arg, @turn)
                end
            end
            @previous_play = arg
        end

        if @board.analyze(@player_playing.pattern_array)
            # game over, no need to switch turns
            @player_playing.set_win_status(true)
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
    def self.get_board()
        return @board
    end

    Contract Nat => nil
    def self.set_AIs(count)
        @AI_players = count
        nil
    end

    Contract ArrayOf[String] => nil
    def self.handle_event(commands)
        case commands
        when Array
            if commands[0].respond_to?("to_i") and
              commands[0].to_i.to_s == commands[0] and
              @game_started
                self.take_turn(Integer(commands[0]))
            elsif commands[0].respond_to?("downcase")
                if commands[0].downcase.include? "new" or
                  commands[0].downcase.include? "create"
                    ai_count = Integer(commands[2]) rescue nil
                    begin
                        gameClazz = Object.const_get(commands[1]) # Game
                    rescue NameError => ne
                        raise ne, "#{commands[1]} mode not found."
                    end
                    if gameClazz.superclass == Game
                        self.create_game(commands[1], ai_count)
                        online_mode = false
                    else
                        raise ModeNotSupported,"#{commands[1]} mode not supported."
                    end
                elsif commands[0].downcase.include? "host"
                    # commands[1] = "Connect4"
                    begin
                        gameClazz = Object.const_get(commands[1]) # Game
                    rescue NameError => ne
                        raise ne, "#{commands[1]} mode not found."
                    end
                    if gameClazz.superclass == Game
                        self.create_hosted_game(commands[1])
                        @online_mode = true
                    else
                        raise ModeNotSupported,"#{commands[1]} mode not supported."
                    end
                elsif commands[0].downcase.include? "join"
                    # commands[1] = "Connect4"
                    url = commands[2]
                    port = Integer(commands[3]) rescue nil
                    begin
                        gameClazz = Object.const_get(commands[1]) # Game
                    rescue StandardError
                        raise ModeNotSupported
                    end
                    if gameClazz.superclass == Game
                        @game = gameClazz.new()
                        @server = HostGame.new(@game)
                        @game, @game_started, @players, players_index, @board = @server.join_server()
                        @player_playing = @players[players_index]
                        puts "My players are #{@players}"
                        puts "size #{@players.size}"
                        puts "My player playing is #{@player_playing}"
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


                elsif commands[0].downcase.include? "restart" or
                     commands[0].downcase.include? "reset"
                    @players = []
                    @board = nil
                    @player_playing = nil
                    @game_started = false
                    @server.close_server()
                elsif commands[0].downcase.include? "ai"
                    self.take_turn(0)
                elsif commands[0].downcase.include? "remote"
                    self.take_turn(0)
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
