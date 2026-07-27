require "fastrb"

RSpec.describe RubyAPI::ParamConverters do
  describe ".convert" do
    it "converts to String" do
      expect(described_class.convert("hello", String)).to eq("hello")
    end

    it "converts to Integer" do
      expect(described_class.convert("42", Integer)).to eq(42)
    end

    it "converts to Float" do
      expect(described_class.convert("3.14", Float)).to eq(3.14)
    end

    it "converts to Boolean (true)" do
      expect(described_class.convert("true", RubyAPI::Boolean)).to eq(true)
    end

    it "converts to Boolean (false)" do
      expect(described_class.convert("false", RubyAPI::Boolean)).to eq(false)
    end

    it "converts to Date" do
      expect(described_class.convert("2026-01-15", Date)).to eq(Date.new(2026, 1, 15))
    end

    it "converts to Time" do
      result = described_class.convert("2026-01-15T10:30:00Z", Time)
      expect(result).to be_a(Time)
    end

    it "converts to DateTime" do
      result = described_class.convert("2026-01-15T10:30:00", DateTime)
      expect(result).to be_a(DateTime)
    end

    it "converts to Array from JSON string" do
      expect(described_class.convert('[1,2,3]', Array)).to eq([1, 2, 3])
    end

    it "converts to Hash from JSON string" do
      result = described_class.convert('{"a":1}', Hash)
      expect(result).to eq("a" => 1)
    end

    it "validates UUID format" do
      uuid = "550e8400-e29b-41d4-a716-446655440000"
      expect(described_class.convert(uuid, RubyAPI::UUID)).to eq(uuid)
    end

    it "rejects invalid UUID" do
      expect { described_class.convert("not-a-uuid", RubyAPI::UUID) }.to raise_error(RubyAPI::ConversionError)
    end

    it "converts to Decimal" do
      result = described_class.convert("3.14", RubyAPI::Decimal)
      expect(result).to eq(BigDecimal("3.14"))
    end

    it "converts to Symbol" do
      expect(described_class.convert("hello", Symbol)).to eq(:hello)
    end

    it "raises ConversionError for invalid Integer" do
      expect { described_class.convert("abc", Integer) }.to raise_error(RubyAPI::ConversionError)
    end

    it "raises ConversionError for invalid Float" do
      expect { described_class.convert("abc", Float) }.to raise_error(RubyAPI::ConversionError)
    end
  end
end
