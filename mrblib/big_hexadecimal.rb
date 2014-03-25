module Bnet

  class BigHexadecimal

    class << self
      def clean_digits(digits)
        digits.pop while (digits.length > 1 && (digits.last.nil? || digits.last == 0))
        digits
      end

      def normalize_digits(digits, base)
        clean_digits(digits)

        cursor = 0

        loop do
          break if cursor >= digits.length && digits.last < base

          v_current = digits[cursor] || 0
          v_next = digits[cursor + 1] || 0

          if v_current < 0
            loop do
              break if v_current >= 0
              v_next -= 1
              v_current += base
            end
            digits[cursor] = v_current
            digits[cursor + 1] = v_next
          elsif v_current >= base
            c, digits[cursor] = v_current.divmod base
            digits[cursor + 1] = v_next + c
          end

          cursor = cursor + 1

        end

        clean_digits(digits)
        digits
      end
    end

    BASE = 16

    def initialize(hex_string_or_digits, skip_normalize = false)
      hex_string_or_digits = [hex_string_or_digits] if hex_string_or_digits.is_a? Fixnum

      if hex_string_or_digits.is_a? Array
        @is_minus = false
        if skip_normalize
          @digits = hex_string_or_digits.dup
        else
          @digits = self.class.normalize_digits(hex_string_or_digits, BASE)
        end
      else
        @is_minus = hex_string_or_digits =~ /^-/
        @digits = hex_string_or_digits.gsub(/^-/, '').gsub(/^0+/, '').split(//).reverse.map{ |v| v.to_i(BASE) }
        @digits.push(0) if @digits.empty?
      end
    end

    ZERO = BigHexadecimal.new 0
    ONE = BigHexadecimal.new 1
    TWO = BigHexadecimal.new 2

    def +(other)
      if self.minus? && other.minus?
        return (self.sign_reversed + other.sign_reversed).sign_reversed
      elsif self.minus?
        return other - self.sign_reversed
      elsif other.minus?
        return self - other.sign_reversed
      end

      if self.safe_for_plus? && other.safe_for_plus?
        return BigHexadecimal.new(self.to_i + other.to_i)
      end

      return other + self if self.length < other.length

      result_digits = self.digits.dup
      other.digits.each_with_index do |v1, index|
        result_digits[index] += v1
      end

      BigHexadecimal.new result_digits
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

      if self.safe_for_plus? && other.safe_for_plus?
        return BigHexadecimal.new(self.to_i - other.to_i)
      end

      result_digits = self.digits.dup
      other.digits.each_with_index do |v1, index|
        result_digits[index] -= v1
      end

      BigHexadecimal.new result_digits
    end

    def *(other)
      if self.minus? && other.minus?
        return self.sign_reversed * other.sign_reversed
      elsif self.minus?
        return (self.sign_reversed * other).sign_reversed
      elsif other.minus?
        return (self * other.sign_reversed).sign_revsersed
      end

      if self.safe_for_multiply? && other.safe_for_multiply?
        return BigHexadecimal.new(self.to_i * other.to_i)
      elsif self.safe_for_multiply?
        return other * self
      elsif other.safe_for_multiply?
        return ZERO if other == ZERO
        return self if other == ONE
        return self.double if other == TWO
      end

      result_digits = Array.new(self.length / 2 + other.length / 2)

      self.digits.each_slice(2).with_index do |pair0, i|
        other.digits.each_slice(2).with_index do |pair1, j|
          v0 = (pair0[1] || 0) * BASE + (pair0[0] || 0)
          v1 = (pair1[1] || 0) * BASE + (pair1[0] || 0)
          result_digits[i + j] = (result_digits[i + j] || 0) + v0 * v1
        end
      end

      result_digits = result_digits.map do |v|
        v.nil? ? [0, 0, 0] : v.divmod(BASE).reverse
      end.flatten

      BigHexadecimal.new result_digits

    end

    def /(other)
      self.divmod(other)[0]
    end

    def %(other)
      self.divmod(other)[1]
    end

    def divmod(other)
      raise StandardError.new('div by zero') if other == ZERO

      if self.safe_for_multiply? && other.safe_for_multiply?
        return self.to_i.divmod(other.to_i).map{ |v| BigHexadecimal.new v }
      end

      case other
      when ZERO then raise StandardError.new('div by zero')
      when ONE then [self, ZERO]
      when TWO then [self.half, self.even? ? ZERO : ONE]
      else
        div, mod = ZERO, self
        loop do
          break if mod < other
          mod = mod - other
          div = div + ONE
        end
        [div, mod]
      end
    end

    def **(other)
      return ONE if other == ZERO

      if other.even?
        (self ** other.half).square
      else
        self * (self ** (other - ONE))
      end

    end

    def square
      self * self
    end

    def half
      return self.sign_reversed.half.sign_reversed if self.minus?

      return BigHexadecimal.new(self.to_i >> 1) if self.safe_for_plus?

      bits = @digits.map do |v|
        c = v.to_s(2)
        (("0" * (4 - c.length)) + c).reverse
      end.join('').split(//)

      bits.shift

      digits = bits.each_slice(4).map { |v| v.join('').reverse.to_i(2) }

      BigHexadecimal.new digits, true
    end

    def double
      return self.sign_reversed.double.sign_reversed if self.minus?

      return BigHexadecimal.new(self.to_i << 1) if self.safe_for_plus?

      bits = @digits.map do |v|
        c = v.to_s(2)
        (("0" * (4 - c.length)) + c).reverse
      end.join('').split(//)

      bits.unshift('0')

      digits = bits.each_slice(4).map { |v| v.join('').reverse.to_i(2) }

      BigHexadecimal.new digits, true

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
        return other.sign_reversed < self.sign_reversed
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

    def digit_at(index)
      @digits[index] || 0
    end

    def digits
      @digits
    end

    def to_s
      "#{self.minus? ? '-' : ''}#{@digits.map{ |v| v.to_s(BASE) }.reverse.join('')}"
    end

    def to_bin
      raise StandardError.new('to_bin not implemented for minus number') if self.minus?

      self.to_s.pack('H*')
    end

    def length
      @digits.count
    end

    def minus?
      @is_minus
    end

    def even?
      self.digit_at(0) % 2 == 0
    end

    def odd?
      !even?
    end

    def safe_for_plus?
      self.length <= 7
    end

    def safe_for_multiply?
      self.length <= 3
    end

    def to_i
      self.to_s.to_i(16)
    end

  end

end
