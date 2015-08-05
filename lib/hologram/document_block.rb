module Hologram
  class DocumentBlock
    COMMENT_REGEX = /^\s*---\s(.*?)\s---[\r]?$/m

    attr_accessor :name, :parent, :children, :title, :categories, :markdown, :config, :heading, :errors

    def initialize(config = nil, markdown = nil)
      @children = {}
      @errors = []
      set_members(config, markdown) if config and markdown
    end

    def self.from_comment(comment)
      comment_match = COMMENT_REGEX.match(comment)
      return if !comment_match

      markdown = comment.sub(comment_match[0], '')
      config = YAML::load(comment_match[1])

      self.new(config, markdown)
    rescue ArgumentError, Psych::SyntaxError
      raise CommentLoadError, "Could not parse comment:\n#{comment}"
    end

    def set_members(config, markdown)
      @config   = config
      @name     = config['name']
      @categories = Array(config['category'] || config['categories'])
      @title    = h(config['title'])
      @parent   = config['parent']
      @markdown = markdown

      if @name.nil?
        @name = @title.gsub(' ', '_')
      end
    end

    def get_hash
      {:name => @name,
       :parent => @parent,
       :categories => @categories,
       :title => @title
      }
    end

    def is_valid?
      errors << 'Missing required category and/or parent config value' if !categories and !parent
      errors << 'Missing name or title config value' if !name and !title
      errors << 'Missing required markdown' if !markdown
      errors.empty?
    end

    # sets the header tag based on how deep your nesting is

    def markdown_with_heading(heading = 1, opts={})
      include_sub_nav = opts[:include_sub_nav] || false

      output = "<div class=\"novu-box-wrapper #{@title}\">"
      output += "<div class=\"title one-line\">"
      output += "<h#{heading.to_s} id=\"#{@name}\" class=\"#{css_class_name}\">#{@title}</h#{heading.to_s}>"
      output += "</div>"

      if include_sub_nav && !children.empty?
        output += "<ul class=\"section-nav\">"
        children.values.each do |child|
          output += "<li><a href=\"\##{child.name}\">#{child.title}</a></li>"
        end
        output += "</ul>"
      end
      output += @markdown + "</div><br />"
    end

    private

    def css_class_name
      'styleguide'
    end
  end
end

