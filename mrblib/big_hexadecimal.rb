module Bnet

  class BigHexadecimal
    def minus?
      @is_minus
    end

    def digits
      @digits
    end

    def initialize(hex_string)
      @is_minus = hex_string =~ /^-/
      @digits = hex_string.gsub(/^-/, '').gsub(/^0+/, '').split(//).reverse
      @digits.push(0) if @digits.empty?
    end

    BASE = 16
    ZERO = BigHexadecimal.new('0')
    ONE = BigHexadecimal.new('1')

    def +(other)
      if self.minus? && other.minus?
        return (self.sign_reversed + other.sign_reversed).sign_reversed
      elsif self.minus?
        return other - self.sign_reversed
      elsif other.minus?
        return self - other.sign_reversed
      end

      result_digits = Array.new([other.length, self.length].max).each_with_index.map do |_, index|
        self.digits[index].to_i(BASE) + other.digits[index].to_i(BASE)
      end

      BigHexadecimal.new self.class.normalize_digits(result_digits, BASE).map{ |v| v.to_s(BASE) }.reverse.join('')
    end

    def -(other)
      if self.minus? && other.minus?
        return (self.sign_reversed - other.sign_reversed).sign_reversed
      elsif self.minus?
        return (self.sign_reversed + other).sign_reversed
      elsif other.minus?
        return (self + other.sign_reversed).sign_reversed
      end

      if self < other
        return (other - self).sign_reversed
      end

      result_digits = Array.new([other.length, self.length].max).each_with_index.map do |_, index|
        self.digits[index].to_i(BASE) - other.digits[index].to_i(BASE)
      end

      BigHexadecimal.new self.class.normalize_digits(result_digits, BASE).map{ |v| v.to_s(BASE) }.reverse.join('')
    end

    def *(other)
      if self.minus? && other.minus?
        return self.sign_reversed * other.sign_reversed
      elsif self.minus?
        return (self.sign_reversed * other).sign_reversed
      elsif other.minus?
        return (self * other.sign_reversed).sign_revsersed
      end

      result_digits = Array.new(self.length + other.length)

      (0 ... self.length).each do |i|
        (0 ... other.length).each do |j|
          result_digits[i + j] = self.digits[i].to_i(BASE) * other.digits[j].to_i(BASE)
        end
      end

      BigHexadecimal.new self.class.normalize_digits(result_digits, BASE).map{ |v| v.to_s(BASE) }.reverse.join('')
    end

    def /(other)
      self.divmod(other)[0]
    end

    def %(other)
      self.divmod(other)[1]
    end

    def divmod(other)
      div = ZERO
      mod = self
      loop do
        break if mod < other
        mod = mod - other
        div = div + ONE
      end
      [div, mod.dup]
    end

    def **(other)
      result = nil, counter = other
      loop do
        break if counter == ZERO
        result = self * self
        counter = counter - ONE
      end
      result
    end

    def abs
      self.minus? ? self.sign_reversed : BigHexadecimal.new(self.to_s)
    end

    def sign_reversed
      if self.minus?
        BigHexadecimal.new(self.to_s.sub(/^-/, ''))
      else
        BigHexadecimal.new("-#{self.to_s}")
      end
    end

    def <(other)
      if self.minus? && other.minus?
        return other.abs < self.abs
      elsif self.minus?
        return true
      elsif other.minus?
        return false
      end

      return true if self.length < other.length
      return false if self.length > other.length

      self.to_s < other.to_s
    end

    def ==(other)
      self.to_s == other.to_s
    end

    def dup
      BigHexadecimal.new(self.to_s)
    end

    def to_s
      "#{self.minus? ? '-' : ''}#{@digits.reverse.join('')}"
    end

    def to_bin
      raise StandardError.new('to_bin not implemented for minus number') if self.minus?

      @digits.reverse.pack('H*')
    end

    def length
      @digits.count
    end

    class << self
      def normalize_digits(digits, base)
        cursor = 0
        loop do
          break if cursor >= digits.length && digits.last < 16
          v = digits[cursor].to_i

          if v < 0
            loop do
              break if v >= 0
              digits[cursor + 1] = digits[cursor + 1].to_i - 1
              v += base
            end
          else
            c, v = v.divmod base
            if c > 0
              digits[cursor + 1] = digits[cursor + 1].to_i + c
            end
          end

          digits[cursor] = v
          cursor = cursor + 1
        end

        digits
      end
    end

  end

end
