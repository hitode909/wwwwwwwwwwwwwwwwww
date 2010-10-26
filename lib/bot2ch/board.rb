module Bot2ch
  class Board
    def initialize(url)
      @url = url
      @subject = "#{url}/subject.txt"
    end

    def get_threads
      threads = []
      CachedResource.resource(@subject) do |f|
        lines = f.read.toutf8
        lines.each_line do |line|
          dat, _title = line.split('<>')
          title, posts_length = *_title.scan(/^(.*)\((\d+)\)$/).first
          created_on = Time.at(dat.to_i)
          threads << Bot2ch::Thread.new("#{@url}/dat/#{dat}", title, posts_length.to_i, created_on)
        end
      end
      threads
    end

    def threads
      @threads ||= get_threads
    end
  end
end
