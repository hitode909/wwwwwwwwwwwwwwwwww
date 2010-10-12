# -*- coding: utf-8 -*-

require 'rubygems'
$:.unshift('lib')
require 'bot2ch'
require 'MeCab'
require 'generator'

menu = Bot2ch::Menu.new
board = menu.get_board('news4vip')
thread = board.threads.select{|th| th.title =~ /キーボード弾いて/}.first
# thread = Bot2ch::Thread.new('http://yuzuru.2ch.net/test/read.cgi/news4vip/1286724144/l50', '声優だけど質問ある？')

# TODO
# 表示するときに，>>で参照されてるやつをすぐ下にもってくる
# ただし，親のスコアのほうが大きいときだけもってくる

# トピック抽出?????????

# 表示の工夫，画像展開，リンク

# 1の発言
user_id = thread.post_at(1).user_id
thread.posts.select{|post| post.user_id == user_id}.each{|post|
  post.score += 1
}

# 母子参照
thread.posts.each{ |post|
  post.body.scan(/&gt;&gt;(\d+)/).each{|match|

    number = match[0].to_i
    parent = thread.post_at(number)

    thread.set_family(parent,post) if parent 
      
  }
}

[/ttp/].each{|rule|
  thread.posts.each{|post|
    post.score += post.body.scan(rule).length
  }
}

thread.posts.select{|post| post.children.length > 0 }.each{|post|
  p post.index
  p post.children.map{|post|
     post.index
  }
}

exit
puts "<html><title>#{thread.title}</title><body>"

# スコアついてるやつ表示
thread.posts.select{|post| post.score > 0}.each{|post|
  post.to_html
  # puts "<font size='3em'><div>#{post.index}<br>#{post.body}</font></div>"
}
puts "</body></html>"
