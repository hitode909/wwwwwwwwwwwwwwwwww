# -*- coding: utf-8 -*-

require 'rubygems'
$:.unshift('lib')
require 'bot2ch'
require 'blog'

unless ENV['hatena_username'] and ENV['hatena_password']
  raise '環境変数 hatena_usernameとhatena_passwordを設定してください'
end

menu = Bot2ch::Menu.new
board = menu.get_board('news4vip')

thread = board.threads.sort_by{|t| t.speed}.reverse[0..30].sample

# 1の発言
iti = 100
user_id = thread.post_at(1).user_id
thread.posts.select{|post| post.user_id == user_id}.each{|post|
  post.score += iti
  iti /= 2
}

require "pp"
pp thread.keywords

# スコア付け
thread.keywords.keys.each{|rule|
  next if rule.match(/\./)
  thread.posts.select{|post| post.body.match rule }.each{|post|
    post.score += thread.keywords[rule].to_i
  }
}

# 記事投稿 いきなり投稿されるので気をつける!!!!!
writer = Blog::HatenaDiaryWriter.new(ENV['hatena_username'], ENV['hatena_password'])
entry = Blog::Entry.new(thread.title,thread.posts.select{|post| post.standard_score  >= 10 })
puts entry.title
writer.post(entry)
