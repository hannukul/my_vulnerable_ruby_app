require 'sinatra'
require 'sqlite3'

db = SQLite3::Database.open "data.db"
db.results_as_hash = true
db.execute "CREATE TABLE IF NOT EXISTS users(user_id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT, password TEXT)"

get '/' do
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
  results = db.get_first_row "SELECT username, password FROM users WHERE username=? AND password=?", [username, password]

  if results.nil?
    puts "to console: user not found"
    return "No user found"
  else
    puts results
    session[:user_id] = results[0]

    puts "to console: user found"
    return "Welcome, #{username}!"
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
