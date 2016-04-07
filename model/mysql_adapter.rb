require "mysql2"
require "observer"

class MySQLAdapter

    include Observable
    class PlayerAlreadyExists < StandardError
    end
    class PlayerNotFound < StandardError
    end

    def initialize(host="127.0.0.1", port=8080,
                   username="admin3iQCfbc", password="2nUhtK3IX5RT",
                   db="myapp")
        @host = host
        @port = port
        @username = username
        @password = password
        @db = db

    end

    def connected?
        return @con != nil
    end

    def connect
        begin
            @con = Mysql2::Client.new(:host => @host, :username => @username,
                                      :password => @password)
            @con.query("use #{@db}")

            if @con.query("show tables LIKE 'players'").to_a.size < 1
                @con.query("create table players ( name varchar(255) NOT NULL, wins int, losses int, ties int, points int, PRIMARY KEY (name));")
            end
        rescue => se
            changed
            notify_observers("Message: MySQL error, games will not recorded. \n" +
                            "Error Message: #{se.message}.")
        end
    end

    def get_table_sorted_by_points
        return @con.query("select * from players order by points desc;")
    end

    def add_player(name)
        if player_exists?(name)
            raise PlayerAlreadyExists, "#{name} already exists in the database."
        else
            @con.query("insert into players  values ('#{name}', 0,0,0,0);")
        end
    end

    def delete_player(name)
        if player_exists?(name)
            @con.query("delete from players where name='#{name}';")
        else
            raise PlayerNotFound, "#{name} not found in the database."
        end
    end

    def player_exists?(name)
        @con.query("select * from players where name='#{name}';").each do |row|
            return true
        end
        return false
    end

    def get_wins_for_player(name)
        check_and_run_query(name) {
            @con.query("select wins from players where name='#{name}';").each do |row|
                return row["wins"]
            end
        }
    end

    def get_losses_for_player(name)
        check_and_run_query(name) {
            @con.query("select losses from players where name='#{name}';").each do |row|
                return row["losses"]
            end
        }
    end

    def get_ties_for_player(name)
        check_and_run_query(name) {
            @con.query("select ties from players where name='#{name}';").each do |row|
                return row["ties"]
            end
        }
    end

    def get_points_for_player(name)
        check_and_run_query(name) {
            @con.query("select points from players where name='#{name}';").each do |row|
                return row["points"]
            end
        }
    end

    def set_wins_for_player(name, win_count)
        check_and_run_query(name) {
            @con.query("update players set wins='#{win_count}' where name='#{name}';")
        }
    end

    def set_points_for_player(name, point_count)
        check_and_run_query(name) {
            @con.query("update players set points='#{point_count}' where name='#{name}';")
        }
    end

    def set_losses_for_player(name, loss_count)
        check_and_run_query(name) {
            @con.query("update players set losses='#{loss_count}' where name='#{name}';")
        }
    end

    def set_ties_for_player(name, tie_count)
        check_and_run_query(name) {
            @con.query("update players set ties='#{tie_count}' where name='#{name}';")
        }
    end

    def check_and_run_query(name)
        # http://www.tutorialspoint.com/ruby/ruby_blocks.htm
        if player_exists?(name)
            yield
        else
            raise PlayerNotFound, "#{name} not found in the database."
        end
    end

    private :set_wins_for_player,
            :set_losses_for_player,
            :set_ties_for_player,
            :set_points_for_player,
            :check_and_run_query

    def add_win_for_player(name)
        wins = get_wins_for_player(name)
        points = get_points_for_player(name)

        wins += 1
        points += 2

        set_wins_for_player(name, wins)
        set_points_for_player(name, points)
    end

    def add_loss_for_player(name)
        losses = get_losses_for_player(name)
        losses += 1
        set_losses_for_player(name, losses)
    end

    def add_tie_for_player(name)
        ties = get_ties_for_player(name)
        points = get_points_for_player(name)

        ties += 1
        points += 1

        set_ties_for_player(name, ties)
        set_points_for_player(name, points)
    end

end
