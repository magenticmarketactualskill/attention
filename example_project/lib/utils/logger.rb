module Logger
  def self.log(message)
    puts "[#{Time.now}] #{message}"
  end
end
