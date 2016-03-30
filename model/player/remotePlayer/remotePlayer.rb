require "contracts"
require_relative "../player"

class RemotePlayer < Player

    include Contracts::Core
    include Contracts::Builtin
    include Contracts::Invariants

    Contract None => Nat
    def get_move
        1
    end
end
