require 'sinatra'
require 'sqlite3'
require 'dotenv/load'

use Rack::Session::Cookie, key: 'rack.session',
                           path: '/',
                           secret: ENV['SESSION_SECRET']

db = SQLite3::Database.open "data.db"
db.results_as_hash = true
db.execute "CREATE TABLE IF NOT EXISTS users(user_id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT, password TEXT)"

get '/' do
  @logged_in = nil

  if session[:user_id].nil?
    @logged_in = false
  else
    @logged_in = true
    @username = session[:username] 
  end
  erb :index
end

get '/login' do
  erb :login
end

get '/register' do
  erb :register
end

post '/login' do
  username = params["username"]
  password = params["password"]
  results = db.get_first_row "SELECT user_id, username, password FROM users WHERE username=? AND password=?", [username, password]

  if results.nil?
    puts "to console: user not found"
    return "No user found"
  else
    puts results
    session[:user_id] = results["user_id"]
    session[:username] = results["username"]
    puts session.inspect

    # return "Welcome, #{username}!"
    redirect '/'
  end

end

post '/register' do
  # TODO
  # check if user exists before adding.

  username = params["username"]
  password = params["password"]
  
  begin
    db.execute("INSERT INTO users (username, password) VALUES (?, ?)", [username, password])
    @message = "Registration successful! Redirecting to home..."
    erb :message_and_redirect
  rescue SQLite3::Exception => e
    puts "Database error: #{e}"
    @message = "Registration failed."
    erb :message_and_redirect
  end
end

get '/logout' do
  session.clear
  redirect '/'
end
