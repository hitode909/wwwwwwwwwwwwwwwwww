# -*- Coding: utf-8 -*-
require 'digest/md5'
require 'open-uri'

module CachedResource

  private
  def flush(path)
    cache = '/tmp/' + Digest::MD5.hexdigest(name.to_s)
    File.delete(cache)
  end

  def resource(name, *rest, &block)
    cache = '/tmp/' + Digest::MD5.hexdigest(name.to_s)
    File.delete(cache) if File.exists?(cache) and Time.now - File.ctime(cache) > 10 * 60

    download(name, cache) unless File.exists?(cache)
    open(cache, *rest, &block)
  end

  def download(url, file)
    open(file, 'w') {|local|
      got = open(url) {|remote|
        local.write(remote.read)
      }
    }
  rescue Exception, TimeoutError => error
    File.delete(file) if File.exists?(file)
    raise error
  end

  module_function :flush, :resource, :download

end
