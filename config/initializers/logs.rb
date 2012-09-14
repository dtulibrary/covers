cache_logfile = File.open("#{Rails.root}/log/cache.log", 'a')
cache_logfile.sync = true
CACHE_LOG = Cachelog.new(cache_logfile)