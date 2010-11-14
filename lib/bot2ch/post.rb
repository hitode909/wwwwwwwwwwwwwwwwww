# -*- coding: utf-8 -*-

module Bot2ch
  class Post
    attr_accessor :thread, :name, :email, :date, :body, :index, :user_id, :thread, :score,:parents,:children,:color

    def is_owner
      self.thread.post_at(1).user_id == self.user_id
    end

    def to_html
      self.fix_color
      puts '<dl class="thread">'
      puts '<dt hb:annotation="true">'
      puts self.index
      puts '：<font color="green"><b>'
      puts '<span>'

      puts self.name
      puts '</span>'
      puts '</b></font>：'
      puts self.date
      puts self.is_owner ? '<span class="owner">' : '<span>'
      puts 'ID:'
      puts self.user_id
      puts '</span>'

      puts '</dt><dd>'
      #      puts '<font Color=' + "#{self.color}" + '>'
      puts self.body
      #      puts '</font>'
      puts '</dd></dl>'
    end

    def body_xhtml
      self.body.gsub(/<br>/, "<br/>").gsub(/^sssp.*/, '').gsub(/<\/?a[^>]*>/, '').gsub(/h?ttp[^ ]+/) {|url|
        url = 'h' + url unless url.match(/^http/)
        option = url.match(/(jpg|png|gif|bmp)$/) ? 'image' : 'title'
        "[#{url}:#{option}]"
      }.gsub(/ID:\w+/) {|id|
        "[]#{id}[]"
      }# .gsub(/&/, "&amp;")
    end

    def initialize
      @score  =  0
      @parents = []
      @children = []
      @color = 'black'
    end

    def url
      "#{self.thread.url}/#{self.index}"
    end

    def body_text
      begin
      CGI.unescapeHTML(self.body.gsub(/<br>/, '').gsub(/http[^\s]+/, '').gsub(/<\/?a[^>]*>/, ''))
      rescue
        p self
        return ""
      end
    end

    def self.register(*names)
      names.each{|name|
        define_method("standard_#{name}".to_sym){
          @cache ||= {}
          @cache[name] ||=
          (self.send(name) - self.thread.send("average_#{name}".to_sym)) * 10 / self.thread.send("deviation_#{name}".to_sym)
         }
       }
    end

    def set_child(post)
      return if @children.include?(post) or post.index < self.index
      @children << post
#      @score +=1
    end

    def set_parent(post)
      return if @parents.include?(post) or post.index > self.index
      @parents << post
      # @score +=1
    end

    def scored?
      self.score > 0
    end

    def primary?
      self.parents.empty? && scored?
    end
    
    def descendant
      []
      # warn self.index
      #       return [] if @children.empty?
      #       p self.children.each{|popopo|
      #         p popopo.descendant
      #       }
      #       aaa = @children.concat(@children.map(&:descocendant).flatten)
      # p aaa
      # aaa.uniq.sort_by{|post| post.index}
    end

    def add_mention(index)
      @mentions ||= []
      @mentions << index if index
      @mentions
    end

    def mentions
      unless defined? @mentions
        self.thread.collect_mentions
      end
      return @mentions
    end

    def mentions_count
      self.mentions.length
    end

    def fix_color
      self.color = "Red" if self.score > 2
      self.color = "Navy" if self.is_owner
    end

    def html_classes
      list = []
      list << 'owner' if self.is_owner
      list << 'big' if self.standard_score > 20
      list
    end

  end

  class Post::Deleted < Post
    def body
      ''
    end
  end

end
