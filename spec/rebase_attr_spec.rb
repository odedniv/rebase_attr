require 'rebase_attr'

class RebaseTestBase
  attr_accessor :x
end

# This converts options to local varaibels so they can be used inside the Class.new { }
def rebase_class(**options, &block)
  Class.new(RebaseTestBase) { rebase_attr(:x, **options, &block) }
end

describe RebaseAttr::Generator do
  #requires: decoded, encoded
  shared_examples_for "values" do
    subject(:instance) { klass.new }

    describe "#encode" do
      specify { expect(klass.encode_x(decoded)).to eq(encoded) }
      specify { expect(instance.encode_x(decoded)).to eq(encoded) }
      specify { expect(instance.encode_x(nil)).to be_nil }
    end

    describe "#decode" do
      specify { expect(klass.decode_x(encoded)).to eq(decoded) }
      specify { expect(klass.decode_x(nil)).to be_nil }
      specify { expect(instance.decode_x(encoded)).to eq(decoded) }
      specify { expect(instance.decode_x(nil)).to be_nil }
    end

    describe "reader" do
      context "when not nil" do
        before { d = decoded; instance.instance_eval { @x = d } } # converting decoded to local variable so I can use it inside instance_eval
        its(:x) { should == encoded }
      end

      context "when nil" do
        before { instance.instance_eval { @x = nil } } # converting decoded to local variable so I can use it inside instance_eval
        its(:x) { should be_nil }
      end
    end

    describe "#without_rebase" do
      context "when not nil" do
        before { d = decoded; instance.instance_eval { @x = d } } # converting decoded to local variable so I can use it inside instance_eval
        its(:x_without_rebase) { should == decoded }
      end

      context "when nil" do
        before { instance.instance_eval { @x = nil } } # converting decoded to local variable so I can use it inside instance_eval
        its(:x_without_rebase) { should be_nil }
      end
    end

    describe "writer" do
      context "when not nil" do
        before { instance.x = encoded }
        specify { expect(instance.instance_eval { @x }).to eq(decoded) }
      end

      context "when nil" do
        before { instance.x = nil }
        specify { expect(instance.instance_eval { @x }).to be_nil }
      end
    end

    describe "#without_rebase=" do
      context "when not nil" do
        before { instance.x_without_rebase = decoded }
        specify { expect(instance.instance_eval { @x }).to eq(decoded) }
      end

      context "when nil" do
        before { instance.x_without_rebase = nil }
        specify { expect(instance.instance_eval { @x }).to be_nil }
      end
    end
  end

  # requires: from, to, convert_name, convert_block, decoded_default, decoded_from,
  #           decoded_convert, decoded_convert_from, encoded_default, encoded_convert
  shared_context "all except readable" do
    context "without from" do
      context "not converted" do
        let(:klass) { rebase_class to: to }
        let(:decoded) { decoded_default }
        let(:encoded) { encoded_default }
        it_behaves_like "values"
      end

      context "converted" do
        context "named" do
          let(:klass) { rebase_class to: to, convert: convert_name, deconvert: deconvert }
          let(:decoded) { decoded_default }
          let(:encoded) { encoded_convert }
          it_behaves_like "values"
        end

        context "block" do
          let(:klass) { rebase_class to: to, convert: convert_block, deconvert: deconvert }
          let(:decoded) { decoded_default }
          let(:encoded) { encoded_convert }
          it_behaves_like "values"
        end
      end
    end

    context "from" do
      context "not converted" do
        let(:klass) { rebase_class from: from, to: to }
        let(:decoded) { decoded_from }
        let(:encoded) { encoded_default }
        it_behaves_like "values"
      end

      context "converted" do
        let(:klass) { rebase_class from: from, to: to, convert: convert_name, deconvert: deconvert }
        let(:decoded) { decoded_from }
        let(:encoded) { encoded_convert }
        it_behaves_like "values"
      end
    end
  end

  # requires: from, to, convert_name, convert_block, decoded_default, decoded_from, decoded_convert,
  #           decoded_convert_from, encoded_default, encoded_convert, encoded_readable, encoded_convert_readable
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
          let(:klass) { rebase_class to: to, readable: true, convert: convert_name, deconvert: deconvert }
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
          let(:klass) { rebase_class from: from, to: to, readable: true, convert: convert_name, deconvert: deconvert }
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
  let(:deconvert) { nil }
  let(:decoded_default) { 31756185168571 }
  let(:decoded_from) { "716072010565273" }

  context "base 2" do
    let(:to) { 2 }
    let(:convert_name) { :chop }
    let(:deconvert) { -> (x) { x + "1" } }
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
    let(:deconvert) { -> (x) { x + "3" } }
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
    let(:encoded_readable) { "yceydx22eabb" }
    let(:encoded_convert_readable) { "YCEYDX22EABB" }

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

      describe "#encode" do
        specify { expect { klass.encode_x(:a) }.to raise_error(TypeError, "decoded value must implement #to_i, :a given") }
        specify { expect { instance.encode_x(:a) }.to raise_error(TypeError, "decoded value must implement #to_i, :a given") }
      end

      describe "#decode" do
        specify { expect { klass.decode_x(:a) }.to raise_error(TypeError, "encoded value must implement #to_i, :a given") }
        specify { expect { instance.decode_x(:a) }.to raise_error(TypeError, "encoded value must implement #to_i, :a given") }
      end

      describe "reader" do
        before { instance.instance_eval { @x = :a } }
        specify { expect { instance.x }.to raise_error(TypeError, "decoded value must implement #to_i, :a given") }
      end

      describe "writer" do
        specify { expect { instance.x = :a }.to raise_error(TypeError, "encoded value must implement #to_i, :a given") }
      end
    end
  end
end
