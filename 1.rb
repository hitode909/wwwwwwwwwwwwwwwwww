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
    post.score+= 1
    number = match[0].to_i
    parent = thread.post_at(number)
    parent.score+=1 if parent
  }
}

[/ttp/].each{|rule|
  thread.posts.each{|post|
    post.score += post.body.scan(rule).length
  }
}

puts "<html><title>#{thread.title}</title><body>"

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

puts "<html><title>#{thread.title}</title><body>"
puts '<style> .owner { color: pink; font-weight: bold; } </style>'


# スコアついてるやつ表示
thread.posts.select{|post| post.score > 0}.each{|post|
  post.to_html
  # puts "<font size='3em'><div>#{post.index}<br>#{post.body}</font></div>"
}
puts "</body></html>"

exit
[/麺/, /こってり/, /http/].each{|rule|
  thread.posts.each{|post|
    post.score += post.body.scan(rule).length
  }
}




if false
  count = Hash.new{0}
parse(thread.all_body_text).select{|n|
  n.feature =~ /^名詞/
}.each{|n|
  count[n.surface]+= 1
}

require 'pp'
count.each_pair.map{|a, b| [a, b]}.sort_by{|a| a[1]}.each{|pair|
  puts "#{pair[0]}\t#{pair[1]}"
}
exit
def parse(text)
  c = MeCab::Tagger.new("-O wakati")
  n = c.parseToNode(text)

  Generator.new{|g|
    while n do
      g.yield n
      n = n.next
    end
  }
end
  end
