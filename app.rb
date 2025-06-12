require 'sinatra'

get '/' do
  erb :index
end

get '/login' do
  erb :login
end

post '/login' do
  username = params["username"]
  password = params["password"]
  "you just send a request with #{username} and #{password}"
end
