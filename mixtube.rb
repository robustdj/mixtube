require 'json'
require 'open-uri'
require 'bundler/setup'
Bundler.require :default

enable :sessions
use Rack::Flash

configure do
  Tilt.register 'scss', Tilt::SassTemplate
  set :scss, :syntax => :scss
end

helpers do
  # TODO: Put helpers here.
end

get '/favorites/:username' do
  render_favorites params[:username]
end

get '/favorites' do
  render_favorites ENV["MIXCLOUD_DEFAULT_USERNAME"]
end

get '/cloudcast' do
  @cloudcast = JSON.parse(open("http://api.mixcloud.com#{params["key"]}").read)
  @cloudcast["oembed"] = JSON.parse(open("http://www.mixcloud.com/oembed/?url=#{@cloudcast['url']}").read)["html"]
  haml :cloudcast
end

get '/query_youtube' do
  client = YouTubeIt::Client.new(:dev_key => YOUTUBE_KEY)
  @videos = client.videos_by(:query => params[:q]).videos
  content_type :json
  @videos.map{|video| {:image_url => video.thumbnails[1].url, :embed => video.embed_html, :title => video.title, :unique_id => video.unique_id}}.to_json
end

get '/oauth' do
  redirect "https://www.mixcloud.com/oauth/authorize?client_id=#{MIXCLOUD_API_KEY}&redirect_uri=http://localhost:9393/mixtube_callback"
end

get '/mixtube_callback' do
  code = params["code"]
  redirect "https://www.mixcloud.com/oauth/access_token?client_id=#{MIXCLOUD_API_KEY}&redirect_uri=http://localhost:9393/mixtube_callback&client_secret=#{MIXCLOUD_API_SECRET}&code=#{code}"
end

get '/' do
  render_favorites ENV["MIXCLOUD_DEFAULT_USERNAME"]
end

get '/*' do
  haml :not_found
end

get 'stylesheets/:file.css' do |file|
  content_type 'text/css', :charset => 'utf-8'

  # no #scss method is defined (and #sass only looks for .sass files)
  # we must call render ourself:
  scss file.to_sym, :layout => false
end

def render_favorites(username)
  json = JSON.parse(open("http://api.mixcloud.com/#{username}/favorites/").read)
  #json = JSON.parse(File.read("spec/fixtures/favorites.json"))
  @favorites = json["data"]
  @name = json["name"]
  haml :index
end
