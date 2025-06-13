require 'sinatra'
require 'sqlite3'
use Rack::Session::Cookie, key: 'rack.session',
                           path: '/',
                           secret: 'change_this_to_a_secure_random_string_adfdsfsadfads_adfdsafsfsafagdgsda_gfasgsdfgagagsdfagsafgaagdgagasgddgasdgdsag'

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
  username = params["username"]
  password = params["password"]

  begin
    db.execute("INSERT INTO users (username, password) VALUES (?, ?)", [username, password])
    "Successfully added user #{username} to database"
  rescue SQLite3::Exception => e
    puts "Database error: #{e}"
  end
end
