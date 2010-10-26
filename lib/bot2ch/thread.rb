# -*- coding: utf-8 -*-
module Bot2ch
  class Thread
    attr_accessor :dat, :title, :created_on, :posts_length

    def initialize(url, title, posts_length, created_on = Time.now)
      @dat = url
      @title = title.strip
      @posts_length = posts_length
      @created_on = created_on
    end

    def url
      list = @dat.split('/').reject{|f| f == ''}
      "http://#{list[1]}/test/read.cgi/#{list[2]}/#{list[4].scan(/\d/).join}"
    end

    def get_images
      images = []
      downloaders = [NormalImageDownloader, ImepitaDownloader]
      CachedResource.resource(@dat) do |f|
        lines = f.read.toutf8
        lines.each do |line|
          contents = line.split('<>')[3]
          while contents =~ /\/\/[-_.!~*\'()a-zA-Z0-9;\/?:\@&=+\$,%#]+/i
            url = "http:#{$&}"
            contents = $'
            image_downloader = downloaders.find { |d| d.match(url) }
            next unless image_downloader
            images << image_downloader.new(url)
          end
        end
      end
      images
    end

    def all_body_text
      self.posts.map(&:body_text).join("\n")
    end

    # iは1から
    def post_at(i)
      posts[i-1]
    end

    def posts
      return @posts if @posts
      index = 1
      CachedResource.resource(@dat) do |f|
        lines = f.read.toutf8
        @posts = lines.each_line.map {|line|
          begin
            raise if line == "あぼーん"
            post = Post.new
            post.thread = self
            name, email, _date, body = line.split('<>')
            date = Time.local(*_date.scan(/\d+/)[0..5])
            user_id = _date.scan(/ID:(.*)$/).flatten.first
            %w{name email date user_id body index}.each{ |key|
              eval "post.#{key} = #{key}"
            }
            post.thread = self
            index += 1
            post
          rescue
            # warn "failed to parse: #{line}"
            post = Post::Deleted.new
            post.thread = self
            index += 1
            post
          end
        }
      end
    end

    def set_family(parent,child)
      return unless child.index > parent.index
      parent.set_child(child)
      child.set_parent(parent)
    end

    def dat_no
      File.basename(@dat, '.dat')
    end

    def speed
      self.posts_length / (Time.now - self.created_on) * (3600 * 24)
    end

    def title_and_length
      "#{title}(#{posts_length})"
    end
  end
end