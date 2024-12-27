# frozen_string_literal: true

require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/reloader'
require 'puma'
require 'json'
require 'cgi'
require 'sanitize'

FILE_PATH = 'public/memos.json'

helpers Sinatra::ContentFor

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

def get_memos(file_path)
  File.open(file_path) { |f| JSON.parse(f.read) }
end

def set_memos(file_path, memos)
  File.open(file_path, 'w') { |f| f.write(memos.to_json) }
end

get '/' do
  redirect '/memos'
end

get '/memos/new' do
  erb :new
end

get '/memos' do
  @memos = get_memos(FILE_PATH)
  erb :index
end

get '/memos/:id' do
  memos = get_memos(FILE_PATH)
  @memo = memos[params[:id]]
  if @memo
    @title = @memo['title']
    @content = @memo['content']
    erb :show
  else
    status 404
    erb :not_found
  end
end

patch '/memos/:id' do
  memos = get_memos(FILE_PATH)

  if memos.key?(params[:id])
    title = params[:title]
    content = params[:content]
    memos[params[:id]] = { 'title' => title, 'content' => content }
    set_memos(FILE_PATH, memos)
    redirect "/memos/#{params[:id]}"
  else
    status 404
    erb :not_found
  end
end

post '/memos' do
  title = params[:title]
  content = params[:content]

  memos = get_memos(FILE_PATH)
  id = SecureRandom.uuid
  memos[id] = { 'title' => title, 'content' => content }
  set_memos(FILE_PATH, memos)

  redirect '/memos'
end

get '/memos/:id/edit' do
  memos = get_memos(FILE_PATH)
  @id = params[:id]
  @memo = memos[@id]

  if @memo
    @title = memos[@id]['title']
    @content = memos[@id]['content']
    erb :edit
  else
    status 404
    erb :not_found
  end
end

delete '/memos/:id' do
  memos = get_memos(FILE_PATH)
  memos.delete(params[:id])
  set_memos(FILE_PATH, memos)

  redirect '/memos'
end

not_found do
  erb :not_found
end
