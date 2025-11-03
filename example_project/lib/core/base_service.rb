class BaseService
  def initialize(config)
    @config = config
  end

  def execute
    raise NotImplementedError
  end
end
