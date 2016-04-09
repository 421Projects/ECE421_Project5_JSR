require "mysql2"
require "observer"
require "yaml"
require "json"

class LocalFileStorage

    include Observable

    attr_accessor :file_handler

    def initialize(file_name="game_records.yml")
        @file_name = file_name
        if File.exists?(@file_name) == false
            a = File.open(@file_name, "a+")
            a.close
        end
    end

    def save(key,value)
        contents = read_file
        # puts "contents #{contents}"
        # puts "key #{key}"
        # puts "value #{contents[key]}"
        contents[key] = value
        save_file(contents)
    end

    def load(key)
        contents = read_file
        return contents[key]
    end

    def delete(key)
        save(key, nil)
    end

    def read_file
        @file_handler = File.open(@file_name, "rb")
        contents = @file_handler.read
        # contents = JSON.parse(contents.gsub('\"', '"'))
        contents = YAML::load(contents)
        # contents = JSON.parse(contents)
        if contents == false
            contents = {}
        end
        @file_handler.close
        return contents
    end

    def save_file(contents)
        @file_handler = File.open(@file_name, "wb")
        contents = YAML::dump(contents)
        @file_handler.write(contents)
        @file_handler.close
        #@file_handler.write(contents.to_yaml)
    end

end

