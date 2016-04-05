require "test/unit"
require_relative "game_controller"
require_relative "commandline_controller"
require_relative "../view/command_line"
require_relative "../model/board"
require_relative "../model/game/connect4"
require_relative "../model/game/otto_toot"

class ControllerTest < Test::Unit::TestCase

    def test_create_game
        game_controller = GameController.new
        game = game_controller.create_game("Connect4")

        assert(game.is_a?(Connect4))

        game_controller = GameController.new
        game = game_controller.create_game("OttoToot")

        assert(game.is_a?(OttoToot))
    end

    def test_place_piece
        game_controller = GameController.new
        game = game_controller.create_game("Connect4")

        piece = Black.new

        game_controller.place_piece(piece, 1)

        board = game_controller.get_board()
        assert_equal(piece, board.get_piece(1, board.height-1))
    end

    def test_create_real_player
        game_controller = GameController.new
        game = game_controller.create_game("Connect4")

        game_controller.create_real_players(1)

        assert_equal(1, game_controller.get_number_of_players)
    end

    def test_create_ai_player
        game_controller = GameController.new
        game = game_controller.create_game("Connect4")

        game_controller.create_ai_players(1)

        assert_equal(1, game_controller.get_number_of_players)
    end

    def test_commandline
        CMDController.instance.initialize([CommandLineView.new])
        create_game_commandline
        handle_event_commandline
    end

    def create_game_commandline
        assert_raise CMDController.instance::ModeNotSupported do
            CMDController.instance.create_game("ModeNotCreated", 1)
        end
        assert_raise CMDController.instance::AICountError do
            CMDController.instance.create_game("Connect4", 3)
        end
        assert_raise CMDController.instance::AICountError do
            CMDController.instance.create_game("Connect4", -1)
        end
    end

    def handle_event_commandline
        assert_raise CMDController.instance::CommandNotSupported do
            CMDController.instance.handle_event(["randomCommand"])
        end
        assert_raise do
            CMDController.instance.handle_event("randomCommand")
        end
        assert_raise do
            CMDController.instance.handle_event(1)
        end
    end

end
