require 'rake'
require 'sequel'
require_relative './config/initializer'

task :console do
  exec "./bin/console"
end

namespace :db do
  desc "Create tables"
  task :create_tables do
    DB.create_table :bands do
      primary_key :id
      String :name
      Text :description
    end

    DB.create_table :songs do
      primary_key :id
      String  :title
      Integer :rating
      Integer :band_id
    end
  end

  desc "Drop tables"
  task :drop_tables do
    DB.run("drop table bands")
    DB.run("drop table songs")
  end

  desc "Reset database to initial state"
  task :reset => %i[drop_tables create_tables seed]

  desc "Insert sample bands and songs"
  task :seed do
    seed_data = {
      "Pearl Jam" => [
        { title: "Yellow Ledbetter", rating: 5 },
        { title: "Daughter", rating: 5 },
        { title: "Animal", rating: 4 },
        { title: "State of Love and Trust", rating: 4 },
        { title: "Alive", rating: 3 },
        { title: "Inside Job", rating: 4 }
      ],
      "Led Zeppelin" => [
        { title: "Black Dog", rating: 4 },
        { title: "Achilles Last Stand", rating: 5 },
        { title: "Immigrant Song", rating: 4 },
        { title: "Whole Lotta Love", rating: 4 }
      ],
      "Kaya Project" => [
        { title: "Always Waiting", rating: 5 }
      ],
      "Foo Fighters" => [
        { title: "The Pretender", rating: 3 },
        { title: "Best of You", rating: 5 }
      ],
      "Radiohead" => [
      ],
      "Red Hot Chili Peppers" => [
      ]
    }

    bands = DB[:bands]
    songs = DB[:songs]

    seed_data.each_pair do |band_name, songs_data|
      band = bands.where(name: band_name).first
      unless band
        puts "Create band: #{band_name}"
        band_id = bands.insert(name: band_name)
      end
      songs_data.each do |song_data|
        title = song_data[:title]
        rating = song_data[:rating]
        song = songs.where(title: title).first
        unless song
          puts "Create song: #{title} (#{rating})"
          song = songs.insert(title: title, rating: rating, band_id: band_id)
        end
      end
    end
  end
end
