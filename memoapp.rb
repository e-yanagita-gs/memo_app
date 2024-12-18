# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'puma'
require 'json'
require 'cgi'
require 'sanitize'

FILE_PATH = 'public/memos.json'

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
  title = Sanitize.fragment(params[:title])
  content = Sanitize.fragment(params[:content])

  memos = get_memos(FILE_PATH)
  memos[params[:id]] = { 'title' => title, 'content' => content }
  set_memos(FILE_PATH, memos)

  redirect "/memos/#{params[:id]}"
end

post '/memos' do
  title = Sanitize.fragment(params[:title])
  content = Sanitize.fragment(params[:content])

  memos = get_memos(FILE_PATH)
  id = (memos.keys.map(&:to_i).max + 1).to_s
  memos[id] = { 'title' => title, 'content' => content }
  set_memos(FILE_PATH, memos)

  redirect '/memos'
end

get '/memos/:id/edit' do
  memos = get_memos(FILE_PATH)
  @id = params[:id]
  @title = memos[params[:id]]['title']
  @content = memos[params[:id]]['content']
  erb :edit
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
