require "contracts"
require_relative "../player"

class LocalPlayer < Player

    include Contracts::Core
    include Contracts::Builtin
    include Contracts::Invariants

    Contract Nat => nil
    def send_move(column)
        nil
    end
end
