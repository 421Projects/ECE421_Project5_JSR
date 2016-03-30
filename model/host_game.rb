require 'contracts'
require 'observer'
require_relative 'player/player'
require_relative 'game/game'
class HostGame

    include Observable

    include Contracts::Core
    include Contracts::Builtin
    include Contracts::Invariants

    # http://www.ingate.com/files/422/fwmanual-en/xa10285.html
    invariant(@port) {@port > 1024 && @port < 65535}

    Contract Game, Nat => nil
    def initialize(game, port)
        @game = game
        @port = port
        nil
    end

    Contract None => nil
    def start_server()
        # add handler for receiving piece placements from connected clients
        nil
    end

    Contract None => nil
    def close_server()
        nil
    end

end

