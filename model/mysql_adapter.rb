require "mysql2"

class MySQLAdapter

    def initialize(host="127.0.0.1", port=8080,
                   username="admin3iQCfbc", password="2nUhtK3IX5RT",
                   db="myapp")
        @host = host
        @port = port
        @username = username
        @password = password
        @db = db
        @con = Mysql2::Client.new(:host => @host, :username => @username,
                                 :password => @password)
        @con.query("use #{@db}")

        if @con.query("show tables LIKE 'players'").to_a.size < 1
            @con.query("create table players ( name varchar(255) NOT NULL, wins int, losses int, ties int, points int, PRIMARY KEY (name));")
        end
    end

    def add_player(name)
        @con.query("insert into players  values ('#{name}', 0,0,0,0);")
    end

    def delete_player(name)
        @con.query("delete from players where name=#{name};")
    end

    def get_wins_for_player(name)
        @con.query("select wins from players where name='#{name}';").each do |row|
            return row["wins"]
        end
    end

    def get_losses_for_player(name)
        @con.query("select losses from players where name='#{name}';").each do |row|
            return row["losses"]
        end
    end

    def get_ties_for_player(name)
        @con.query("select ties from players where name='#{name}';").each do |row|
            return row["ties"]
        end
    end

    def get_points_for_player(name)
        @con.query("select points from players where name='#{name}';").each do |row|
            return row["points"]
        end
    end

    def set_wins_for_player(name, win_count)
        @con.query("update players set wins='#{win_count}' where name='#{name}';")
    end

    def set_points_for_player(name, point_count)
        @con.query("update players set points='#{point_count}' where name='#{name}';")
    end

    def set_losses_for_player(name, loss_count)
        @con.query("update players set losses='#{loss_count}' where name='#{name}';")
    end

    def set_ties_for_player(name, tie_count)
        @con.query("update players set ties='#{tie_count}' where name='#{name}';")
    end

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
