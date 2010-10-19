class TextUtilities
  
  def TextUtilities.wrap(text, width, new_line = '<br />')
    wrapped_text = ""
    count = 0
    in_tag = 0
    text.each_char do |e|
      in_tag +=1 if e == '<'
      unless in_tag > 0
        if count >= width and e == ' ' # use regexp?
          wrapped_text << new_line
          count = 0
        end
          count += 1
      end
      in_tag -=1 if e == '>'
      wrapped_text << e
    end
    wrapped_text
  end
  
end
