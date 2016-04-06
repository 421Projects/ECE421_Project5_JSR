require_relative "../controller/commandline_controller"
require 'contracts'
require 'observer'

class CommandLineView

    include Contracts::Core
    include Contracts::Builtin
    include Contracts::Invariants

    Contract None => nil
    def initialize()
        @running = true
        return nil
    end

    Contract None => nil
    def start_game()
        CMDController.instance.observer_views.push(self)
        CMDController.instance.add_observer(self)
        puts "Mode files loaded are:"
        puts CMDController.instance.modes_loaded


        puts "--------------------------------------------"
        puts "What is the player's name?"
        # http://stackoverflow.com/questions/6085518/what-is-the-easiest-way-to-push-an-element-to-the-beginning-of-the-array
        parse_command(get_command().unshift("name"))

        while (@running)
            if CMDController.instance.game_started
                puts "running"
                if CMDController.instance.human_player_playing?
                    puts "#{eval('CMDController.instance.get_player_playings_name')} Next Piece?> "
                    parse_command(get_command())
                elsif CMDController.instance.ai_player_playing?
                    t = Thread.new {
                        CMDController.instance.handle_event(["ai_move"])
                    }
                    print "AI #{CMDController.instance.get_player_playings_name} Thinking"
                    print "." until t.join(0.25)
                    STDOUT.flush
                elsif CMDController.instance.remote_player_playing?
                    puts "remote move"
                    t = Thread.new {
                        CMDController.instance.handle_event(["remote_move"])
                    }
                    print "Remote Player #{CMDController.instance.get_player_playings_name} Thinking"
                    print "." until t.join(0.25)
                    STDOUT.flush
                else
                    puts "We got nothing! #{CMDController.instance.player_playing}"
                    puts "We got nothing! #{CMDController.instance.players}"
                    sleep(1)
                end
            else
                puts "Prompt> "
                parse_command(get_command())
            end

        end
        puts "GoodBye!"
        nil
    end

    Contract None => ArrayOf[String]
    def get_command()
        return gets.chomp.split
    end

    #Contract Or[Player, Board, Game] => nil
    def update(arg)
        if arg.is_a? Player
            puts "#{arg.to_s} has won!"
            #eval("CMDController.instance.handle_event(['reset'])")
            CMDController.instance.handle_event(['reset'])
        elsif arg.is_a? Board
            self.pretty_print(arg)
        elsif arg.is_a? String and arg.include? "Message"
            puts (arg)
        elsif arg.is_a? String and arg.include? "name"
            puts "What is the player's name?"
            # http://stackoverflow.com/questions/6085518/what-is-the-easiest-way-to-push-an-element-to-the-beginning-of-the-array
            parse_command(get_command().unshift("name"))
        else
            puts "#{arg} not recognized."
        end
        nil
    end

    Contract ArrayOf[String] => nil
    def parse_command(user_input)
        # http://stackoverflow.com/questions/8258517/how-to-check-whether-a-string-contains-a-substring-in-ruby
        if user_input == nil or user_input[0] == nil
            return
        elsif user_input[0].downcase.include? "help"
            puts "help: list these help options\n" +
                 "new: start new game. Ex. new <mode name>\n " +
                 "restart: restart game \n" +
                 "modes: list modes\n"
        elsif user_input[0].downcase.include? "mode"
            puts "Mode files loaded are:"
            puts CMDController.instance.get_mode_files_loaded
        elsif user_input[0].downcase.include? "exit" or
             user_input[0].downcase.include? "quit"
            @running = false
        else
            if user_input[0].downcase.include? "new" or
              user_input[0].downcase.include? "create"
                puts "how many AIs? (maximum of 2 supported)"
                user_input << gets.chomp
            end
            #            begin
            if (user_input[0].downcase.include? "join")
                t = Thread.new {
                    CMDController.instance.handle_event(user_input)
                }
                print "Waiting for game to start"
                print "." until t.join(0.25)
                STDOUT.flush
            else
                CMDController.instance.handle_event(user_input)
            end
            #            rescue StandardError => se
            #                 puts se.message
            #                 puts "Do you want try again? (y/n)"
            #                 response = gets.chomp.split
            #                 if response[0].downcase.include? "y"
            #                     puts "Trying again..."
            #                     return
            #                 else
            #                     puts "Quiting..."
            #                     @running = false
            #                 end
            #             end
        end
        nil
    end

    Contract Board => nil
    def pretty_print(board)
        puts board.board
        board_pic = ""
        for r in (board.height-1).downto(0)
            for c in 0..(board.width-1)
                # board_pic += "(#{r},#{c})[#{board.get_player_on_pos(r,c).piece}], "
                board_pic += "[#{board.board[[r,c]]}], "
            end
            board_pic += "\n"
        end
        puts board_pic
        nil
    end
end
# http://stackoverflow.com/questions/2249310/if-name-main-equivalent-in-ruby
if __FILE__ == $0
    c = CommandLineView.new
    c.start_game()
end
