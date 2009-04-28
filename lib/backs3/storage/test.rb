class Backs3::Storage::Test < Backs3::Storage::Base
  def initialize(options = {})
    super(options)
    @store = {}
  end

  def store(name, value)
    if value.respond_to?(:read)
      @store[name] = value.read
    else
      @store[name] = value
    end
  end

  def read(name)
    if block_given?
      yield @store[name]
    else
      @store[name]
    end
  end

  def delete(name)
    @store.delete(name)
  end

  def exists?(name)
    @store.has_key?(name)
  end

  def list(path = nil)
    @store.map do |k,v|
      k
    end
  end
end