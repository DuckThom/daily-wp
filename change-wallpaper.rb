require 'net/http'
require 'json'
require 'sqlite3'

database_file = "test.db"
wallpaper_file = File.expand_path( "~/wallpaper.jpg" )

db = SQLite3::Database.new( database_file )

# Create a table for the images
db.execute( "CREATE TABLE IF NOT EXISTS images (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, url VARCHAR(255) NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL)" )

# Get the json response from the API
response = Net::HTTP.get('www.bing.com', '/HPImageArchive.aspx?format=js&idx=0&n=1')

# Parse the json
json = JSON.parse(response)

# Get the image uri
uri = json["images"][0]["url"]

image_data = Net::HTTP.get('www.bing.com', uri)

begin
    if File.exists? wallpaper_file then
        file = File.open( wallpaper_file, "w" )
    else
        file = File.new( wallpaper_file, "w" )
    end

    file.write(image_data)
rescue IOError => e
    puts e
ensure
    file.close unless file.nil?
end

db.close
