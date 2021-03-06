require 'sinatra'
require 'sequel'
require './config/initializer'
require 'json'
require 'rack/cors'

class RockAndRollAPI < Sinatra::Base

  use Rack::Cors do
    allow do
      origins  '*'
      resource '*', headers: :any, methods: %i[get post put options]
    end
  end

  def songs_for_artist(artist)
    artist_songs_records = DB[:songs].where(artist_id: artist[:id])
    artist_songs_records.map do |song|
      { id: song[:id], title: song[:title], rating: song[:rating] }
    end
  end

  def artist_for_slug(slug)
    artists = DB[:artists]
    artists.detect do |artist|
      name = artist[:name]
      name_parts = name.split(/\s+/).map(&:downcase)
      artist_slug = name_parts.join('-')
      artist_slug == slug
    end
  end

  get '/' do
    [200, { "Content-Type" =>"application/json" }, { name: "Rock & Roll API", version: '0.1' }.to_json]
  end

  get '/artists' do
    artists = DB[:artists]
    status 200
    headers({ "Content-Type" =>"application/json" })
    [].tap do |json_response|
      artists.each do |artist|
        json_response << { id: artist[:id], name: artist[:name], songs: songs_for_artist(artist) }
      end
    end.to_json
  end

  post '/artists' do
    artist_name = params[:name]
    attributes = { name: artist_name }
    artists = DB[:artists]
    artist_id = artists.insert(attributes)

    status 201 # Created
    headers({ "Content-Type" =>"application/json" })
    attributes.merge(id: artist_id, songs: []).to_json
  end

  get '/artists/:slug' do
    artist = artist_for_slug(params[:slug])

    status 200
    headers({ "Content-Type" =>"application/json" })
    {
      id: artist[:id],
      name: artist[:name],
      songs: songs_for_artist(artist)
    }.to_json
  end

  get '/artists/:slug/songs' do
    status 200
    headers({ "Content-Type" =>"application/json" })

    artist = artist_for_slug(params[:slug])
    songs_for_artist(artist).to_json
  end

  post '/songs' do
    songs = DB[:songs]
    attributes = { title: params[:title], artist_id: params[:artist_id], rating: 0 }
    song_id = songs.insert(attributes)

    status 201
    headers({ "Content-Type" =>"application/json" })
    attributes.merge(id: song_id).to_json
  end

  put '/songs/:id' do
    songs = DB[:songs]
    songs.where(id: params[:id]).update(rating: params[:rating])
    attributes = songs.where(id: params[:id]).first

    status 200
    headers({ "Content-Type" =>"application/json" })
    attributes.to_json
  end

end
