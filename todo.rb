require "sinatra"
require "sinatra/reloader" if development?
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
  elsif list[:todos].any? { |todo| todo[:name] == name }
    return "Todo name must be unique."
  end
end

# load a list, flashing an error and redirecting to /lists if invalid id
def load_list(idx)
  list = session[:lists][idx] if idx && session[:lists][idx]
  return list if list

  session[:error] = "The specified list was not found."
  redirect "/lists"
end

configure do
  enable :sessions
  set :session_secret, 'secret' # change to a long hi-entropy env var
end

helpers do 
  def todos_count(list)
    list[:todos].size
  end

  def todos_remaining_count(list)
    list[:todos].select { |todo| !todo[:completed] }.size
  end

  def todo_complete?(todo)
    todo[:completed]
  end

  def list_complete?(list)
    todos_count(list) > 0 && todos_remaining_count(list) == 0
  end

  def list_class(list)
    "complete" if list_complete?(list)
  end

  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| list_complete?(list) }

    incomplete_lists.each { |list| yield list, lists.index(list) }
    complete_lists.each { |list| yield list, lists.index(list) }
  end

  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.each(&block)
    complete_todos.each(&block)
  end

  def next_todo_id(todos)
    max = todos.map { |todo| todo[:id] }.max || 0
    max + 1
  end
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
  @list_id = params[:id].to_i
  @list = load_list(@list_id)
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

# create a new todo in a list
post "/lists/list/:id/todos" do 
  @list_id = params[:id].to_i
  @list = load_list(@list_id)

  todo_name = params[:todo_name].strip

    error = error_for_todo_name(@list, todo_name)
    if error
      session[:error] = error
      erb :list, layout: :layout
    else
      id = next_todo_id(@list[:todos])
      @list[:todos] << { id: id, name: todo_name, completed: false } 
      session[:success] = "The todo has been added."
      redirect "/lists/list/#{@list_id}"
    end
end

# update todo list name
post "/lists/list/:id" do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated."
    redirect "/lists/list/#{@list_id}"
  end  
end

# edit an existing todo list
get "/lists/list/:id/edit" do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)

  erb :edit_list, layout: :layout
end

# delete an existing list
post "/lists/list/:id/destroy" do
  @list_id = params[:id].to_i
  session[:lists].delete_at(@list_id)

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:success] = "The list has been deleted."
    redirect "/lists"
  end
end

# delete an existing todo
post "/lists/list/:list_id/todos/destroy/:id" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)

  todo_id = params[:id].to_i
  @list[:todos].reject! { |todo| todo[:id] == todo_id }

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "The todo has been deleted."
    redirect "/lists/list/#{@list_id}"
  end
end

# update todo status
post "/lists/list/:list_id/todos/:id" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)

  todo_id = params[:id].to_i
  is_completed = (params[:completed] == "true")
  todo = @list[:todos].find { |todo| todo[:id] == todo_id }

  session[:success] = "The todo has been updated."
  redirect "/lists/list/#{@list_id}"
end

# mark all todos as completed
post "/lists/list/:id/mark_all_done" do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)

  @list[:todos].each do |todo|
    todo[:completed] = true
  end

  session[:success] = "All todos have been marked as done."
  redirect "/lists/list/#{@list_id}"
end