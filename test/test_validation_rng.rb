# frozen_string_literal: false

require "rexml/validation/relaxng"

module REXMLTests
  class RNGValidation < Test::Unit::TestCase
    include REXML

    def test_validate
      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<element name="A" xmlns="http://relaxng.org/ns/structure/1.0">
  <element name="B">
    <element name="C">
      <attribute name="X"/>
      <zeroOrMore>
        <element name="E">
          <empty/>
        </element>
      </zeroOrMore>
    </element>
    <element name="D">
      <empty/>
    </element>
  </element>
</element>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      no_error( validator, %q{<A><B><C X="x"><E/><E/></C><D/></B></A>} )
      error( validator, %q{<A><B><D/><C X="x"/></B></A>} )
    end


    def test_sequence
      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<element name="A" xmlns="http://relaxng.org/ns/structure/1.0">
  <element name="B">
    <element name="C">
      <empty/>
    </element>
    <element name="D">
      <empty/>
    </element>
  </element>
</element>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      error( validator, %q{<A><B><C/><C/><D/></B></A>} )
      error( validator, %q{<A><B><D/><C/></B></A>} )
      error( validator, %q{<A><C/><D/></A>} )
      no_error( validator, %q{<A><B><C/><D/></B></A>} )
    end


    def test_choice
      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<element name="A" xmlns="http://relaxng.org/ns/structure/1.0">
  <element name="B">
    <choice>
      <element name="C">
        <empty/>
      </element>
      <element name="D">
        <empty/>
      </element>
    </choice>
  </element>
</element>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      error( validator, %q{<A><B><C/><D/></B></A>} )
      no_error( validator, %q{<A><B><D/></B></A>} )
      no_error( validator, %q{<A><B><C/></B></A>} )
    end

    def test_optional
      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<element name="A" xmlns="http://relaxng.org/ns/structure/1.0">
  <element name="B">
    <optional>
      <element name="C">
        <empty/>
      </element>
    </optional>
  </element>
</element>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      no_error( validator, %q{<A><B/></A>} )
      no_error( validator, %q{<A><B><C/></B></A>} )
      error( validator, %q{<A><B><D/></B></A>} )
      error( validator, %q{<A><B><C/><C/></B></A>} )
    end

    def test_zero_or_more
      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<element name="A" xmlns="http://relaxng.org/ns/structure/1.0">
  <element name="B">
    <zeroOrMore>
      <element name="C">
        <empty/>
      </element>
    </zeroOrMore>
  </element>
</element>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )
      no_error( validator, %q{<A><B/></A>} )
      no_error( validator, %q{<A><B><C/></B></A>} )
      no_error( validator, %q{<A><B><C/><C/><C/></B></A>} )
      error( validator, %q{<A><B><D/></B></A>} )
      error( validator, %q{<A></A>} )

      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<element name="A" xmlns="http://relaxng.org/ns/structure/1.0">
  <element name="B">
    <zeroOrMore>
      <element name="C">
        <empty/>
      </element>
      <element name="D">
        <empty/>
      </element>
    </zeroOrMore>
  </element>
</element>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      no_error( validator, %q{<A><B/></A>} )
      no_error( validator, %q{<A><B><C/><D/></B></A>} )
      no_error( validator, %q{<A><B><C/><D/><C/><D/></B></A>} )
      error( validator, %q{<A><B><D/></B></A>} )
    end

    def test_one_or_more
      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<element name="A" xmlns="http://relaxng.org/ns/structure/1.0">
  <element name="B">
    <oneOrMore>
      <element name="C">
        <empty/>
      </element>
    </oneOrMore>
  </element>
</element>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      error( validator, %q{<A><B/></A>} )
      no_error( validator, %q{<A><B><C/></B></A>} )
      no_error( validator, %q{<A><B><C/><C/><C/></B></A>} )
      error( validator, %q{<A><B><D/></B></A>} )
      error( validator, %q{<A></A>} )
    end

    def test_attribute
      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<element name="A" xmlns="http://relaxng.org/ns/structure/1.0">
  <attribute name="X"/>
  <attribute name="Y"/>
</element>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      error( validator, %q{<A><B/></A>} )
      error( validator, %q{<A/>} )
      error( validator, %q{<A X=""/>} )
      no_error( validator, %q{<A X="1" Y="1"/>} )
    end

    def test_choice_attributes
      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<element name="A" xmlns="http://relaxng.org/ns/structure/1.0">
  <choice>
    <attribute name="X"/>
    <attribute name="Y"/>
  </choice>
</element>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      error( validator, %q{<A X="1" Y="1"/>} )
      error( validator, %q{<A/>} )
      no_error( validator, %q{<A X="1"/>})
      no_error( validator, %q{<A Y="1"/>} )
    end

    def test_choice_attribute_element
      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<element name="A" xmlns="http://relaxng.org/ns/structure/1.0">
  <choice>
    <attribute name="X"/>
    <element name="B"/>
  </choice>
</element>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      error( validator, %q{<A X="1"><B/></A>} )
      error( validator, %q{<A/>} )
      no_error( validator, %q{<A X="1"/>})
      no_error( validator, %q{<A><B/></A>} )
    end

    def test_empty
      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<element name="A" xmlns="http://relaxng.org/ns/structure/1.0">
  <empty/>
</element>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      error( validator, %q{<A><B/></A>} )
      error( validator, %q{<A>Text</A>} )
      no_error( validator, %q{<A/>})
    end

    def test_text_val
      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<element name="A" xmlns="http://relaxng.org/ns/structure/1.0">
  <text/>
</element>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      error( validator, %q{<A><B/></A>} )
      no_error( validator, %q{<A>Text</A>} )
      error( validator, %q{<A/>})
    end

    def test_choice_text
      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<element name="A" xmlns="http://relaxng.org/ns/structure/1.0">
  <choice>
    <element name="B"/>
    <text/>
  </choice>
</element>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      error( validator, %q{<A><B/>Text</A>} )
      error( validator, %q{<A>Text<B/></A>} )
      no_error( validator, %q{<A>Text</A>} )
      no_error( validator, %q{<A><B/></A>} )
    end

    def test_group
      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<element name="A" xmlns="http://relaxng.org/ns/structure/1.0">
  <choice>
    <element name="B"/>
    <group>
      <element name="C"/>
      <element name="D"/>
    </group>
  </choice>
</element>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      error( validator, %q{<A><B/><C/></A>} )
      error( validator, %q{<A><C/></A>} )
      no_error( validator, %q{<A><B/></A>} )
      no_error( validator, %q{<A><C/><D/></A>} )

      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<element name="A" xmlns="http://relaxng.org/ns/structure/1.0">
  <element name="B"/>
  <group>
    <element name="C"/>
    <element name="D"/>
  </group>
</element>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      error( validator, %q{<A><B/><C/></A>} )
      error( validator, %q{<A><B/><D/></A>} )
      error( validator, %q{<A><B/></A>} )
      no_error( validator, %q{<A><B/><C/><D/></A>} )
    end

    def test_value
      # Values as text nodes
      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<element name="A" xmlns="http://relaxng.org/ns/structure/1.0">
  <element name="B">
    <value>VaLuE</value>
  </element>
</element>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      error( validator, %q{<A><B>X</B></A>} )
      error( validator, %q{<A><B/></A>} )
      no_error( validator, %q{<A><B>VaLuE</B></A>} )

      # Values as text nodes, via choice
      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<element name="A" xmlns="http://relaxng.org/ns/structure/1.0">
  <element name="B">
    <choice>
      <value>Option 1</value>
      <value>Option 2</value>
    </choice>
  </element>
</element>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      error( validator, %q{<A><B/></A>} )
      error( validator, %q{<A><B>XYZ</B></A>} )
      no_error( validator, %q{<A><B>Option 1</B></A>} )
      no_error( validator, %q{<A><B>Option 2</B></A>} )

      # Attribute values
      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<element name="A" xmlns="http://relaxng.org/ns/structure/1.0">
  <attribute name="B">
    <value>VaLuE</value>
  </attribute>
</element>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      error( validator, %q{<A/>} )
      error( validator, %q{<A B=""/>} )
      error( validator, %q{<A B="Lala"/>} )
      no_error( validator, %q{<A B="VaLuE"/>} )

      # Attribute values via choice
      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<element name="A" xmlns="http://relaxng.org/ns/structure/1.0">
  <attribute name="B">
    <choice>
      <value>Option 1</value>
      <value>Option 2</value>
    </choice>
  </attribute>
</element>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      error( validator, %q{<A B=""/>} )
      error( validator, %q{<A B="Value"/>} )
      no_error( validator, %q{<A B="Option 1"></A>} )
      no_error( validator, %q{<A B="Option 2"/>} )
    end

    def test_interleave
      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<element name="A" xmlns="http://relaxng.org/ns/structure/1.0">
  <element name="B">
    <interleave>
      <element name="C"/>
      <element name="D"/>
      <element name="E"/>
    </interleave>
  </element>
</element>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      error( validator, %q{<A><B><C/></B></A>} )
      error( validator, %q{<A><B><C/><D/><C/></B></A>} )
      no_error( validator, %q{<A><B><C/><D/><E/></B></A>} )
      no_error( validator, %q{<A><B><E/><D/><C/></B></A>} )
      no_error( validator, %q{<A><B><D/><C/><E/></B></A>} )
      no_error( validator, %q{<A><B><E/><C/><D/></B></A>} )
      error( validator, %q{<A><B><E/><C/><D/><C/></B></A>} )
    end

    def test_mixed
      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<element name="A" xmlns="http://relaxng.org/ns/structure/1.0">
  <element name="B">
    <mixed>
      <element name="D"/>
    </mixed>
  </element>
</element>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      no_error( validator, %q{<A><B>Text<D/></B></A>} )
      no_error( validator, %q{<A><B><D/>Text</B></A>} )
    end

    def test_ref_sequence
      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<grammar xmlns="http://relaxng.org/ns/structure/1.0">
  <start>
    <element name="A">
      <ref name="B"/>
      <ref name="B"/>
    </element>
  </start>

  <define name="B">
    <element name="B">
      <attribute name="X"/>
    </element>
  </define>
</grammar>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      no_error( validator, %q{<A><B X=''/><B X=''/></A>} )
      error( validator, %q{<A><B X=''/></A>} )
    end

    def test_ref_choice
      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<grammar xmlns="http://relaxng.org/ns/structure/1.0">
  <start>
    <element name="A">
      <choice>
        <ref name="B"/>
      </choice>
    </element>
  </start>

  <define name="B">
    <element name="B"/>
    <element name="C"/>
  </define>
</grammar>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      error( validator, %q{<A><D/></A>} )
      error( validator, %q{<A><B/><C/></A>} )
      no_error( validator, %q{<A><B/></A>} )
      no_error( validator, %q{<A><C/></A>} )

      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<grammar xmlns="http://relaxng.org/ns/structure/1.0">
  <start>
    <element name="A">
      <ref name="B"/>
    </element>
  </start>

  <define name="B">
    <choice>
      <element name="B"/>
      <element name="C"/>
    </choice>
  </define>
</grammar>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      error( validator, %q{<A><D/></A>} )
      error( validator, %q{<A><B/><C/></A>} )
      no_error( validator, %q{<A><B/></A>} )
      no_error( validator, %q{<A><C/></A>} )

      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<grammar xmlns="http://relaxng.org/ns/structure/1.0">
  <start>
    <element name="A">
      <choice>
        <ref name="B"/>
        <element name="D"/>
      </choice>
    </element>
  </start>

  <define name="B">
    <element name="B"/>
    <element name="C"/>
  </define>
</grammar>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      error( validator, %q{<A><B/><C/></A>} )
      no_error( validator, %q{<A><B/></A>} )
      no_error( validator, %q{<A><C/></A>} )
      no_error( validator, %q{<A><D/></A>} )
    end


    def test_ref_zero_plus
      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<grammar xmlns="http://relaxng.org/ns/structure/1.0">
  <start>
    <element name="A">
      <zeroOrMore>
        <ref name="B"/>
      </zeroOrMore>
    </element>
  </start>

  <define name="B">
    <element name="B">
      <attribute name="X"/>
    </element>
  </define>
</grammar>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      error( validator, %q{<A><B/></A>} )
      no_error( validator, %q{<A/>} )
      no_error( validator, %q{<A><B X=''/></A>} )
      no_error( validator, %q{<A><B X=''/><B X=''/><B X=''/></A>} )

      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<grammar xmlns="http://relaxng.org/ns/structure/1.0">
  <start>
    <element name="A">
      <ref name="B"/>
    </element>
  </start>

  <define name="B">
    <zeroOrMore>
      <element name="B">
        <attribute name="X"/>
      </element>
    </zeroOrMore>
  </define>
</grammar>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      error( validator, %q{<A><B/></A>} )
      no_error( validator, %q{<A/>} )
      no_error( validator, %q{<A><B X=''/></A>} )
      no_error( validator, %q{<A><B X=''/><B X=''/><B X=''/></A>} )
    end


    def test_ref_one_plus
      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<grammar xmlns="http://relaxng.org/ns/structure/1.0">
  <start>
    <element name="A">
      <oneOrMore>
        <ref name="B"/>
      </oneOrMore>
    </element>
  </start>

  <define name="B">
    <element name="B">
      <attribute name="X"/>
    </element>
  </define>
</grammar>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      error( validator, %q{<A><B/></A>} )
      error( validator, %q{<A/>} )
      no_error( validator, %q{<A><B X=''/></A>} )
      no_error( validator, %q{<A><B X=''/><B X=''/><B X=''/></A>} )

      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<grammar xmlns="http://relaxng.org/ns/structure/1.0">
  <start>
    <element name="A">
      <ref name="B"/>
    </element>
  </start>

  <define name="B">
    <oneOrMore>
      <element name="B">
        <attribute name="X"/>
      </element>
    </oneOrMore>
  </define>
</grammar>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      error( validator, %q{<A><B/></A>} )
      error( validator, %q{<A/>} )
      no_error( validator, %q{<A><B X=''/></A>} )
      no_error( validator, %q{<A><B X=''/><B X=''/><B X=''/></A>} )
    end

    def test_ref_interleave
      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<grammar xmlns="http://relaxng.org/ns/structure/1.0">
  <start>
    <element name="A">
      <interleave>
        <ref name="B"/>
      </interleave>
    </element>
  </start>

  <define name="B">
    <element name="B"/>
    <element name="C"/>
  </define>
</grammar>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      error( validator, %q{<A><B/></A>} )
      error( validator, %q{<A><C/></A>} )
      error( validator, %q{<A><C/><C/></A>} )
      no_error( validator, %q{<A><B/><C/></A>} )
      no_error( validator, %q{<A><C/><B/></A>} )

      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<grammar xmlns="http://relaxng.org/ns/structure/1.0">
  <start>
    <element name="A">
      <ref name="B"/>
    </element>
  </start>

  <define name="B">
    <interleave>
      <element name="B"/>
      <element name="C"/>
    </interleave>
  </define>
</grammar>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      error( validator, %q{<A><B/></A>} )
      error( validator, %q{<A><C/></A>} )
      error( validator, %q{<A><C/><C/></A>} )
      no_error( validator, %q{<A><B/><C/></A>} )
      no_error( validator, %q{<A><C/><B/></A>} )

      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<grammar xmlns="http://relaxng.org/ns/structure/1.0">
  <start>
    <element name="A">
      <interleave>
        <ref name="B"/>
        <ref name="C"/>
      </interleave>
    </element>
  </start>

  <define name="B">
    <element name="B"/>
  </define>
  <define name="C">
    <element name="C"/>
  </define>
</grammar>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      error( validator, %q{<A><B/></A>} )
      error( validator, %q{<A><C/></A>} )
      error( validator, %q{<A><C/><C/></A>} )
      no_error( validator, %q{<A><B/><C/></A>} )
      no_error( validator, %q{<A><C/><B/></A>} )
    end

    def test_ref_recurse
      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<grammar xmlns="http://relaxng.org/ns/structure/1.0">
  <start>
    <element name="A">
      <ref name="B"/>
    </element>
  </start>

  <define name="B">
    <element name="B">
      <optional>
        <ref name="B"/>
      </optional>
    </element>
  </define>
</grammar>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      error( validator, %q{<A></A>} )
      no_error( validator, %q{<A><B/></A>} )
      no_error( validator, %q{<A><B><B/></B></A>} )
    end

    def test_ref_optional
      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<grammar xmlns="http://relaxng.org/ns/structure/1.0">
  <start>
    <element name="A">
      <optional>
        <ref name="B"/>
      </optional>
    </element>
  </start>

  <define name="B">
    <element name="B">
    </element>
  </define>
</grammar>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      no_error( validator, %q{<A></A>} )
      no_error( validator, %q{<A><B/></A>} )
      error( validator, %q{<A><B/><B/></A>} )
      error( validator, %q{<A><C/></A>} )

      rng = <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<grammar xmlns="http://relaxng.org/ns/structure/1.0">
  <start>
    <element name="A">
      <ref name="B"/>
    </element>
  </start>

  <define name="B">
    <optional>
      <element name="B">
      </element>
    </optional>
  </define>
</grammar>
      XML
      validator = REXML::Validation::RelaxNG.new( rng )

      no_error( validator, %q{<A></A>} )
      no_error( validator, %q{<A><B/></A>} )
      error( validator, %q{<A><B/><B/></A>} )
      error( validator, %q{<A><C/></A>} )
    end



    def error( validator, source )
      parser = REXML::Parsers::TreeParser.new( source )
      parser.add_listener( validator.reset )
      assert_raise( REXML::Validation::ValidationException,
                    "Expected a validation error" ) { parser.parse }
    end

    def no_error( validator, source )
      parser = REXML::Parsers::TreeParser.new( source )
      parser.add_listener( validator.reset )
      assert_nothing_raised { parser.parse }
    end
  end
end
