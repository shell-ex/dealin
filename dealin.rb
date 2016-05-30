#!/usr/bin/env ruby

require 'getoptlong'
require 'shellwords'

opts = GetoptLong.new(
  [ '--field-separator', '-F', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--fields', '-f', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ]
)
opts.ordering = GetoptLong::REQUIRE_ORDER

$sep = / +/
$field_s = -1
$field_e = -1
$cmd = nil

def usage
  x = <<-EOF
    USAGE: #{$0} -fn[,m] [OPTION] command ...

      -f, --fields n[,m]        Set start and end field
      -F, --field-separator fs  Use fs for the input field separator

  EOF
  puts x.gsub(/^    /, '')
  exit 0
end

opts.each do |opt, arg|
  case opt
  when '--field-separator'
    $sep = arg
  when '--fields'
    raise 'Bad fields format' if arg !~ /\d+(,\d+)?/
    x = arg.split ','
    $field_s = x[0].to_i
    $field_e = x.length > 1 ? x[1].to_i : $field_s
    raise 'End field has to great equal then start field' if $field_s > $field_e
  when '--help'
    usage
  end
end

if $field_s < 0 or ARGV.length == 0
  usage
end
$cmd = Shellwords.join ARGV

def split line
  i = 0
  spos = $field_s == 1 ? 0 : -1
  epos = -1
  line.scan($sep) do
    i += 1
    epos = $~.begin(0) if i == $field_e
    spos = $~.end(0) if i == $field_s - 1
  end
  epos = line.length if epos == -1
  if spos != -1
    return [line[0, spos], line[spos, epos - spos], line[epos..-1]]
  else
    return [line]
  end
end

$p = IO.popen($cmd, 'r+')
$queue = []
$buf_stdin = ""
$buf_p = ""

def emit line
  line.chomp!
  x = split line
  $queue.push x
  if x.length > 1
    $p.puts x[1]
  end
end

def combine line
  line.chomp!
  while ! $queue.empty? && $queue[0].length <= 1
    puts $queue.shift.join
  end
  if $queue.empty?
    STDERR.puts "line not match!"
    return
  end
  x = $queue.shift
  x[1] = line
  puts x.join
  while ! $queue.empty? && $queue[0].length <= 1
    puts $queue.shift.join
  end
end

$fds = [$p, STDIN]
while $fds.length > 0
  r, = select($fds)
  r.each do |s|
    if s == STDIN
      begin
        $buf_stdin += s.read_nonblock 64 * 1024
        $buf_stdin = $buf_stdin.gsub(/.*?\n/) do |x|
          emit x
        end
      rescue EOFError
        $fds.delete s
        emit $buf_stdin if $buf_stdin.length > 0
        $p.close_write
      end
    else
      begin
        $buf_p += s.read_nonblock 64 * 1024
        $buf_p = $buf_p.gsub(/.*?\n/) do |x|
          combine x
        end
      rescue EOFError
        $fds.delete s
        combine $buf_p if $buf_p.length > 0
      end
    end
  end
end

