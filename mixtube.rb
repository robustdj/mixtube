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

  def tag_path(tag_key)
    tag_key.gsub("/tag/", "/tags/")[0..-2]
  end
end

get '/favorites/:username' do
  render_favorites params[:username]
end

get '/favorites' do
  render_favorites ENV["MIXCLOUD_DEFAULT_USERNAME"]
end

get '/hot' do
  render_cloudcasts :hot
end

get '/popular' do
  render_cloudcasts :popular
end

get '/new' do
  render_cloudcasts :new
end

get '/tags/:tag' do
  render_tag params[:tag]
end

get '/cloudcast' do
  @cloudcast = JSON.parse(open("http://api.mixcloud.com#{params["key"]}").read)
  @cloudcast["oembed"] = JSON.parse(open("http://www.mixcloud.com/oembed/?url=#{@cloudcast['url']}").read)["html"]
  haml :cloudcast
end

get '/query_youtube' do
  client = YouTubeIt::Client.new(:dev_key => ENV['YOUTUBE_KEY'])
  @videos = client.videos_by(:query => params[:q]).videos
  content_type :json

  {
    :query => params[:q],
    :videos => @videos.map{|video| {:image_url => video.thumbnails[1].url, :title => CGI::escapeHTML(video.title), :unique_id => video.unique_id}}
  }.to_json
end

get '/youtube/:yt_id' do
  haml :youtube, :layout => false
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
  @cloudcasts = json["data"]
  @name = json["name"]
  @nav = :favorites
  haml :index
end

def render_cloudcasts(type)
  api_url = "http://api.mixcloud.com/#{type}/"
  api_url = "http://api.mixcloud.com/popular/hot/" if type == :hot

  json = JSON.parse(open(api_url).read)
  @cloudcasts = json["data"]
  @name = type.to_s
  @nav = type
  haml :index
end

def render_tag(tag)
  api_url = "http://api.mixcloud.com/search/?tag=#{tag}&type=cloudcast&q=#{tag}"

  json = JSON.parse(open(api_url).read)
  @cloudcasts = json["data"]
  @name = tag.to_s
  haml :index
end
