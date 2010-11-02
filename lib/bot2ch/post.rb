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

    def standard_score
      @standard_score ||=
        (self.score - self.thread.average_score) * 10 / self.thread.deviation
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

    def fix_color
      self.color = "Red" if self.score > 2
      self.color = "Navy" if self.is_owner
    end

  end

  class Post::Deleted < Post
    def body
      ''
    end
  end

end
