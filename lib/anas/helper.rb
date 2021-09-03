
class ::Hash
  # via https://stackoverflow.com/a/25835016/2257038
  def stringify_keys
    h = self.map do |k,v|
      v_str = if v.instance_of? Hash
                v.stringify_keys
              else
                v
              end

      [k.to_s, v_str]
    end
    Hash[h]
  end

  # via https://stackoverflow.com/a/25835016/2257038
  def symbol_keys
    h = self.map do |k,v|
      v_sym = if v.instance_of? Hash
                v.symbol_keys
              else
                v
              end

      [k.to_sym, v_sym]
    end
    Hash[h]
  end

  def value_to_string!
    self.each { |k, v| self[k] = v.to_s }
  end
end

class String
  def camelize
    return self if self !~ /_/ && self =~ /[A-Z]+.*/
    split('_').map{|e| e.capitalize}.join
  end

  def classify
    Object.const_get(self)
  end

  def underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end
end
