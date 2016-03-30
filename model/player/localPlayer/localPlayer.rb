require "contracts"
require_relative "../player"

class LocalPlayer < Player

    include Contracts::Core
    include Contracts::Builtin
    include Contracts::Invariants

    def send_move
    end
end
