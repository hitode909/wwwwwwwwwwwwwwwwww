# -*- Coding: utf-8 -*-
require 'digest/md5'
require 'open-uri'

module CachedResource

  private
  def resource(path, force = false)
    cache = '/tmp/' + Digest::MD5.hexdigest(path.to_s)
    File.delete(cache) if force and File.exists?(cache)

    if File.exists?(cache) and Time.now - File.ctime(cache) < 10 * 60
      open(cache)
    else
      File.delete(cache) if File.exists?(cache)
      download(path, cache)
      open(cache)
    end
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

  module_function :resource, :download

end
