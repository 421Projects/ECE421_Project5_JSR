require "contracts"
require 'observer'
require_relative "../player"

class RemotePlayer < Player

    include Contracts::Core
    include Contracts::Builtin
    include Contracts::Invariants


    @move_made = -1
    def get_move(arg)
        if CMDController.hosting?
            return CMDController.get_server.get_move
        else
            return CMDController.get_server.server_handle.call("get_column_played", CMDController.turn)
        end
    end

    def send_move(column_num)
        if CMDController.hosting?
            CMDController.get_server.send_move(column_num)
        else
            puts "Gone where you didnt think!!!"
            CMDController.get_server.server_handle.call("send_column_played", column_num, CMDController.turn)
        end
        true
    end
end
