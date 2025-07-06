require 'sinatra'
require 'sqlite3'
require 'dotenv/load'
require 'date'
require 'bcrypt'
require 'open-uri'


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

  ## Fix related to A02: Cryptographic failure, about lack of password hashing
  ##
  ## Here's how to check password when it's properly hashed
  # row = db.get_first_row("SELECT user_id, password FROM users WHERE username=?", [username])
  # if row && BCrypt::Password.new(row['password']) == password
    # Authentication successful
    # session[:user_id] = row["user_id"]
    # session[:username] = username
    # redirect '/'
  # else
    # return "Invalid login details"
  # end

  ## This login code only works with plaintext passwords
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
  username = params["username"]
  password = params["password"]

## EXAMPLE of A02: Cryptographic failure ######################################
## In the following code, passwords are saved to database in plaintext
## Here's a how to fix this vulnerability
# password = BCrypt::Password.create(password)

## Additional changes has been made to login route as well to make login work with hashed passwords
###############################################################################



## EXAMPLE of A03: Injection
## Register page is vulnerable to SQL injection because sql statements are not 
## properly parameterized
## 
## Example of malicious username entry
## attacker', 'maliciouspass'); DROP TABLE users; --
## which drops the table users
  begin

    ###### FIX for A03 ######################
    ## this code eliminates the issue sql injeciton
    db.execute("INSERT INTO users (username, password) VALUES (?, ?)", [username, password])
    ##############################

    ##### Also comment out this unsafe code
    #sql_query = "INSERT INTO users (username, password) VALUES ('#{username}','#{password}')"
    #db.execute_batch(sql_query)
    ####################################################

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

  #############################################################
  # Here's a fix for A01 vulnerability
  #
  # is the owner of the journal entry
  #
  # user_id = session[:user_id]
  # halt 401, "Please log in to continue\n" unless user_id
  # entry = db.execute("SELECT * FROM entries WHERE entry_id=? AND user_id=?", [id_to_delete, user_id]).first
  # if entry
  #     db.execute("DELETE FROM entries WHERE entry_id=?", id_to_delete)
  #    redirect '/'
  # else
  #    halt 403, "Not authorized to delete this entry"
  # end
  ###############################################################

  ###############################################################
  # EXAMPLE of A01:2021 Broken Access Control
  #
  # Anyone is able to delete an entry with GET request to this endpoint with an entry id
  # For example with curl to delete entry with id of 4: curl -X GET http://localhost:4567/entries/4/delete
  begin
    db.execute("DELETE from entries WHERE entry_id=?", id_to_delete)
    redirect '/' 
  rescue
    puts "Database error: #{e}"
  end
  ################################################################
end

get '/profile' do 
  erb :profile
end


# THIS ENDPOINT IS RESPONSIBLE FOR FETCHING PROFILE IMAGE AND IS VULNERABLE TO OWASP TOP10 2021 A10: Server-side Request Forgery
# Also A05 Misconfiguration is demonstrated here, as improper handling of errors leads to stack trace being exposed to the user
post '/profile/url' do 
  

  url = params["profile_image_url"]


  # This is the code has the checks needed to make endpoint SAFE

  # ALLOWED_DOMAINS = ['imgur.com']  #Domain whitelist
  #
  # uri = URI.parse(url)
  #
  # # 1. Only allow http and https protocols
  # halt 400, "Invalid URL scheme" unless ['http', 'https'].include?(uri.scheme)
  #
  # # 2. Check domain whitelist
  # host = uri.host
  # halt 400, "Domain not allowed" unless ALLOWED_DOMAINS.any? { |d| host&.end_with?(d) }
  #
  # # 3. Resolve and block private IPs
  # def private_ip?(ip)
  #   ip = IPAddr.new(ip)
  #   ip.private? || ip.loopback? || ip.link_local?
  # end
  #
  # ips = Resolv.getaddresses(host)
  # if ips.any? { |ip| private_ip?(ip) }
  #   halt 400, "URL resolves to private IP, not allowed"
  # end



# OWASP Top10 A05: Misconfiguration
# Here the vulnerability is exposing stack trace to the enduser.
# This is fixed by using begin-rescue blocks
# Safe code changes are commented out here.
  
  # begin
    uri = URI.parse(url)
    ext = File.extname(uri.path)
    ext = '.jpg' if ext.empty?  

    filename = "#{SecureRandom.hex(10)}#{ext}"
    filepath = File.join(settings.public_folder, 'uploads', filename)

    URI.open(uri, open_timeout: 5, read_timeout: 5) do |image|
      raise "Not an image!" unless image.content_type.start_with?('image/')
      File.open(filepath, 'wb') do |file|
        file.write(image.read)
      end
    end
    session[:profile_image] = "/uploads/#{filename}"
    puts session[:profile_image]
    erb :profile

  # rescue => e
  #  status 400
  #   "Error fetching image: #{e.message}"
  # end
  
end

post '/profile/file' do 
end


get '/logout' do
  session.clear
  redirect '/'
end
