require_relative 'error'

module Cumuliform
  module Import
    def import(template)
      imports << template
    end

    def has_logical_id?(logical_id)
      (imports.reverse).inject(logical_ids.include?(logical_id)) { |found, template|
        found || template.has_logical_id?(logical_id)
      }
    end

    private

    def imports
      @imports ||= []
    end
  end

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

    def each(&block)
      merged.each(&block)
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
