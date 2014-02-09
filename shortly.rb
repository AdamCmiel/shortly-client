require 'sinatra'
require "sinatra/reloader" if development?
require 'active_record'
require 'digest/sha1'
require 'pry'
require 'uri'
require 'bcrypt'
require 'open-uri'
# require 'nokogiri'

###########################################################
# Configuration
###########################################################

set :public_folder, File.dirname(__FILE__) + '/public'

configure :development, :production do
  ActiveRecord::Base.establish_connection(
   :adapter => 'sqlite3',
   :database =>  'db/dev.sqlite3.db'
  )
end

# Handle potential connection pool timeout issues
after do
  ActiveRecord::Base.connection.close
end

# turn off root element rendering in JSON
ActiveRecord::Base.include_root_in_json = false

###########################################################
# Models
###########################################################
# Models to Access the database through ActiveRecord.
# Define associations here if need be
# http://guides.rubyonrails.org/association_basics.html

class Link < ActiveRecord::Base
  has_many :clicks
  belongs_to :user

  validates :url, presence: true

  before_save do |record|
    record.code = Digest::SHA1.hexdigest(url)[0,5]
  end
end

class Click < ActiveRecord::Base
    belongs_to :link, counter_cache: :visits
end

class User < ActiveRecord::Base
  has_many :tokens
  has_many :links

  before_create do |record|
    record.password_salt     = BCrypt::Engine.generate_salt
    record.password = BCrypt::Engine.hash_secret(record.password, record.password_salt)
  end
end

class Token < ActiveRecord::Base
  belongs_to :user

  before_create do |record|
    # puts record.inspect
    string_to_hash = record.user.username + record.user.password
    record.auth_code = Digest::SHA1.hexdigest(string_to_hash)[0,10]
  end
end

###########################################################
# Routes
###########################################################

get '/' do
  erb :index
end

get '/create' do
  erb :index
end

get '/login' do
  erb :index
end

get '/logout' do
  redirect "/"
end

# Need to check authorization for these routes (Am I logged in?)

['/links'].map do |path|
  before path do
      halt 401 unless current_user?
  end
end
  
get '/links' do
  links = Link.all
  links.map { |link|
   link.as_json.merge(base_url: request.base_url, click: link.clicks.last)
  }.to_json
end

post '/links' do
  data = JSON.parse request.body.read
  puts data.inspect
  uri = URI(data['url'])
  raise Sinatra::NotFound unless uri.absolute?
  link = Link.find_by_url(uri.to_s) ||  Link.create(url: uri.to_s, title: get_url_title(uri))
  link.as_json.merge(base_url: request.base_url).to_json
end

get '/:url' do
  link = Link.find_by_code params[:url]
  raise Sinatra::NotFound if link.nil?
  link.clicks.create!
  redirect link.url
end

post '/users/login' do 
  data = JSON.parse request.body.read
  user = User.find_by_username(data["username"])
  if user.nil? 
    response.status 418
    response.body '418: User not found'
  else 
    token = user.tokens.create
    user.tokens.last.to_json
  end
end

post '/users/create' do
  data = JSON.parse request.body.read
  user = User.find_by_username(data["username"]) || User.create(data)
  token = user.tokens.create
  user.tokens.last.to_json 
end

###########################################################
# Utility
###########################################################

def read_url_head url
    head = ""
    url.open do |u|
        begin
            line = u.gets
            next  if line.nil?
            head += line
            break if line =~ /<\/head>/
        end until u.eof?
    end
    head + "</html>"
end

def get_url_title url
    # Nokogiri::HTML.parse( read_url_head url ).title
    result = read_url_head(url).match(/<title>(.*)<\/title>/)
    result.nil? ? "" : result[1]
end

def current_user?
  c_t = current_token
  c_t && !!c_t.user
end

def current_token
  Token.find_by_auth_code params[:token]
end