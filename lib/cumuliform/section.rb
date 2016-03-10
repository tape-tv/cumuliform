module Cumuliform
  # @api private
  class Section
    attr_reader :name, :imports, :items

    def initialize(name, imports)
      @name = name
      @imports = imports
      @items = {}
    end

    def []=(name, item)
      items[name] = item
    end

    def [](name)
      merged[name]
    end

    def each(&block)
      merged.each(&block)
    end

    def member?(name)
      merged.member?(name)
    end

    def empty?
      merged.empty?
    end

    def merged
      imports.reduce({}) { |merged, import|
        import.get_section(name).merged.merge(merged)
      }.merge(items)
    end
  end
end
