require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

# return an error msg. if list name is invalid, or return nil if valid.
def error_for_list_name(name)
  if !(1..100).cover? name.size
    return "List name must be between 1-100 characters."
  elsif session[:lists].any? { |list| list[:name] == name }
    return "List name must be unique."
  end
end

# return an error msg if todo name is invalid, or return nil if valid
def error_for_todo_name(list, name)
  if !(1..100).cover? name.size
    return "Todo name must be between 1-100 characters."
  elsif list[:todos].any? { |todo| todo == name }
    return "Todo name must be unique."
  end
end

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

# view individual list and todos
get "/lists/list/:id" do
  # retrieve list from session[:lists] using its index and :id
  id = params[:id].to_i
  @list = session[:lists][id]
  erb :list, layout: :layout
end

# render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# create a new list 
post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "The list has been created."
    redirect "/lists"
  end  
end

# create a new todo in a list, or update list name
post "/lists/list/:id" do
  id = params[:id].to_i
  @list = session[:lists][id]

  if params[:todo_name] # if we're making a todo list..
    todo_name = params[:todo_name].strip

    error = error_for_todo_name(@list, todo_name)
    if error
      session[:error] = error
      erb :list, layout: :layout
    else
      @list[:todos] << todo_name
      session[:success] = "The todo has been created."
      redirect "/lists/list/#{id}"
    end

  elsif params[:list_name] # if we're editing a list name...
    list_name = params[:list_name].strip

    error = error_for_list_name(list_name)
    if error
      session[:error] = error
      erb :edit_list, layout: :layout
    else
      @list[:name] = list_name
      session[:success] = "The list has been updated."
      redirect "/lists/list/#{id}"
    end  
  end
end

# edit an existing todo list
get "/lists/list/:id/edit" do
  id = params[:id].to_i
  @list = session[:lists][id]

  erb :edit_list, layout: :layout
end

# delete an existing list

post "/lists/list/:id/destroy" do
  id = params[:id].to_i
  session[:lists].delete_at(id)
  session[:success] = "The list has been deleted."
  redirect "/lists"
end