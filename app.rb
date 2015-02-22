require 'sinatra'
require 'sequel'
require './config/initializer'
require 'json'
require 'rack/cors'
require 'pry'

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
      { id: song[:id], title: song[:title], rating: song[:rating], artist: artist[:id] }
    end
  end

  def song_ids_for_artist(artist)
    songs = songs_for_artist(artist)
    songs.map { |song| song[:id] }
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

  def parse_body(json)
    if json.nil? || json.empty?
      json = "{}"
    end

    JSON.parse(json, symbolize_names: true)
  end

  get '/' do
    [200, { "Content-Type" =>"application/json" }, { name: "Rock & Roll API", version: '0.1' }.to_json]
  end

  get '/bands' do
    artists = DB[:artists]
    songs   = DB[:songs]

    status 200
    headers({ "Content-Type" =>"application/json" })

    artists_array = artists.map do |artist|
      {
        id: artist[:id],
        name: artist[:name],
        description: artist[:description],
        songs: song_ids_for_artist(artist),
      }
    end

    songs_array = songs.map do |song|
      {
        id: song[:id],
        title: song[:title],
        rating: song[:rating],
        band: song[:artist_id],
      }
    end

    payload = {
      bands: artists_array,
      songs: songs_array,
    }

    payload.to_json
  end

  post '/bands' do
    raw_data = parse_body(request.body.read)

    artist_name = raw_data[:band][:name]
    attributes  = { name: artist_name }
    artists     = DB[:artists]
    artist_id   = artists.insert(attributes)

    status 201 # Created
    headers({ "Content-Type" =>"application/json" })

    {
      band: attributes.merge(id: artist_id, songs: []),
      songs: [],
    }.to_json
  end

  get '/bands/:slug' do
    artist = artist_for_slug(params[:slug])

    status 200
    headers({ "Content-Type" =>"application/json" })

    payload = {
      band: {
        id: artist[:id],
        name: artist[:name],
        description: artist[:description],
        songs: song_ids_for_artist(artist),
      },
      songs: songs_for_artist(artist),
    }

    payload.to_json
  end

  get '/bands/:slug/songs' do
    status 200
    headers({ "Content-Type" =>"application/json" })

    artist = artist_for_slug(params[:slug])
    songs_for_artist(artist).to_json
  end

  put '/bands/:slug' do
    raw_data = parse_body(request.body.read)
    bands = DB[:artists]
    bands.where(id: params[:slug]).update(description: raw_data[:band][:description])
    attributes = bands.where(id: params[:slug]).first

    status 200
    headers({ "Content-Type" =>"application/json" })

    {
      band: attributes
    }.to_json
  end

  post '/songs' do
    raw_data = parse_body(request.body.read)

    songs = DB[:songs]
    band  = DB[:artists].where(id: raw_data[:song][:band]).first
    attributes = { title: raw_data[:song][:title], artist_id: raw_data[:song][:band], rating: 0 }

    song_id = songs.insert(attributes)

    status 201
    headers({ "Content-Type" =>"application/json" })

    {
      song: attributes.merge(id: song_id),
      band: {
        name: band[:name],
        description: band[:description],
      }
    }.to_json
  end

  put '/songs/:id' do
    raw_data = parse_body(request.body.read)
    songs = DB[:songs]
    songs.where(id: params[:id]).update(rating: raw_data[:song][:rating])
    attributes = songs.where(id: params[:id]).first

    status 200
    headers({ "Content-Type" =>"application/json" })

    {
      song: attributes
    }.to_json
  end
end
