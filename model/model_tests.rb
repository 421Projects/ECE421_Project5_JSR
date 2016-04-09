require "test/unit"
require_relative "player/player"
require_relative "player/localPlayer/local_ai_player"
require_relative "player/localPlayer/local_real_player"
require_relative "board"
require_relative "mysql_adapter"
require_relative "game/game"
require_relative "game/connect4"
require_relative "game/otto_toot"
require_relative "local_file_storage"

class Connect4ModelTest < Test::Unit::TestCase

    def test_player_board_connect4Mode

        game = Connect4.new()

        p1 = Player.new(game.p1_piece, game.p1_patterns)
        p2 = Player.new(game.p2_piece, game.p2_patterns)

        b = Board.new(game.board_width, game.board_height)
        b.set_piece(1, p1.piece)
        assert_equal(b.piece_count, 1)
        b.set_piece(1, p1.piece)
        assert_equal(b.piece_count, 2)
        b.set_piece(1, p1.piece)
        assert_equal(b.piece_count, 3)
        b.set_piece(1, p1.piece)
        assert_equal(b.piece_count, 4)

        assert_equal(b.analyze(p1.pattern_array), true,
                     "Didn't detect win.")
        assert_equal(b.analyze(p2.pattern_array), false,
                     "Wrongly calculated the game to be won.")

        b = Board.new(game.board_width, game.board_height)
        b.set_piece(1, p2.piece)
        assert_equal(b.piece_count, 1)
        b.set_piece(1, p2.piece)
        assert_equal(b.piece_count, 2)
        b.set_piece(1, p2.piece)
        assert_equal(b.piece_count, 3)
        b.set_piece(1, p2.piece)
        assert_equal(b.piece_count, 4)

        assert_equal(b.analyze(p1.pattern_array), false,
                     "Wrongly calculated the game to be won.")
        assert_equal(b.analyze(p2.pattern_array), true,
                     "Didn't detect win.")

        b = Board.new(game.board_width, game.board_height)
        b.set_piece(1, p1.piece)
        assert_equal(b.piece_count, 1)
        b.set_piece(2, p1.piece)
        assert_equal(b.piece_count, 2)
        b.set_piece(3, p1.piece)
        assert_equal(b.piece_count, 3)
        b.set_piece(4, p1.piece)
        assert_equal(b.piece_count, 4)

        assert_equal(b.analyze(p1.pattern_array), true,
                     "Didn't detect win.")
        assert_equal(b.analyze(p2.pattern_array), false,
                     "Wrongly calculated the game to be won.")

        b = Board.new(game.board_width, game.board_height)
        b.set_piece(1, p2.piece)
        assert_equal(b.piece_count, 1)
        b.set_piece(2, p2.piece)
        assert_equal(b.piece_count, 2)
        b.set_piece(3, p2.piece)
        assert_equal(b.piece_count, 3)
        b.set_piece(4, p2.piece)
        assert_equal(b.piece_count, 4)

        assert_equal(b.analyze(p1.pattern_array), false,
                     "Wrongly calculated the game to be won.")
        assert_equal(b.analyze(p2.pattern_array), true,
                     "Didn't detect win.")


        # Test diagonal win (/) for BlackPiece
        b = Board.new(game.board_width, game.board_height)
        b.set_piece(1, p1.piece)
        assert_equal(b.piece_count, 1)

        b.set_piece(2, p2.piece)
        assert_equal(b.piece_count, 2)
        b.set_piece(2, p1.piece)
        assert_equal(b.piece_count, 3)

        b.set_piece(3, p2.piece)
        assert_equal(b.piece_count, 4)
        b.set_piece(3, p2.piece)
        assert_equal(b.piece_count, 5)
        b.set_piece(3, p1.piece)
        assert_equal(b.piece_count, 6)

        b.set_piece(4, p2.piece)
        assert_equal(b.piece_count, 7)
        b.set_piece(4, p2.piece)
        assert_equal(b.piece_count, 8)
        b.set_piece(4, p2.piece)
        assert_equal(b.piece_count, 9)
        b.set_piece(4, p1.piece)
        assert_equal(b.piece_count, 10)

        assert_equal(b.analyze(p1.pattern_array), true,
                     "Didn't detect win.")
        assert_equal(b.analyze(p2.pattern_array), false,
                     "Wrongly calculated the game to be won.")

        # Test diagonal win (\) for BlackPiece
        b = Board.new(game.board_width, game.board_height)
        b.set_piece(1, p2.piece)
        assert_equal(b.piece_count, 1)
        b.set_piece(1, p2.piece)
        assert_equal(b.piece_count, 2)
        b.set_piece(1, p2.piece)
        assert_equal(b.piece_count, 3)
        b.set_piece(1, p1.piece)
        assert_equal(b.piece_count, 4)

        b.set_piece(2, p2.piece)
        assert_equal(b.piece_count, 5)
        b.set_piece(2, p2.piece)
        assert_equal(b.piece_count, 6)
        b.set_piece(2, p1.piece)
        assert_equal(b.piece_count, 7)

        b.set_piece(3, p2.piece)
        assert_equal(b.piece_count, 8)
        b.set_piece(3, p1.piece)
        assert_equal(b.piece_count, 9)

        b.set_piece(4, p1.piece)
        assert_equal(b.piece_count, 10)

        assert_equal(b.analyze(p1.pattern_array), true,
                     "Didn't detect win.")
        assert_equal(b.analyze(p2.pattern_array), false,
                     "Wrongly calculated the game to be won.")

        # Test diagonal win (/) for RedPiece
        b = Board.new(game.board_width, game.board_height)
        b.set_piece(1, p2.piece)
        assert_equal(b.piece_count, 1)

        b.set_piece(2, p1.piece)
        assert_equal(b.piece_count, 2)
        b.set_piece(2, p2.piece)
        assert_equal(b.piece_count, 3)

        b.set_piece(3, p1.piece)
        assert_equal(b.piece_count, 4)
        b.set_piece(3, p1.piece)
        assert_equal(b.piece_count, 5)
        b.set_piece(3, p2.piece)
        assert_equal(b.piece_count, 6)

        b.set_piece(4, p1.piece)
        assert_equal(b.piece_count, 7)
        b.set_piece(4, p1.piece)
        assert_equal(b.piece_count, 8)
        b.set_piece(4, p1.piece)
        assert_equal(b.piece_count, 9)
        b.set_piece(4, p2.piece)
        assert_equal(b.piece_count, 10)

        assert_equal(b.analyze(p2.pattern_array), true,
                     "Didn't detect win.")
        assert_equal(b.analyze(p1.pattern_array), false,
                     "Wrongly calculated the game to be won.")

        # Test diagonal win (\) for RedPiece
        b = Board.new(game.board_width, game.board_height)
        b.set_piece(1, p1.piece)
        assert_equal(b.piece_count, 1)
        b.set_piece(1, p1.piece)
        assert_equal(b.piece_count, 2)
        b.set_piece(1, p1.piece)
        assert_equal(b.piece_count, 3)
        b.set_piece(1, p2.piece)
        assert_equal(b.piece_count, 4)

        b.set_piece(2, p1.piece)
        assert_equal(b.piece_count, 5)
        b.set_piece(2, p1.piece)
        assert_equal(b.piece_count, 6)
        b.set_piece(2, p2.piece)
        assert_equal(b.piece_count, 7)

        b.set_piece(3, p1.piece)
        assert_equal(b.piece_count, 8)
        b.set_piece(3, p2.piece)
        assert_equal(b.piece_count, 9)

        b.set_piece(4, p2.piece)
        assert_equal(b.piece_count, 10)

        assert_equal(b.analyze(p2.pattern_array), true,
                     "Didn't detect win.")
        assert_equal(b.analyze(p1.pattern_array), false,
                     "Wrongly calculated the game to be won.")
    end

    def test_player_board_otto_toot_mode

        game = OttoToot.new()

        p1 = Player.new(game.p1_piece, game.p1_patterns) # Wins with OTTO
        p2 = Player.new(game.p2_piece, game.p2_patterns) # Wins with TOOT

        b = Board.new(game.board_width, game.board_height)
        b.set_piece(1, p1.piece)
        assert_equal(b.piece_count, 1)
        b.set_piece(1, p2.piece)
        assert_equal(b.piece_count, 2)
        b.set_piece(1, p2.piece)
        assert_equal(b.piece_count, 3)
        b.set_piece(1, p1.piece)
        assert_equal(b.piece_count, 4)

        assert_equal(b.analyze(p1.pattern_array), true,
                     "Didn't detect win.")
        assert_equal(b.analyze(p2.pattern_array), false,
                     "Wrongly calculated the game to be won.")

        b = Board.new(game.board_width, game.board_height)
        b.set_piece(1, p2.piece)
        assert_equal(b.piece_count, 1)
        b.set_piece(1, p1.piece)
        assert_equal(b.piece_count, 2)
        b.set_piece(1, p1.piece)
        assert_equal(b.piece_count, 3)
        b.set_piece(1, p2.piece)
        assert_equal(b.piece_count, 4)

        assert_equal(b.analyze(p1.pattern_array), false,
                     "Wrongly calculated the game to be won.")
        assert_equal(b.analyze(p2.pattern_array), true,
                     "Didn't detect win.")

        b = Board.new(game.board_width, game.board_height)
        b.set_piece(1, p1.piece)
        assert_equal(b.piece_count, 1)
        b.set_piece(2, p2.piece)
        assert_equal(b.piece_count, 2)
        b.set_piece(3, p2.piece)
        assert_equal(b.piece_count, 3)
        b.set_piece(4, p1.piece)
        assert_equal(b.piece_count, 4)

        assert_equal(b.analyze(p1.pattern_array), true,
                     "Didn't detect win.")
        assert_equal(b.analyze(p2.pattern_array), false,
                     "Wrongly calculated the game to be won.")

        b = Board.new(game.board_width, game.board_height)
        b.set_piece(1, p2.piece)
        assert_equal(b.piece_count, 1)
        b.set_piece(2, p1.piece)
        assert_equal(b.piece_count, 2)
        b.set_piece(3, p1.piece)
        assert_equal(b.piece_count, 3)
        b.set_piece(4, p2.piece)
        assert_equal(b.piece_count, 4)

        assert_equal(b.analyze(p1.pattern_array), false,
                     "Wrongly calculated the game to be won.")
        assert_equal(b.analyze(p2.pattern_array), true,
                     "Didn't detect win.")


        # Test diagonal win (/) for p1 piece
        b = Board.new(game.board_width, game.board_height)
        b.set_piece(1, p1.piece)
        assert_equal(b.piece_count, 1)

        b.set_piece(2, p2.piece)
        assert_equal(b.piece_count, 2)
        b.set_piece(2, p2.piece)
        assert_equal(b.piece_count, 3)

        b.set_piece(3, p2.piece)
        assert_equal(b.piece_count, 4)
        b.set_piece(3, p2.piece)
        assert_equal(b.piece_count, 5)
        b.set_piece(3, p2.piece)
        assert_equal(b.piece_count, 6)

        b.set_piece(4, p2.piece)
        assert_equal(b.piece_count, 7)
        b.set_piece(4, p2.piece)
        assert_equal(b.piece_count, 8)
        b.set_piece(4, p2.piece)
        assert_equal(b.piece_count, 9)
        b.set_piece(4, p1.piece)
        assert_equal(b.piece_count, 10)

        assert_equal(b.analyze(p1.pattern_array), true,
                     "Didn't detect win.")
        assert_equal(b.analyze(p2.pattern_array), false,
                     "Wrongly calculated the game to be won.")

        # Test diagonal win (\) for p1 piece
        b = Board.new(game.board_width, game.board_height)
        b.set_piece(1, p1.piece)
        assert_equal(b.piece_count, 1)
        b.set_piece(1, p2.piece)
        assert_equal(b.piece_count, 2)
        b.set_piece(1, p2.piece)
        assert_equal(b.piece_count, 3)
        b.set_piece(1, p1.piece)
        assert_equal(b.piece_count, 4)

        b.set_piece(2, p2.piece)
        assert_equal(b.piece_count, 5)
        b.set_piece(2, p2.piece)
        assert_equal(b.piece_count, 6)
        b.set_piece(2, p2.piece)
        assert_equal(b.piece_count, 7)

        b.set_piece(3, p2.piece)
        assert_equal(b.piece_count, 8)
        b.set_piece(3, p2.piece)
        assert_equal(b.piece_count, 9)

        b.set_piece(4, p1.piece)
        assert_equal(b.piece_count, 10)

        assert_equal(b.analyze(p1.pattern_array), true,
                     "Didn't detect win.")
        assert_equal(b.analyze(p2.pattern_array), false,
                     "Wrongly calculated the game to be won.")

        # Test diagonal win (/) for p2 piece
        b = Board.new(game.board_width, game.board_height)
        b.set_piece(1, p2.piece)
        assert_equal(b.piece_count, 1)

        b.set_piece(2, p1.piece)
        assert_equal(b.piece_count, 2)
        b.set_piece(2, p1.piece)
        assert_equal(b.piece_count, 3)

        b.set_piece(3, p1.piece)
        assert_equal(b.piece_count, 4)
        b.set_piece(3, p1.piece)
        assert_equal(b.piece_count, 5)
        b.set_piece(3, p1.piece)
        assert_equal(b.piece_count, 6)

        b.set_piece(4, p1.piece)
        assert_equal(b.piece_count, 7)
        b.set_piece(4, p1.piece)
        assert_equal(b.piece_count, 8)
        b.set_piece(4, p1.piece)
        assert_equal(b.piece_count, 9)
        b.set_piece(4, p2.piece)
        assert_equal(b.piece_count, 10)

        assert_equal(b.analyze(p2.pattern_array), true,
                     "Didn't detect win.")
        assert_equal(b.analyze(p1.pattern_array), false,
                     "Wrongly calculated the game to be won.")

        # Test diagonal win (\) for p2 piece
        b = Board.new(game.board_width, game.board_height)
        b.set_piece(1, p1.piece)
        assert_equal(b.piece_count, 1)
        b.set_piece(1, p1.piece)
        assert_equal(b.piece_count, 2)
        b.set_piece(1, p1.piece)
        assert_equal(b.piece_count, 3)
        b.set_piece(1, p2.piece)
        assert_equal(b.piece_count, 4)

        b.set_piece(2, p1.piece)
        assert_equal(b.piece_count, 5)
        b.set_piece(2, p1.piece)
        assert_equal(b.piece_count, 6)
        b.set_piece(2, p1.piece)
        assert_equal(b.piece_count, 7)

        b.set_piece(3, p1.piece)
        assert_equal(b.piece_count, 8)
        b.set_piece(3, p1.piece)
        assert_equal(b.piece_count, 9)

        b.set_piece(4, p2.piece)
        assert_equal(b.piece_count, 10)

        assert_equal(b.analyze(p2.pattern_array), true,
                     "Didn't detect win.")
        assert_equal(b.analyze(p1.pattern_array), false,
                     "Wrongly calculated the game to be won.")
    end

    def test_ai_score_of_pattern
        game = Connect4.new()

        b = Board.new(game.board_width, game.board_height)

        pattern = {}
        pattern[[0, 0]] = game.p1_piece
        pattern[[0, 1]] = game.p1_piece
        pattern[[0, 2]] = game.p1_piece
        pattern[[0, 3]] = game.p1_piece

        p1 = LocalAIPlayer.new(game.p1_piece, game.p1_patterns, game.p2_piece, game.p2_patterns)

        b.set_piece(3, game.p1_piece)
        assert_equal(4, p1.score_of_pattern(pattern, b))

        b.set_piece(2, game.p1_piece)
        assert_equal(31, p1.score_of_pattern(pattern, b))
    end

    def test_ai_score_of_board
        game = Connect4.new()

        b = Board.new(game.board_width, game.board_height)

        p1 = LocalAIPlayer.new(game.p1_piece, game.p1_patterns, game.p2_piece, game.p2_patterns)

        b.set_piece(0, game.p1_piece)
        assert_equal(3, p1.score_of_board(b, game.p1_patterns))

        b.set_piece(0, game.p1_piece)
        assert_equal(15, p1.score_of_board(b, game.p1_patterns))

        b.set_piece(0, game.p1_piece)
        assert_equal(117, p1.score_of_board(b, game.p1_patterns)) # (100+10+1) + (1+1+1) + (1+1+1) + 0

        b.set_piece(0, game.p1_piece)
        assert_equal(1118, p1.score_of_board(b, game.p1_patterns)) # (1000+100+10+1) + (1+1+1+1) + (1+1+1+1) + (1)

        b = Board.new(game.board_width, game.board_height)
        b.set_piece(3, game.p1_piece)
        assert_equal(7, p1.score_of_board(b, game.p1_patterns)) # (1) + (1+1+1+1) + (1) + (1)

        b.set_piece(3, game.p1_piece)
        assert_equal(25, p1.score_of_board(b, game.p1_patterns)) # (10 + 1) + (1+1+1+1 + 1+1+1+1) + (1+1+1) + (1+1+1)

        b.set_piece(3, game.p1_piece)
        assert_equal(135, p1.score_of_board(b, game.p1_patterns)) # (100+10+1) + (1+1+1+1 + 1+1+1+1 + 1+1+1+1) + (1+1+1+1+1) + (1+1+1+1+1)

        b.set_piece(3, game.p1_piece)
        assert_equal(1144, p1.score_of_board(b, game.p1_patterns)) # (1000+100+10+1) + (1+1+1+1 + 1+1+1+1 + 1+1+1+1 + 1+1+1+1) + (1+1+1+1) + (1+1+1+1)
    end

    def test_ai_heuristic
        game = Connect4.new()

        b = Board.new(game.board_width, game.board_height)

        p1 = LocalAIPlayer.new(game.p1_piece, game.p1_patterns, game.p2_piece, game.p2_patterns)

        pattern1 = {}
        pattern1[[0, 0]] = game.p1_piece
        pattern1[[0, 1]] = game.p1_piece
        pattern1[[0, 2]] = game.p1_piece
        pattern1[[0, 3]] = game.p1_piece

        pattern2 = {}
        pattern2[[0, 0]] = game.p1_piece
        pattern2[[1, 0]] = game.p1_piece
        pattern2[[2, 0]] = game.p1_piece
        pattern2[[3, 0]] = game.p1_piece

        assert_equal(0, p1.heuristic(pattern1, b, 0, 0))

        b.set_piece(0, game.p1_piece)
        assert_equal(1, p1.heuristic(pattern1, b, 0, 0))

        b.set_piece(0, game.p1_piece)
        assert_equal(1, p1.heuristic(pattern1, b, 0, 0))
        assert_equal(10, p1.heuristic(pattern2, b, 0, 0))

        b.set_piece(0, game.p1_piece)
        assert_equal(1, p1.heuristic(pattern1, b, 0, 0))
        assert_equal(100, p1.heuristic(pattern2, b, 0, 0))

        b.set_piece(0, game.p1_piece)
        assert_equal(1, p1.heuristic(pattern1, b, 0, 0))
        assert_equal(1000, p1.heuristic(pattern2, b, 0, 0))
    end

    def test_ai_basic_play

        game = Connect4.new()

        p1 = LocalAIPlayer.new(game.p1_piece, game.p1_patterns, game.p2_piece, game.p2_patterns, 1)

        b = Board.new(game.board_width, game.board_height)
        assert_equal(b.piece_count, 0)

        p1.play(b)
        assert_equal(b.piece_count, 1)

        p1.play(b)
        assert_equal(b.piece_count, 2)

        p1.play(b)
        assert_equal(b.piece_count, 3)

        p1.play(b)
        assert_equal(b.piece_count, 4)

        assert_equal(b.analyze(p1.pattern_array), true,
                     "Didn't detect win.")

    end

    def test_ai_tough_play
        game = Connect4.new()

        p1 = LocalAIPlayer.new(game.p1_piece, game.p1_patterns, game.p2_piece, game.p2_patterns, 3)
        p2 = LocalAIPlayer.new(game.p2_piece, game.p2_patterns, game.p1_piece, game.p1_patterns, 3)

        b = Board.new(game.board_width, game.board_height)
        b.set_piece(3, game.p2_piece)
        b.set_piece(3, game.p2_piece)
        b.set_piece(3, game.p2_piece)
        p1.play(b)
        b.set_piece(3, game.p2_piece)

        assert_equal(false, b.analyze(p2.pattern_array),
                     "AI didn't stop player from winning.")
    end

    def test_game_constructor
        assert_raise NotImplementedError do
            thrown = Game.new
        end
    end


    def check_stats_for_player(msa, player, asserted_stats=[0,0,0,0],
                               error_message="Default values incorrect.")
        wins, losses, ties, points = [
            msa.get_wins_for_player(player),
            msa.get_losses_for_player(player),
            msa.get_ties_for_player(player),
            msa.get_points_for_player(player)
        ]
        stats = [wins, losses, ties, points]

        assert_equal(stats, asserted_stats,
                     error_message)
    end

    def test_mysql_adapter_basic_flow()
        msa = MySQLAdapter.new

        assert(msa != nil)

        test_user = "test_user"

        begin
            msa.add_player(test_user)
            check_stats_for_player(msa, test_user)

            msa.add_win_for_player(test_user)
            check_stats_for_player(msa, test_user, [1,0,0,2],
                                   "Win not recoreded properly.")

            msa.add_loss_for_player(test_user)
            check_stats_for_player(msa, test_user, [1,1,0,2],
                                   "Loss not recoreded properly.")

            msa.add_tie_for_player(test_user)
            check_stats_for_player(msa, test_user, [1,1,1,3],
                                   "Tie not recoreded properly.")

            wins = 1
            losses = 1
            ties = 1
            points = 3

            iterations = rand(5..10)
            for i in 1..iterations
                msa.add_win_for_player(test_user)
                wins += 1
                points += 2
                check_stats_for_player(msa, test_user, [wins,losses,ties,points],
                                       "Win not recoreded properly.")
            end

            iterations = rand(5..10)
            for i in 1..iterations
                msa.add_loss_for_player(test_user)
                losses += 1
                check_stats_for_player(msa, test_user, [wins,losses,ties,points],
                                       "Loss not recoreded properly.")
            end

            iterations = rand(5..10)
            for i in 1..iterations
                msa.add_tie_for_player(test_user)
                ties += 1
                points += 1
                check_stats_for_player(msa, test_user, [wins,losses,ties,points],
                                       "Tie not recoreded properly.")
            end

            msa.delete_player(test_user)
            assert_raise do
                check_stats_for_player(msa, test_user, [-1,-1,-1,-1],
                                       "Player not properly deleted.")
            end

        rescue MySQLAdapter::NotConnected => nc
            puts nc.message
            puts "Not testing mysql."
        end
    end

    def test_mysql_adapter_exception_flow()
        msa = MySQLAdapter.new

        assert(msa != nil)

        test_user = "test_user"
        begin
            msa.add_player(test_user)
            check_stats_for_player(msa, test_user)

            assert_raise do
                msa.add_player(test_user)
            end

            msa.delete_player(test_user)

            assert_raise do
                msa.delete_player(test_user)
            end

            assert_raise do
                msa.get_wins_for_player(msa,name)
            end
            assert_raise do
                msa.get_losses_for_player(msa,name)
            end
            assert_raise do
                msa.get_ties_for_player(msa,name)
            end
            assert_raise do
                msa.get_points_for_player(msa,name)
            end
        rescue MySQLAdapter::NotConnected => nc
            puts nc.message
            puts "Not testing mysql."
        end

    end

    def test_local_file_storage
        lfs = LocalFileStorage.new
        game = Connect4.new()

        p1 = LocalAIPlayer.new(game.p1_piece, game.p1_patterns, game.p2_piece, game.p2_patterns)
        p2 = LocalRealPlayer.new(game.p2_piece, game.p2_patterns)

        players = [p1,p2]

        b = Board.new(game.board_width, game.board_height)

        game_state = {
            "game" => game,
            "game_started" =>true,
            "players" => players,
            "player_playing_index" => 0,
            "board" => b,
            "turn" => 0
        }

        lfs.save("test_game", game_state)
        attributes = lfs.load("test_game")
        assert_equal(attributes["board"].piece_count, 0)
        assert_equal(attributes["turn"], 0)
        assert_equal(attributes["player_playing_index"], 0)

        b.set_piece(3, p1.piece)
        b.set_piece(3, p2.piece)
        assert_equal(b.piece_count, 2)
        game_state = {
            "game" => game,
            "game_started" =>true,
            "players" => players,
            "player_playing_index" => 0,
            "board" => b,
            "turn" => 3
        }

        lfs.save("test_game", game_state)
        attributes = lfs.load("test_game")
        assert_equal(attributes["board"].piece_count, 2)
        assert_equal(attributes["turn"], 3)
        assert_equal(attributes["player_playing_index"], 0)

        lfs.delete("test_game")

        attributes = lfs.load("test_game")
        assert_equal(attributes, nil)

    end

    # def test_basic_remote_play
    #     game = Connect4.new()

    #     hg = HostGame.new(game, 8080)
    #     hg.start_server

    #     p1 = RemoteAIPlayer.new(hg, game.p1_piece, game.p1_patterns, game.p2_piece, game.p2_patterns, 1)

    #     b = Board.new(game.board_width, game.board_height)
    #     assert_equal(b.piece_count, 0)

    #     p1.play(b)
    #     assert_equal(b.piece_count, 1)

    #     p1.play(b)
    #     assert_equal(b.piece_count, 2)

    #     p1.play(b)
    #     assert_equal(b.piece_count, 3)

    #     p1.play(b)
    #     assert_equal(b.piece_count, 4)

    #     assert_equal(b.analyze(p1.pattern_array), true,
    #                  "Didn't detect win.")
    # end

    # def test_basic_remote_play2
    #     game = Connect4.new()

    #     hg = HostGame.new(game, 8080)
    #     hg.start_server

    #     p1 = RemoteAIPlayer.new(hg, game.p1_piece, game.p1_patterns, game.p2_piece, game.p2_patterns, 1)

    #     b = Board.new(game.board_width, game.board_height)
    #     assert_equal(b.piece_count, 0)

    #     p1.play(b)
    #     assert_equal(b.piece_count, 1)

    #     assert_equal(b.analyze(p1.pattern_array), false,
    #                  "Detected wrongful win.")

    #     hg.close_server

    #     assert_raise do
    #         # server is closed
    #         p1.play(b)
    #     end

    #     assert_equal(b.piece_count, 1)
    # end


end
