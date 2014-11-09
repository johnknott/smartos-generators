# String extension. Probably shouldn't extend core classes though.
# @todo Don't modify core classes!
class String
  # Function to recreate functionality of Rails' strip_heredoc
  # @return [String] String with removed whitespace left aligned to suitable point
  def strip_indent
    self.gsub(/^#{self[/\A\s*/]}/, '')
  end
end