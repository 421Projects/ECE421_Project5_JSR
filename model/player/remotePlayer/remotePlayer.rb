require "contracts"
require 'observer'
require_relative "../player"

class RemotePlayer < Player

    include Contracts::Core
    include Contracts::Builtin
    include Contracts::Invariants


    @move_made = -1
    def get_move
        if CMDController.instance.hosting?
            return CMDController.instance.get_server.get_move
        else
            return CMDController.instance.get_server.server_handle.call("get_column_played", CMDController.instance.turn)
        end
    end

    def send_move(column_num)
        if CMDController.instance.hosting?
            CMDController.instance.get_server.send_move(column_num)
        else
            puts "Gone where you didnt think!!!"
            CMDController.instance.get_server.server_handle.call("send_column_played", column_num, CMDController.instance.turn)
        end
        true
    end
end
