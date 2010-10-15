class Hash
  def symbolize_keys
    returnval = {}
    self.each do |k, v|
      returnval[k.to_sym] = v
    end
    returnval
  end

  def symbolize_keys!
    self.replace(self.symbolize_keys)
  end
end