require 'rebase_attr'

class RebaseTestBase
  attr_writer :x
end

# This converts options to local varaibels so they can be used inside the Class.new { }
def rebase_class(**options, &block)
  Class.new(RebaseTestBase) { rebase_attr(:x, **options, &block) }
end

describe RebaseAttr::Generator do
  #requires: decoded, encoded
  shared_examples_for "values" do
    subject(:instance) { klass.new }

    describe "reader" do
      before { instance.instance_eval { @x = decoded } }
      its(:x) { should == encoded }
    end

    describe "writer" do
      before { instance.x = encoded }
      specify { expect(instance.instance_eval { @x }).to eq(decoded) }
    end

    describe "#encode" do
      specify { expect(klass.encode_x(decoded)).to eq(encoded) }
      specify { expect(instance.encode_x(decoded)).to eq(encoded) }
    end

    describe "#decode" do
      specify { expect(klass.decode_x(encoded)).to eq(decoded) }
      specify { expect(instance.decode_x(encoded)).to eq(decoded) }
    end
  end

  # requires: from, to, convert_name, convert_block, decoded_default, decoded_from,
  #           encoded_default, encoded_convert
  shared_context "all except readable" do
    context "default" do
      let(:klass) { rebase_class to: to }
      let(:decoded) { decoded_default }
      let(:encoded) { encoded_default }
      it_behaves_like "values"
    end

    context "from" do
      let(:klass) { rebase_class from: from, to: to }
      let(:decoded) { decoded_from }
      let(:encoded) { encoded_default }
      it_behaves_like "values"
    end

    context "converted" do
      context "named" do
        let(:klass) { rebase_class to: to, convert: convert_name }
        let(:decoded) { decoded_default }
        let(:encoded) { encoded_convert }
        it_behaves_like "values"
      end

      context "block" do
        let(:klass) { rebase_class to: to, convert: convert_block }
        let(:decoded) { decoded_default }
        let(:encoded) { encoded_convert }
        it_behaves_like "values"
      end
    end
  end

  # requires: from, to, convert_name, convert_block, decoded_default, decoded_from,
  #           encoded_default, encoded_convert, encoded_readable, encoded_convert_readable
  shared_context "allows readable" do
    include_context "all except readable"

    context "readable" do # 0 => x, 1 => y, l => w, o => z
      context "without from" do
        context "not converted" do
          let(:klass) { rebase_class to: to, readable: true }
          let(:decoded) { decoded_default }
          let(:encoded) { encoded_readable }
          it_behaves_like "values"
        end

        context "converted" do
          let(:klass) { rebase_class to: to, readable: true, convert: convert_name }
          let(:decoded) { decoded_default }
          let(:encoded) { encoded_convert_readable }
          it_behaves_like "values"
        end
      end

      context "from" do
        context "not converted" do
          let(:klass) { rebase_class from: from, to: to, readable: true }
          let(:decoded) { decoded_from }
          let(:encoded) { encoded_readable }
          it_behaves_like "values"
        end

        context "converted" do
          let(:klass) { rebase_class from: from, to: to, readable: true, convert: convert_name }
          let(:decoded) { decoded_from }
          let(:encoded) { encoded_convert_readable }
          it_behaves_like "values"
        end
      end
    end
  end

  # requires: from, to, convert_name, convert_block, decoded_default, decoded_from,
  #           encoded_default, encoded_convert
  shared_context "does not allow readable" do
    include_context "all except readable"
  end

  # defaults
  let(:from) { 8 }
  let(:convert_name) { :upcase }
  let(:convert_block) { -> (x) { x.send(convert_name) } }
  let(:decoded_default) { 31756185168571 }
  let(:decoded_from) { "716072010565273" }

  context "base 2" do
    let(:to) { 2 }
    let(:convert_name) { :chop }
    let(:encoded_default) { "111001110000111010000001000101110101010111011" }
    let(:encoded_convert) { "11100111000011101000000100010111010101011101" }
    let(:encoded_readable) { "yyyxxyyyxxxxyyyxyxxxxxxyxxxyxyyyxyxyxyxyyyxyy" }
    let(:encoded_convert_readable) { "yyyxxyyyxxxxyyyxyxxxxxxyxxxyxyyyxyxyxyxyyyxy" }

    include_context "allows readable"
  end

  context "base 8" do
    let(:to) { 8 }
    let(:from) { 7 }
    let(:convert_name) { :chop }
    let(:decoded_from) { "6455210605126033" }
    let(:encoded_default) { "716072010565273" }
    let(:encoded_convert) { "71607201056527" }
    let(:encoded_readable) { "7y6x72xyx565273" }
    let(:encoded_convert_readable) { "7y6x72xyx56527" }

    include_context "allows readable"
  end

  context "base 16" do
    let(:to) { 16 }
    let(:encoded_default) { "1ce1d022eabb" }
    let(:encoded_convert) { "1CE1D022EABB" }
    let(:encoded_readable) { "xcexdw22eabb" }
    let(:encoded_convert_readable) { "XCEXDW22EABB" }

    include_context "allows readable"
  end

  context "base 32" do
    let(:to) { 32 }
    let(:encoded_default) { "ss7825qlr" }
    let(:encoded_convert) { "SS7825QLR" }
    let(:encoded_readable) { "ss7825qwr" }
    let(:encoded_convert_readable) { "SS7825QWR" }

    include_context "allows readable"
  end

  context "base 36" do
    let(:to) { 36 }
    let(:encoded_default) { "b98l8q8qj" }
    let(:encoded_convert) { "B98L8Q8QJ" }

    include_context "does not allow readable"
  end

  context "errors" do
    specify { expect { rebase_class }.to raise_error(ArgumentError, "#rebase_attr must receive :to") }
    specify { expect { rebase_class(to: 10) { } }.to raise_error(ArgumentError, "#rebase_attr does not accept a block, did you mean to use :convert?") }
    specify { expect { rebase_class(to: 33, readable: true) }.to raise_error(ArgumentError, "#rebase_attr does not allow :readable option with bases higher than 32, 33 given") }

    context "input" do
      let(:klass) { rebase_class(to: 16) }
      let(:instance) { klass.new }

      describe "encode_x" do
        specify { expect { klass.encode_x(:a) }.to raiser_error(TypeError, "value must implement #to_i, :a given") }
        specify { expect { instance.encode_x(:a) }.to raiser_error(TypeError, "value must implement #to_i, :a given") }
      end

      describe "decode_x" do
        specify { expect { klass.decode_x(:a) }.to raiser_error(TypeError, "value must implement #to_i, :a given") }
        specify { expect { instance.decode_x(:a) }.to raiser_error(TypeError, "value must implement #to_i, :a given") }
      end

      describe "writer" do
        specify { expect { instance.x = :a }.to raiser_error(TypeError, "value must implement #to_i, :a given") }
      end

      describe "reader" do
        before { instance.instance_eval { @x = :a } }
        specify { expect { instance.x }.to raiser_error(TypeError, "value must implement #to_i, :a given") }
      end
    end
  end
end
