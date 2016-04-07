require_relative "./remotePlayer"

class RemoteRealPlayer < RemotePlayer
    #Contract Board => nil
    def play(board_to_play)
        move = get_move
        board_to_play.set_piece(move, self.piece)
        nil
    end
end
