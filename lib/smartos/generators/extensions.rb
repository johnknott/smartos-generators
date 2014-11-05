class String
  def strip_indent
    self.gsub(/^#{self[/\A\s*/]}/, '')
  end
end