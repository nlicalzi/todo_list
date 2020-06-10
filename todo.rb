require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret' # change to a long hi-entropy env var
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end 

get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

get "/lists/new" do
  session[:lists] << { name: "New List", todos: [] } # use a form for this
  redirect "/lists"
end
