#!/usr/bin/env ruby
begin
  require 'rubygems'
rescue LoadError
end
require 'wx'
require 'yaml'
require 'irb/ruby-lex'
require 'stringio'


# This class is stolen almost verbatim from why_the_lucky_stiff's Shoes 
# example. (http://github.com/why/shoes/blob/master/samples/expert-irb.rb)
# He gets all the credit.
class MimickIRB < RubyLex
  attr_accessor :started
 
  class Continue < StandardError; end
  class Empty < StandardError; end
 
  def initialize(bind=TOPLEVEL_BINDING)
    set_binding(bind)
    super()
    set_input(StringIO.new)
  end
 
  def set_binding(bind)
    if bind.is_a? Binding
      @bind = bind
    else
      raise "Invalid binding #{bind.inspect}"
    end
  end

  def run(str)
    obj = nil
    @io << str
    @io.rewind
    unless l = lex
      raise Empty if @line == ''
    else
      case l.strip
      when "reset"
        @line = ""
      else
        @line << l << "\n"
        if @ltype or @continue or @indent > 0
          raise Continue
        end
      end
    end
    unless @line.empty?
      obj = eval @line, @bind, "(irb)", @line_no
    end
    @line_no += @line.scan(/\n/).length
    @line = ''
    @exp_line_no = @line_no
 
    @indent = 0
    @indent_stack = []
 
    $stdout.rewind
    output = $stdout.read
    $stdout.truncate(0)
    $stdout.rewind
    [output, obj]
  rescue Object => e
    case e when Empty, Continue
    else @line = ""
    end
    raise e
  ensure
    set_input(StringIO.new)
  end
end


# Docs say there's a KeyEvent.cmd_down which is platform independent. 
# But they LIE so we create our own...
class Wx::KeyEvent
  case  Wx::PLATFORM
  when "WXMAC"
    def inputmod_down; meta_down; end
  when "WXMSW"
    def inputmod_down; alt_down; end
  end
end


module WxIRB
  # WxIRB maintains a persistent history log. The WxIRB history uses a separate 
  # file from IRB which is defined by WxIRB::CommandHistory::HISTFILE. It is 
  # actually just a YAMLized array.
  #
  # By default, the file is $HOME/.wxirb_history (no 'convenient' way of 
  # configuring this right now aside from changing the constant)
  #
  # History is implemented in the WxIRB::CommandHistory class. This is 
  # basically just an Array with a few convenience methods and accessors.
  class CmdHistory < Array
    # an accessor to the history array position.
    attr_accessor :hpos

    # location of the persistent history file
    HISTFILE = "#{ENV["HOME"]}/.wxirb_history"

    # Initializes a CommandHistory object and loads persistent history
    # from the file specified in HISTFILE
    def initialize(*opts)
      super(*opts)
      @hpos = nil
      begin
        self.replace YAML.load_file(HISTFILE)
        @hpos = self.size-1
      rescue
        STDERR.puts "Note - error restoring history: #{$!.inspect}"
      end
    end

    # moves hpos back one and returns the history value at that position
    def prev
      return nil if self.empty?
      val = self[@hpos].to_s
      @hpos -= 1 unless @hpos == 0
      return val
    end

    # moves hpos forward one and returns the history value at that position
    def next
      if not self.empty? and @hpos != self.size-1
        @hpos += 1 
        self[@hpos].to_s
      end
    end

    # An override for the Array superclass that just updates the history 
    # position variable. This also ensures that history elements are appended
    # as strings.
    def << (val)
      @hpos = self.size
      @changed=true
      super(val.to_s)
    end

    # empties the history array and persistent history file
    def clear
      self.replace([])
      self.save!
    end

    # saves current history to the persistent history file
    def save!
      ret=nil
      begin
        ret=File.open(HISTFILE, "w") {|f| f.write(self.to_yaml) }
      rescue Errno::ENOENT
        STDERR.puts "Error: couldn't save history - #{$!}"
      end
      @changed=nil
      ret
    end

    # saves to the persistent history file only if the history has changed.
    # (this is used for an evt_idle event handler by the input text window)
    def save(force=false)
      return nil unless @changed or force
      self.save!
    end
  end


  # Keyboard commands in the input text area are what you'd expect in a 
  # multi-line textbox with some additional special keyboard modifiers.
  # See InputTextCtrl#on_char
  class InputTextCtrl < Wx::TextCtrl
    attr_accessor :history
    include Wx
    STYLE = TE_PROCESS_TAB|TE_PROCESS_ENTER|WANTS_CHARS|TE_MULTILINE

    def initialize(parent, output, mirb)
      super(parent, :style => STYLE)
      @history = CmdHistory.new
      @output = output

      @stdout_save = $stdout
      $stdout = StringIO.new
      @mirb = mirb 
      evt_idle :on_idle
      evt_char  :on_char

      @font = Wx::Font.new(10, Wx::MODERN, Wx::NORMAL, Wx::NORMAL)
      set_default_style Wx::TextAttr.new(Wx::BLACK, Wx::WHITE, @font)

      paint do |dc| 
        b_height = dc.get_text_extent("@", @font)[1] * 4
        cache_best_size Wx::Size.new(self.size.width, b_height)
      end
    end

    # Fires on Wx::IdleEvent - saves persistent history if history has changed
    def on_idle(evt)
      history.save
    end

    # Fires on text input events.
    # Implements a few special keyboard handlers
    # *   META+ENTER : sends a newline inside the input window instead of 
    #     actually running a command
    # *   META+UP-ARROW : scroll up in history
    # *   META+DOWN-ARROW : scroll down in history
    def on_char(evt)
      k = evt.key_code
      mflag = evt.modifiers

      if [MOD_NONE, MOD_SHIFT].include?(mflag) and (0x20..0x7f).include?(k)
        evt.skip()
        return
      end

      case k
      when K_RETURN
        if evt.inputmod_down
          # multi-line command uses meta-down-arrow for newline
          self.write_text("\n")
        else
          @history << self.value
          run self.value
          self.clear
        end
        return
      when (evt.inputmod_down and K_UP)
        if hist=history.prev
          self.value = hist
          self.set_insertion_point_end
          return
        end
      when (evt.inputmod_down and K_DOWN)
        if hist=history.next
          self.value = hist
          self.set_insertion_point_end
          return
        else
          self.clear
        end
      end
      evt.skip()
    end

    # Runs a command through the mock irb class, handles display details.
    def run(cmd)
      (lines = cmd.split(/\r?\n/)).each_index do |idx|
        begin
          line = lines[idx] + "\n"
          @output.default_style = Wx::TextAttr.new(Wx::BLUE)
          @output << ">> #{line}"

          out, obj = @mirb.run(line)
          @output.default_style = Wx::TextAttr.new(Wx::BLACK)
          @output << out
          @output.default_style = Wx::TextAttr.new(Wx::Colour.new(100,100,100))
          @output << "=> #{obj.inspect}\n"
        rescue MimickIRB::Empty
        rescue MimickIRB::Continue
          if idx == lines.size-1
            @output.default_style = Wx::TextAttr.new(Wx::LIGHT_GREY)
            @output << "...\n"
          end
        rescue Exception => se
          @output.default_style = Wx::TextAttr.new(Wx::RED)
          @output << (se.inspect + "\n" + se.backtrace.join("\n") + "\n")
        end
      end
    end
  end


  # The output textbox.
  # This object has a few methods to make it usable (in duck-typing cases) as 
  # an IO object. This doesn't actually inherit or implement from the IO 
  # class, however.
  class OutputTextCtrl < Wx::TextCtrl
    include Wx
    STYLE = TE_READONLY|TE_MULTILINE|TE_RICH|TE_RICH2|TE_CHARWRAP

    def initialize(parent)
      super(parent, :style => STYLE)

      font = Wx::Font.new(10, Wx::MODERN, Wx::NORMAL, Wx::NORMAL)
      set_default_style Wx::TextAttr.new(Wx::BLACK, Wx::WHITE, font)

      @io_style=Wx::TextAttr.new(Wx::Colour.new(180, 104, 52))
    end

    #----------------------------------------------------------------------
    # some methods (as i think of/need them) to make it possible to use 
    # the output text area as a fake IO object
    #----------------------------------------------------------------------

    # '<<' outputs to the output window
    alias :<< :append_text

    # 'close', 'closed?' and 'flush' are also all defined but just emulate 
    # an IO object with their return values. Other than that, they do nothing.
    def close ; nil;  end
    def closed? ; false ; end
    def flush; self; end

    # prints directly to the output text area like 'IO.print'
    # and returns nil.
    def print(*args)
      set_default_style @io_style
      self << args.flatten.join
      nil
    end

    # Displays directly to the output text area like 'IO.puts' and returns nil.
    def puts(*args)
      set_default_style @io_style
      self << args.flatten.map do |o| 
        s=o.to_s
        (s[-1,1]=="\n") ? s : s + "\n"
      end.join
      nil
    end

    # Displays directly to the output text area like 'IO.write' and returns 
    # the number of bytes written.
    def write(dat)
      set_default_style @io_style
      out = dat.to_s
      self << out
      out.size
    end
  end

  # This class is parent to the Input and Output text areas and provides
  # a sliding splitter control between them.
  class TerminalSplitter < Wx::SplitterWindow
    def initialize(parent)
      super(parent, :style => Wx::SP_LIVE_UPDATE)
      self.set_sash_gravity(1.0)
      evt_splitter_dclick self, :on_dclick
    end

    def on_dclick(evt)
      set_sash_position(- @bottom.best_size.height)
    end

    def split_horizontally(top, bottom, pos=nil)
      @top ||= top
      @bottom ||= bottom
      minsz = @bottom.best_size.height
      set_minimum_pane_size(minsz) # this also prevents unsplitting.
      pos ||= - minsz
      super(@top, @bottom, pos)
    end
  end


  # Parent and top-level window for all the wxirb controls.
  class BaseFrame < Wx::Frame
    attr_reader :output, :input

    def initialize(parent, opts={})
      bind = (opts.delete(:binding) || binding)
      @mirb=MimickIRB.new(bind)

      opts[:title] ||= "WxIRB"
      super(parent, opts)

      @splitter = TerminalSplitter.new(self)
      @output = OutputTextCtrl.new(@splitter)
      @input = InputTextCtrl.new(@splitter, @output, @mirb)
      @splitter.split_horizontally(@output, @input)
      @input.set_focus()
    end

    # Allow our binding to be changed on the fly
    def set_binding(bind);  @mirb.set_binding(bind); end

    # Clears the output window
    def clear; @output.clear ; end

    # Returns the window's command history object (see WxIRB::CommandHistory)
    def history; @input.history ; end

    # Prints the history to the output text area. Takes optional start and 
    # end position indexes for viewing just a slice of the history array.
    def histdump(s=0, e=-1)
      @output.puts self.history[s..e]
    end
  end
end

if __FILE__ == $0

  Wx::App.run do 
    $wxirb = WxIRB::BaseFrame.new(nil, :binding => TOPLEVEL_BINDING)
    $wxirb.show
  end

end
