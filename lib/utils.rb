# Monkey patching of String Class 
class String
    def to_b
        !self.to_i.zero?
    end

    def get_prefix_of_code
        self.gsub(/[0-9]/, '')
    end
end