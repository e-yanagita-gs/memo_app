# frozen_string_literal: true

require 'sinatra'
require 'sinatra/content_for'
require 'sinatra/reloader'
require 'pg'
require 'puma'
require 'cgi'

helpers Sinatra::ContentFor

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

def conn
  @conn ||= PG.connect(dbname: 'memo_app')
end

configure do
  result = conn.exec("SELECT * FROM information_schema.tables WHERE table_name = 'memos'")
  conn.exec('CREATE TABLE memos (id SERIAL PRIMARY KEY, title text, content text)') if result.values.empty?
end

def read_memos
  conn.exec('SELECT * FROM memos')
end

def read_memo(id)
  result = conn.exec_params('SELECT * FROM memos WHERE id = $1 LIMIT 1;', [id])
  result.tuple_values(0)
end

def post_memo(title, content)
  result = conn.exec_params('INSERT INTO memos (title, content) VALUES ($1, $2) RETURNING id;', [title, content])
  result[0]['id']
end

def edit_memo(title, content, id)
  conn.exec_params('UPDATE memos SET title = $1, content = $2 WHERE id = $3;', [title, content, id])
end

def delete_memo(id)
  conn.exec_params('DELETE FROM memos WHERE id = $1;', [id])
end

get '/' do
  redirect '/memos'
end

get '/memos/new' do
  erb :new
end

get '/memos' do
  @memos = read_memos
  erb :index
end

get '/memos/:id' do
  memo = read_memo(params[:id])
  if memo
    @title = memo[1]
    @content = memo[2]
    erb :show
  else
    status 404
    erb :not_found
  end
end

patch '/memos/:id' do
  memo = read_memo(params[:id])

  if memo
    title = params[:title]
    content = params[:content]
    id = params[:id]
    edit_memo(title, content, id)
    redirect "/memos/#{params[:id]}"
  else
    status 404
    erb :not_found
  end
end

post '/memos' do
  title = params[:title]
  content = params[:content]
  id = post_memo(title, content)
  redirect "/memos/#{id}"
end

get '/memos/:id/edit' do
  memo = read_memo(params[:id])

  if memo
    @title = memo[1]
    @content = memo[2]
    erb :edit
  else
    status 404
    erb :not_found
  end
end

delete '/memos/:id' do
  delete_memo(params[:id])
  redirect '/memos'
end

not_found do
  erb :not_found
end
