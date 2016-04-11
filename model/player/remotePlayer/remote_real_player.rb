require_relative "./remotePlayer"

class RemoteRealPlayer < RemotePlayer
    #Contract Board => nil
    def play(board_to_play)
        move = get_move
        @last_column_played = move
        if @last_column_played != -2 and @last_column_played != -3
            board_to_play.set_piece(move, self.piece)
        end
        nil
    end
end
