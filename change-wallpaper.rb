require 'net/http'
require 'json'
require 'sqlite3'

class DailyWallpaper

    ##
    # DailyWallpaper initializer.
    #
    def initialize
        @wallpaper_file = File.expand_path( "~/wallpaper.jpg" )
        @db = SQLite3::Database.new( "database.db" )
    end

    ##
    # Run the wallpaper changer 1000.
    #
    def run
        create_table

        get_json

        parse_json

        save_response

        get_image

        write_file

        @db.close
    end

    private

    ##
    # Gracefully close the app for whatever reason.
    #
    def close (msg = '', code = 0)
        puts msg

        @db.close

        exit code
    end

    ##
    # Save the response to the database.
    #
    def save_response
        @uri = @parsed_json["images"][0]["url"]
        hash = @parsed_json["images"][0]["hsh"]
        date = Date.strptime(@parsed_json["images"][0]["enddate"], '%Y%m%d').strftime

        begin
            @db.execute(
                "INSERT INTO images " +
                "( url, date, hash ) " +
                "VALUES " +
                "( '#{@uri.to_s}', '#{date.to_s}', '#{hash.to_s}' );"
            )
        rescue SQLite3::ConstraintException => e
            close e.message
        end
    end

    ##
    # Create a table if it does not exist
    #
    # Table:
    # - images
    #
    # Columns:
    # - id: integer - primary key - autoincrement - not null
    # - url: varchar(255) - not null
    # - hash: varchar(255) - unique - not null
    # - created_at: timestamp - default current_timestamp - not null
    #
    def create_table
        @db.execute(
            "CREATE TABLE IF NOT EXISTS images ( " +
                "id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, " +
                "url VARCHAR(255) NOT NULL, " +
                "hash VARCHAR(255) UNIQUE NOT NULL, " +
                "date VARCHAR(10) UNIQUE NOT NULL, " +
                "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL " +
            ")"
        )
    end

    ##
    # Get JSON from the Bing API.
    #
    def get_json
        @json = Net::HTTP.get('www.bing.com', '/HPImageArchive.aspx?format=js&idx=0&n=1')
    end

    ##
    # Turn a json string into a json object.
    #
    # param::  json: string
    #
    def parse_json
        @parsed_json = JSON.parse @json
    end

    ##
    # Get the image data.
    #
    # return:: string
    #
    def get_image
        @image_data = Net::HTTP.get('www.bing.com', @uri)
    end

    ##
    # Write the image data to a file.
    #
    # param:: data: string
    #
    def write_file
        begin
            if File.exists? @wallpaper_file then
                file = File.open( @wallpaper_file, "w" )
            else
                file = File.new( @wallpaper_file, "w" )
            end

            file.write(@image_data)
        rescue IOError => e
            close e.message 1
        ensure
            file.close unless file.nil?
        end
    end
end

dw = DailyWallpaper.new
dw.run
