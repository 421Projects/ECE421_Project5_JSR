require_relative "./remotePlayer"

class RemoteRealPlayer < RemotePlayer
    #Contract Board => nil
    def play(board_to_play, arg)
        move = get_move(arg)
        board_to_play.set_piece(move, self.piece)
        nil
    end
end
