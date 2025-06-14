require 'sinatra'
require 'sqlite3'
require 'dotenv/load'
require 'date'
require 'bcrypt'

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
    @entries = nil
  else
    @logged_in = true
    @username = session[:username] 
    @entries = db.query "SELECT entry_id, created_at, title, entry FROM entries WHERE user_id=?", session[:user_id]
  end
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
  #/////////////////////////////////////A PROPER WAY TO CHECK PASSWORD DURING LOGIN
  # row = db.get_first_row("SELECT user_id, password FROM users WHERE username=?", [username])
  # if row && BCrypt::Password.new(row['password']) == password
    # Authentication successful
    # session[:user_id] = row["user_id"]
    # session[:username] = username
    # redirect '/'
  # else
    # return "Invalid login details"
  # end
  #///////////////////////////////////////////

  results = db.get_first_row "SELECT user_id, username, password FROM users WHERE username=? AND password=?", [username, password]
  if results.nil?
    return "No user found"
  else
    session[:user_id] = results["user_id"]
    session[:username] = results["username"]
    redirect '/'
  end

end

post '/register' do
  # TODO
  # check if user exists before adding.
  username = params["username"]
  password = params["password"]

#///////////////////////////////////////// HERE HOW TO CORRECTLY HASH PASSWORDS
  # hashed_pw = BCrypt::Password.create(password)
  # db.execute("INSERT INTO users (username, password) VALUES (?, ?)", [username, hashed_pw])
#/////////////////////////////////////


  # example of malicious username entry
  #attacker', 'maliciouspass'); DROP TABLE users; --
  begin
    # this would eliminate the issue sql injeciton
    # db.execute("INSERT INTO users (username, password) VALUES (?, ?)", [username, password])

    # this is a bad way to create sql query and is vulnerable to sql injection
    sql_query = "INSERT INTO users (username, password) VALUES ('#{username}','#{password}')"


    db.execute_batch(sql_query)
    @message = "Registration successful! Redirecting to home..."
    erb :message_and_redirect
  rescue SQLite3::Exception => e
    puts "Database error: #{e}"
    @message = "Registration failed."
    erb :message_and_redirect
  end
end

get '/entries/:id/delete' do
  # Here's a more secure version that checks that the logged in user
  # is the owner of the journal entry
  #
  # user_id = session[:user_id]
  # halt 401, "Please log in to continue" unless user_id
  # entry = db.execute("SELECT * FROM entries WHERE entry_id=? AND user_id=?", [id_to_delete, user_id]).first
  #if entry
  # db.execute("DELETE FROM entries WHERE entry_id=?", id_to_delete)
     #redirect '/'
  # else
    # halt 403, "Not authorized to delete this entry"
  # end
  


  # This is an example of broken access control
  # Anyone is able to delete an entry with GET request to this endpoint with an entry id
  # For example with curl to delete entry with id of 4: curl -X GET http://localhost:4567/entries/4/delete
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
