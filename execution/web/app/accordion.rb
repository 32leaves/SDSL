require 'opal'
require 'opal-jquery'

class Accordion
  attr_accessor :title_height, :height

  def initialize(id)
    @id = id
    @height = `window.innerHeight`
    @title_height = 30
    @on_open = lambda {|x|}

    Element.find("##{id} li").on(:click) do |evt|
      Element.find("##{id} li").each do |e|
        e.css  :height => @title_height
        e.remove_class :active
      end
      active_element = `$(evt.native.currentTarget)`
      active_element.css :height => self.tile_height
      active_element.add_class :active
      @on_open.call(active_element) unless @on_open.nil?
    end
  end

  def on_open(&block)
    @on_open = block
  end

  def tile_height
    title_heights = Element.find("##{@id} li").length * @title_height
    @height - title_heights
  end

  def height=(value)
    @height = value
    Element.find("##{@id} li.active").each do |e|
      e.css :height => tile_height
    end
  end

end