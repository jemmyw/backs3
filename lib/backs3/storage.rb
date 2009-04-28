module Backs3::Storage
  def self.included(base) #:nodoc:
    base.class_eval do
      def self.lookup_storage(name, options)
        storage_class = Backs3::Storage.const_get(name.to_s.camelize)
        storage_class.new(options)
      end
    end
  end

  def storage
    @storage ||= self.class.lookup_storage(@options['storage'] || :aws, @options['storage_options'])
  end
end