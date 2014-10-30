class Slop
  def strip_indent(str)
    str.gsub(/^#{str[/\A\s*/]}/, '')
  end
end