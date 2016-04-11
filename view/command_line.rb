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
                if CMDController.instance.human_player_playing?
                    puts "#{eval('CMDController.instance.get_player_playings_name')} Next Piece?> "
                    parse_command(get_command())
                elsif CMDController.instance.ai_player_playing?
                    t = Thread.new {
                        CMDController.instance.handle_event(["ai_move"])
                    }
                    # print "AI #{CMDController.instance.get_player_playings_name} Thinking"
                    # print "Remote Player #{CMDController.instance.get_player_playings_name} Thinking"
                    puts "AI #{CMDController.instance.get_player_playings_name} Thinking"
                    until t.join(0.10) do
                        print "."
                        sleep(0.2)
                        print "."
                        sleep(0.2)
                        print "."
                        sleep(0.2)
                        print "\r   \r"
                    end
                    STDOUT.flush
                elsif CMDController.instance.remote_player_playing?
                    puts "remote move"
                    t = Thread.new {
                        CMDController.instance.handle_event(["remote_move"])
                    }
                    puts "Remote Player #{CMDController.instance.get_player_playings_name} Thinking"
                    until t.join(0.80) do
                        print "."
                        sleep(0.2)
                        print "."
                        sleep(0.2)
                        print "."
                        sleep(0.2)
                        print "\r   \r"
                    end
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
            # CMDController.instance.handle_event(['record_winner', arg.to_s])
            CMDController.instance.handle_event(['reset', arg.to_s])
        elsif arg.is_a? Board
            self.pretty_print(arg)
        elsif arg.is_a? String and arg.include? "Message"
            puts (arg)
        elsif arg.is_a? String and arg.include? "name"
            puts "What is the player's name?"
            # http://stackoverflow.com/questions/6085518/what-is-the-easiest-way-to-push-an-element-to-the-beginning-of-the-array
            parse_command(get_command().unshift("name"))
        elsif arg.is_a? String and arg.include? "continue"
            puts "Saved game found. Continue saved game? (y/n)"
            # http://stackoverflow.com/questions/6085518/what-is-the-easiest-way-to-push-an-element-to-the-beginning-of-the-array
            parse_command(get_command().unshift("name"))
        elsif arg.is_a? String and arg.include? "tied"
            puts "Game Tied!"
            CMDController.instance.handle_event(['reset', 'tie'])
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
                 "new: start new game. Ex. new <mode name>\n" +
                 "restart: restart game \n" +
                 "modes: list modes\n" +
                 "host: host a new game. Ex. host <mode name> <ip> <port> \n" +
                 "join: join a hosted game. Ex. join <mode name> <ip> <port>\n"
        elsif user_input[0].downcase.include? "mode"
            puts "Mode files loaded are:"
            puts CMDController.instance.modes_loaded
        elsif user_input[0].downcase.include? "exit" or
             user_input[0].downcase.include? "quit"
            @running = false
        elsif user_input[0].downcase.include? "print"
            table = CMDController.instance.get_hs_table
            if table == nil
                puts "MySql not connected."
            else
                self.pretty_print_table(table)
            end
        else
            if user_input[0].downcase.include? "new" or
              user_input[0].downcase.include? "create"
                puts "how many AIs? (maximum of 2 supported)"
                user_input << gets.chomp
            end
            begin
                if (user_input[0].downcase.include? "join")
                    t = Thread.new {
                        CMDController.instance.handle_event(user_input)
                    }
                    puts "Waiting for game to start"
                    until t.join(0.10) do
                        print "."
                        sleep(0.2)
                        print "."
                        sleep(0.2)
                        print "."
                        sleep(0.2)
                        print "\r   \r"
                    end
                    STDOUT.flush
                else
                    CMDController.instance.handle_event(user_input)
                end
            rescue StandardError => se
                puts se.message
                puts "Do you want try again? (y/n)"
                response = gets.chomp.split
                if response[0].downcase.include? "y"
                    puts "Trying again..."
                    return
                else
                    puts "Quiting..."
                    @running = false
                end
            end
        end
        nil
    end

    Contract Board => nil
    def pretty_print(board)
        puts ""
        board_pic = ""
        for r in (board.height-1).downto(0)
            for c in 0..(board.width-1)
                if board.board[[r,c]] == nil
                    board_pic += "[ ], "
                else
                    board_pic += "[#{board.board[[r,c]]}], "
                end
            end
            board_pic += "\n"
        end
        puts board_pic
        puts ""
        nil
    end

    def pretty_print_table(table)
        # http://stackoverflow.com/questions/1087658/nicely-formatting-output-to-console-specifying-number-of-tabs
        puts ""
        puts "______________________________________________"
        puts "|Name    |Wins    |Losses  |Ties    |Points  |"
        puts "|........|........|........|........|........|"
        for row in table
            puts "|%8s|%8s|%8s|%8s|%8s|" % [row['name'], row['wins'], row['losses'], row['ties'],
                                            row['points']]
        end
        puts "|________|________|________|________|________|"
        puts ""
    end
end
# http://stackoverflow.com/questions/2249310/if-name-main-equivalent-in-ruby
if __FILE__ == $0
    c = CommandLineView.new
    c.start_game()
end
