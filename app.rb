require 'sinatra'

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
  "you just send a login request with #{username} and #{password}"
end

post '/register' do
  username = params["username"]
  password = params["password"]
  "you just send a register request with #{username} and #{password}"
end
