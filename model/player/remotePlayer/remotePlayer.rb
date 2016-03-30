require "contracts"
require_relative "../player"

class RemotePlayer < Player

    include Contracts::Core
    include Contracts::Builtin
    include Contracts::Invariants

    def get_move
    end
end
