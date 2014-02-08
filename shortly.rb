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
    string_to_hash = record.user.username + record.user.password
    record.auth_code = Digest::SHA1.hexdigest(string_to_hash)[0,10]
  end
end

###########################################################
# Routes
###########################################################

# before "/" do
#   puts request.cookies['shortly']
# end


get '/' do
  redirect "/login" if request.cookies["shortly"] == nil
  erb :index
end

get '/create' do
  erb :index
end

get '/login' do
  erb :index
end

get '/logout' do
  response.set_cookie("shortly", nil)
  redirect "/"
end


get '/links' do
  # params = JSON.parse request.body.read
  # #extract auth_code string (auth_codes stored in token table)
  # auth_code = params['auth_code']
  # #find user_id associated with token
  # user_id = Token.find_by_auth_code(auth_code).user_id
  # #find all links with user_id

  # if(user_id)
  #   links = Link.find_all_by_user_id(user_id) #.order('created_at DESC')
  #   puts links.inspect
  #   links.map { |link|
  #    link.as_json.merge(base_url: request.base_url)
  #   }.to_json
  # else
  #   status 401
  #   body "Please login to create an account"
  # end

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
    #user = User.find_by username: data[:username]
    # user = User.find_by_username(data["username"])

    link = Link.find_by_url(uri.to_s) ||  Link.create(url: uri.to_s, title: get_url_title(uri))# user_id: user.id)

    link.as_json.merge(base_url: request.base_url).to_json
end

get '/:url' do
    link = Link.find_by_code params[:url]
    raise Sinatra::NotFound if link.nil?
    link.clicks.create!
    redirect link.url
end

post '/users/create' do
  data = JSON.parse request.body.read
  user = User.find_by_username(data[:username]) || User.create(data)
  token = user.tokens.create
  response.set_cookie("shortly", "hi")
  puts response.inspect
  user.to_json
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

def read_url_page url
    page = ""
    url.open do |u|
        begin
            line = u.gets
            next  if line.nil?
            page += line
            break if line =~ /<\/body>/
        end until u.eof?
    end
    page + "</html>"
end


def get_url_title url
    # Nokogiri::HTML.parse( read_url_head url ).title
    result = read_url_head(url).match(/<title>(.*)<\/title>/)
    result.nil? ? "" : result[1]
end
