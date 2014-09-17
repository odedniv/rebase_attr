require "rebase_attr/version"

module RebaseAttr
  READABLE_MAPPING = { '0' => 'x', '1' => 'y', 'l' => 'w', 'o' => 'z' }

  module Generator
    def rebase_attr(*attributes, to: nil, from: nil, convert: nil, deconvert: nil, readable: nil)
      raise ArgumentError, "#rebase_attr must receive :to" unless to
      raise ArgumentError, "#rebase_attr does not accept a block, did you mean to use :convert?" if block_given?
      raise ArgumentError, "#rebase_attr does not allow :readable option with bases higher than 32, #{to} given" if readable and to > 32

      attributes.each do |attr|
        # encoders & decoders
        define_singleton_method :"encode_#{attr}" do |decoded|
          result = decoded
          raise TypeError, "decoded value must implement #to_i, #{result.inspect} given" unless result.respond_to?(:to_i)
          result = result.to_i(from || 10) if result.is_a?(String)
          result = result.to_s(to)
          READABLE_MAPPING.each { |s, d| result.gsub!(/#{s}/i, d) } if readable # gsub! to conserve memory
          result = convert.respond_to?(:call) ? convert.call(result) : result.public_send(convert) if convert
          result
        end
        define_method :"encode_#{attr}" do |decoded|
          self.class.send(:"encode_#{attr}", decoded)
        end

        define_singleton_method :"decode_#{attr}" do |encoded|
          result = encoded
          if deconvert
            result = result.clone # deconvert to not modify outside variable
            result = deconvert.respond_to?(:call) ? deconvert.call(result) : result.public_send(deconvert)
          end
          raise TypeError, "encoded value must implement #to_i, #{result.inspect} given" unless result.respond_to?(:to_i)
          if readable
            result = result.clone # not modifying outside variable
            READABLE_MAPPING.each { |s, d| result.gsub!(/#{d}/i, s) } # gsub! to conserve memory
          end
          result = result.to_i(to)
          result = result.to_s(from) if from
          result
        end
        define_method :"decode_#{attr}" do |encoded|
          self.class.send(:"decode_#{attr}", encoded)
        end

        # readers & writers
        begin
          alias_method :"#{attr}_without_rebase", attr
        rescue NameError # reader does not exist
        else
          define_method attr do
            send(:"encode_#{attr}", send(:"#{attr}_without_rebase"))
          end
        end

        begin
          alias_method :"#{attr}_without_rebase=", :"#{attr}="
        rescue NameError # writer does not exist
        else
          define_method :"#{attr}=" do |encoded|
            send(:"#{attr}_without_rebase=", send(:"decode_#{attr}", encoded))
          end
        end
      end
    end
  end
end

class Module
  include RebaseAttr::Generator
end