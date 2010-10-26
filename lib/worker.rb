require 'timeout'

class Worker
  attr_accessor :concurrency, :tasks, :running_tasks, :mutex
  def initialize(concurrency = 10)
    @concurrency = concurrency
    @tasks = []
    @running_tasks = []
    @mutex = Mutex.new
    run
  end

  def add(&job)
    mutex.synchronize {
      raise "block not given" unless block_given?
      tasks << job
    }
  end

  protected
  def run
    Thread.new {
      loop {
        mutex.synchronize {
          running_tasks.select!{|t|
            t.status != false
          }
          (concurrency - running_tasks.length).times{
            next if tasks.empty?
            running_tasks << Thread.new{
              begin
                timeout(10) {
                  (rand > 0.5 ? tasks.shift : tasks.pop).call(self)
                }
              rescue StandardError, TimeoutError => e
                p e
              end
            }
          }
        }
        sleep 0.1
      }
    }
  end
end
