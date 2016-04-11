require 'contracts'
require "mysql2"
require "observer"
require "yaml"
require "json"

class LocalFileStorage

    include Observable
    include Contracts::Core
    include Contracts::Builtin
    include Contracts::Invariants

    attr_accessor :file_handler

    Contract String => nil
    def initialize(file_name="game_records.yml")
        @file_name = file_name
        if File.exists?(@file_name) == false
            a = File.open(@file_name, "a+")
            a.close
        end
    end

    Contract String, Maybe[HashOf[String, Any]] => Any
    def save(key,value)
        contents = read_file
        # puts "contents #{contents}"
        # puts "key #{key}"
        # puts "value #{contents[key]}"
        contents[key] = value
        save_file(contents)
    end

    Contract String => Any
    def load(key)
        contents = read_file
        return contents[key]
    end

    Contract String => Any
    def delete(key)
        save(key, nil)
    end

    Contract None => Any
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

    Contract Any => Any
    def save_file(contents)
        @file_handler = File.open(@file_name, "wb")
        contents = YAML::dump(contents)
        @file_handler.write(contents)
        @file_handler.close
        #@file_handler.write(contents.to_yaml)
    end

end

