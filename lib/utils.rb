# Monkey patching of String Class 
class String
    def to_b
        !self.to_i.zero?
    end
end