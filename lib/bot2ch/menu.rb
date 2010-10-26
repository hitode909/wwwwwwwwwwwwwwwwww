module Bot2ch
class Menu
    def initialize
      @bbsmenu = 'http://menu.2ch.net/bbsmenu.html'
    end

    def boards
      list = []
      reg = Regexp.new("<a href=(http://\\w+\\.2ch\\.net/\\w+)/>", Regexp::IGNORECASE) # TODO: test
      CachedResource.resource(@bbsmenu) do |f|
        f.each_line{|line|
          list << Board.new($1) if line.encode("utf-8", "sjis") =~ reg
        }
      end
      list
    end

    def get_board(subdir)
      reg = Regexp.new("href=(.+#{subdir})", Regexp::IGNORECASE)
      CachedResource.resource(@bbsmenu) do |f|
        f.each do |line|
          return Board.new($1) if line.encode("utf-8", "sjis") =~ reg
        end
      end
    end
  end
end
