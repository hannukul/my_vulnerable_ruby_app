require 'sinatra'
require 'sqlite3'
require 'dotenv/load'
require 'date'

use Rack::Session::Cookie, key: 'rack.session',
                           path: '/',
                           secret: ENV['SESSION_SECRET']

db = SQLite3::Database.open "data.db"
db.results_as_hash = true
db.execute "CREATE TABLE IF NOT EXISTS users(user_id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT, password TEXT)"
db.execute "CREATE TABLE IF NOT EXISTS entries(entry_id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, created_at DATETIME DEFAULT CURRENT_TIMESTAMP, title TEXT, entry TEXT, FOREIGN KEY (user_id) REFERENCES users (user_id))"

get '/' do
  @logged_in = nil

  if session[:user_id].nil?
    @logged_in = false
  else
    @logged_in = true
    @username = session[:username] 
  end
  @entries = db.query "SELECT entry_id, created_at, title, entry FROM entries WHERE user_id=?", session[:user_id]
  puts @entries
  erb :index
end

get '/login' do
  erb :login
end

get '/register' do
  erb :register
end

get '/entries/new' do
  erb :new_entry
end

post '/entries/new' do
  user_id = session[:user_id]
  if user_id.nil? 
    return "You need to login first, before you can create journal entries"
  end

  title = params["title"]
  entry = params["entry"]

  begin
    db.execute("INSERT INTO entries (user_id, title, entry) VALUES (?, ?, ?)", [user_id, title, entry])
    @message = "Journal entry created successfully! Redirecting back to homepage..."
    erb :message_and_redirect
  rescue SQLite3::Exception => e
    puts "Database error: #{e}"
    @message = "Failed to create a journal entry."
    erb :message_and_redirect
  end
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

get '/entries/:id/delete' do
  id_to_delete = params[:id]
  begin
    db.execute("DELETE from entries WHERE entry_id=?", id_to_delete)
    redirect '/' 
  rescue
    puts "Database error: #{e}"
  end
end

get '/logout' do
  session.clear
  redirect '/'
end
