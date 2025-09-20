require 'optparse'
require 'json'

config = Struct.new(:attrs, :json_attrs, :limit, :width, :idx_flat, :idx_deep, :verbose) do
  #attr_reader :width, :idx_flat, :idx_deep
  def validate!
    raise "Attributes (--header) are required" unless attrs&.any?

    extra_attrs = Array(json_attrs) - attrs
    raise "JSON attributes #{extra_attrs} are not in the main attributes list #{attrs}" unless extra_attrs.empty?
    self.json_attrs&.to_set
    self.width = attrs.size

    warmup
  end

  def warmup
    self.idx_deep = Array(json_attrs).map { |ja| attrs.index(ja) }
    self.idx_flat = Array.new(width) { _1 } - self.idx_deep
  end
end.new

OptionParser.new do |opts|
  opts.banner = "Usage: streamenum.rb [options]"

  opts.on("-h", "--header attr1,attr2,attr3", "ordered attribute names") do |headers|
    config.attrs = headers.split(',')
  end

  opts.on("-j", "--json attr2,attr3", "JSON attribute names") do |jsons|
    config.json_attrs = jsons.split(',')
  end

  opts.on("-v", "--verbose", "Maximum unique values list size per attribute") do |verbose|
    config.verbose = verbose
  end

  opts.on("-l", "--limit 200", "Maximum unique values list size per attribute") do |limit|
    config.limit = limit.to_i
  end

  opts
end.parse!


config.attrs = $stdin.readline.chomp.split("\t") if config.attrs.nil?
config.validate!
$stderr.puts "config: #{config.inspect}\n" if config.verbose


class DeepReader
  class << self
    def parse(obj, prefix=[], &block)
      if obj.is_a?(Array)
        parse_array(obj, prefix, &block)
      elsif obj.is_a?(Hash)
        parse_hash(obj, prefix, &block)
      else
        block.call(prefix, obj)
      end
    end

    def parse_array(obj, prefix, &block)
      obj.each do |v|
        parse(v, prefix + ['[]'], &block)
      end
    end

    def parse_hash(obj, prefix, &block)
      obj.each do |k,v|
        parse(v, prefix + [k], &block)
      end
    end
  end
end

Accumulator = Struct.new(:width, :idx_flat, :idx_deep, :limit) do
  attr_reader :flat_list, :deep_sets
  def initialize(...)
    super
    @flat_list = Array.new(width) { [] }
    @deep_sets = Array.new(width) { Hash.new { |h, k| h[k] = Set.new } }
  end

  def record(values, &listener)
    idx_flat.each do |i|
      next if flat_list[i].size >= limit
      v = values[i]
      unless flat_list[i].include?(v)
        flat_list[i] << v
        listener.call(i, nil, v)
      end
    end

    idx_deep.each do |i|
      hash = JSON.parse(values[i])
      DeepReader.parse(hash) do |path, v|
        storage = deep_sets[i][path]
        next if storage.size >= limit

        unless storage.include?(v)
          storage << v
          listener.call(i, path.join('.'), v)
        end
      end
    end
  end

  def dump(attrs)
    result = {}
    idx_flat.each do |i|
      result[attrs[i]] = flat_list[i]
    end

    idx_deep.each do |i|
      deep_sets[i].each do |path, set|
        output = set.to_a
        output.sort! unless set.include?(false)
        result[([attrs[i]] + path).join('.')] = output
      end
    end

    puts(JSON.pretty_generate(result))
  end
end

acc = Accumulator.new(config.width, config.idx_flat, config.idx_deep, config.limit)

loop do
  line = $stdin.readline
  break if $stdin.eof?
  acc.record(line.chomp.split("\t")) do |i, path, value|
    $stderr.puts(config.attrs[i] + '.' + path.to_s => value) if config.verbose
  end

end

acc.dump(config.attrs)
