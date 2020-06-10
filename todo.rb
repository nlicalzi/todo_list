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

# view all lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# return an error msg. if the name is invalid, or nil if valid.
def error_for_list_name(name)
  if !(1..100).cover? name.size
    return "List name must be between 1-100 characters."
  elsif session[:lists].any? { |list| list[:name] == name }
    return "List name must be unique."
  end
end

# create a new list 
post "/lists" do
  list_name = params[:list_name].strip

  if error = error_for_list_name(list_name)
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "The list has been created."
    redirect "/lists"
  end  
end

# render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end
