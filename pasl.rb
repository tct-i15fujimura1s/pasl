require 'parslet'

module PasL
  class Parser < Parslet::Parser
    root :parser

    rule(:parser) {
      ((s? >> rule.as(:rule)).repeat >> s?).as(:parser)
    }

    rule(:rule) {
      name >> s? >> str("<-") >> s? >> expr.as(:expr)
    }

    rule(:name) {
      (match('[_a-zA-Z]') >> match('[_0-9a-zA-Z?!]').repeat).as(:name)
    }

    rule(:expr) {
      e_choice? >> s? >> lend
    }

    rule(:lend) {
      str(?;) |
      match(?$)
    }

    rule(:e_choice?) {
      e_choice.as(:choice) | e_seq?
    }

    rule(:e_choice) {
      e_seq? >> (s? >> str(?|) >> s? >> e_seq?).repeat(1)
    }

    rule(:e_seq?) {
      e_seq.as(:seq) | e_as?
    }

    rule(:e_seq) {
      e_as? >> (s? >> e_as?).repeat(1)
    }

    rule(:e_as?) {
      e_as.as(:as) | e_term
    }

    rule(:e_as) {
      e_term.as(:expr) >> s? >> str(?@) >> s? >> name.as(:name)
    }

    rule(:e_term) {
      e_present | e_absent | e_small
    }

    rule(:e_present) {
      str(?&) >> s? >> e_small.as(:present)
    }

    rule(:e_absent) {
      str(?!) >> s? >> e_small.as(:absent)
    }

    rule(:e_small) {
      e_repeat | e_repeat1 | e_maybe | e_factor
    }

    rule(:e_repeat) {
      e_factor.as(:repeat) >> s? >> str(?*)
    }

    rule(:e_repeat1) {
      e_factor.as(:repeat1) >> s? >> str(?+)
    }

    rule(:e_maybe) {
      e_factor.as(:maybe) >> s? >> str(??)
    }

    rule(:e_factor) {
      e_any | e_str | e_match | e_group | name.as(:ref)
    }

    rule(:e_str) {
      (str(?") >> (match('[^"]') | str(?\\) >> any).repeat >> str(?")).as(:str)
    }

    rule(:e_match) {
      (str(?[) >> (match('[^\]]') | str(?\\) >> any).repeat >> str(?])).as(:match) |
      str(?/) >> (match('[^/]') | str(?\\) >> any).repeat.as(:match) >> str(?/)
    }

    rule(:e_group) {
      str('(') >> s? >> e_choice? >> s? >> str(')')
    }

    rule(:e_any) {
      str(?.).as(:any)
    }

    rule(:s) {
      (match('[ \t\f]') | str(?\\) >> str(?\n)).repeat(1)
    }

    rule(:s?) {
      s.maybe
    }
  end


  class Transform < Parslet::Transform
    class E
      def self.[](*xs)
        new(*xs)
      end

      attr_reader :type, :values

      def initialize(type, *values)
        @type, @values = type, values
      end

      def value
        case values.length
        when 0; nil
        when 1; values[0]
        else values
        end
      end

      def inspect
        case type
        when :any
          "."
        when :ref
          "\##{value}"
        when :str
          "\"#{value}\""
        else
          "#{type}[#{values.map(&:inspect).join(',')}]"
        end
      end
    end

    rule(parser: subtree(:rules)) {
      hash = {}
      rules.each { |r| hash[r[:rule][:name].to_s.to_sym] = r[:rule][:expr] }
      hash
    }

    rule(choice: sequence(:es)) { E[:choice, *es] }

    rule(seq: sequence(:es)) { E[:seq, *es] }

    rule(as: subtree(:et)) { E[:as, et[:name], et[:expr]] }

    rule(present: simple(:e)) { E[:present, e] }

    rule(absent: simple(:e)) { E[:absent, e] }

    rule(repeat: simple(:e)) { E[:repeat, e] }

    rule(repeat1: simple(:e)) { E[:repeat1, e] }

    rule(maybe: simple(:e)) { E[:maybe, e] }

    rule(any: simple(:s)) { E[:any] }

    rule(match: simple(:s)) { E[:match, s] }

    rule(str: simple(:s)) { E[:str, eval(s)] }

    rule(ref: simple(:n)) { E[:ref, n] }

    rule(name: simple(:s)) { s.to_s.to_sym }
  end

  def self.parseFile(root, path)
    parse(root, File.read(path))
  end

  def self.makeAST(str)
    Transform.new.apply Parser.new.parse str
  end

  def self.parse(root, str)
    parser = Class.new(Parslet::Parser)

    parser.__send__(:root, root)

    parser.__send__(:define_method, :__resolve, &method(:__resolve))

    ast = makeAST str
    ast.each { |(name, expr)| parser.__send__(:rule, name) { __resolve self, expr } }

    parser
  end

  def self.__resolve(s, e)
    v = e.value
    case e.type
    when :choice; v.map { |x| __resolve s, x }.inject { |x, y| x | y }
    when :seq; v.map { |x| __resolve s, x }.inject { |x, y| x >> y }
    when :as; __resolve(s, v[1]).as v[0]
    when :repeat; __resolve(s, v).repeat
    when :repeat1; __resolve(s, v).repeat(1)
    when :maybe; __resolve(s, v).maybe
    when :any; s.__send__ :any
    when :match; s.__send__ :match, v
    when :str; s.__send__.str v
    when :ref; s.__send__ v
    end
  end
end
