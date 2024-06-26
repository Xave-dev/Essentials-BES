class Window_PokemonOption < Window_DrawableCommand
  attr_reader :mustUpdateOptions

  def initialize(options,x,y,width,height)
    @options=options
    @nameBaseColor=Color.new(24*8,15*8,0)
    @nameShadowColor=Color.new(31*8,22*8,10*8)
    @selBaseColor=Color.new(31*8,6*8,3*8)
    @selShadowColor=Color.new(31*8,17*8,16*8)
    @optvalues=[]
    @mustUpdateOptions=false
    for i in 0...@options.length
      @optvalues[i]=0
    end
    super(x,y,width,height)
  end

  def [](i)
    return @optvalues[i]
  end

  def []=(i,value)
    @optvalues[i]=value
    refresh
  end

  def itemCount
    return @options.length+1
  end

  def drawItem(index,count,rect)
    rect=drawCursor(index,rect)
    optionname=(index==@options.length) ? _INTL("Salir") : @options[index].name
    optionwidth=(rect.width*9/20)
    pbDrawShadowText(self.contents,rect.x,rect.y,optionwidth,rect.height,optionname,
       @nameBaseColor,@nameShadowColor)
    self.contents.draw_text(rect.x,rect.y,optionwidth,rect.height,optionname)
    return if index==@options.length
    if @options[index].is_a?(EnumOption)
      if @options[index].values.length>1
        totalwidth=0
        for value in @options[index].values
          totalwidth+=self.contents.text_size(value).width
        end
        spacing=(optionwidth-totalwidth)/(@options[index].values.length-1)
        spacing=0 if spacing<0
        xpos=optionwidth+rect.x
        ivalue=0
        for value in @options[index].values
          pbDrawShadowText(self.contents,xpos,rect.y,optionwidth,rect.height,value,
             (ivalue==self[index]) ? @selBaseColor : self.baseColor,
             (ivalue==self[index]) ? @selShadowColor : self.shadowColor
          )
          self.contents.draw_text(xpos,rect.y,optionwidth,rect.height,value)
          xpos+=self.contents.text_size(value).width
          xpos+=spacing
          ivalue+=1
        end
      else
        pbDrawShadowText(self.contents,rect.x+optionwidth,rect.y,optionwidth,rect.height,
           optionname,self.baseColor,self.shadowColor)
      end
    elsif @options[index].is_a?(NumberOption)
      value=sprintf("Tipo %d/%d",@options[index].optstart+self[index],
         @options[index].optend-@options[index].optstart+1)
      xpos=optionwidth+rect.x
      pbDrawShadowText(self.contents,xpos,rect.y,optionwidth,rect.height,value,
         @selBaseColor,@selShadowColor)
    elsif @options[index].is_a?(SliderOption)
      value=sprintf(" %d",@options[index].optend)
      sliderlength=optionwidth-self.contents.text_size(value).width
      xpos=optionwidth+rect.x
      self.contents.fill_rect(xpos,rect.y-2+rect.height/2,
         optionwidth-self.contents.text_size(value).width,4,self.baseColor)
      self.contents.fill_rect(
         xpos+(sliderlength-8)*(@options[index].optstart+self[index])/@options[index].optend,
         rect.y-8+rect.height/2,
         8,16,@selBaseColor)
      
      value=sprintf("%d",@options[index].optstart+self[index])
      xpos+=optionwidth-self.contents.text_size(value).width
      pbDrawShadowText(self.contents,xpos,rect.y,optionwidth,rect.height,value,
         @selBaseColor,@selShadowColor)
    else
      value=@options[index].values[self[index]]
      xpos=optionwidth+rect.x
      pbDrawShadowText(self.contents,xpos,rect.y,optionwidth,rect.height,value,
         @selBaseColor,@selShadowColor)
      self.contents.draw_text(xpos,rect.y,optionwidth,rect.height,value)
    end
  end

  def update
    dorefresh=false
    oldindex=self.index
    @mustUpdateOptions=false
    super
    dorefresh=self.index!=oldindex
    if self.active && self.index<@options.length
      if Input.repeat?(Input::LEFT)
        self[self.index]=@options[self.index].prev(self[self.index])
        dorefresh=true
        @mustUpdateOptions=true
      elsif Input.repeat?(Input::RIGHT)
        self[self.index]=@options[self.index].next(self[self.index])
        dorefresh=true
        @mustUpdateOptions=true
      end
    end
    refresh if dorefresh
  end
end



module PropertyMixin
  def get
    @getProc ? @getProc.call() : nil
  end

  def set(value)
    @setProc.call(value) if @setProc
  end
end



class EnumOption
  include PropertyMixin
  attr_reader :values
  attr_reader :name

  def initialize(name,options,getProc,setProc)            
    @values=options
    @name=name
    @getProc=getProc
    @setProc=setProc
  end

  def next(current)
    index=current+1
    index=@values.length-1 if index>@values.length-1
    return index
  end

  def prev(current)
    index=current-1
    index=0 if index<0
    return index
  end
end



class EnumOption2
  include PropertyMixin
  attr_reader :values
  attr_reader :name

  def initialize(name,options,getProc,setProc)             
    @values=options
    @name=name
    @getProc=getProc
    @setProc=setProc
  end

  def next(current)
    index=current+1
    index=@values.length-1 if index>@values.length-1
    return index
  end

  def prev(current)
    index=current-1
    index=0 if index<0
    return index
  end
end



class NumberOption
  include PropertyMixin
  attr_reader :name
  attr_reader :optstart
  attr_reader :optend

  def initialize(name,optstart,optend,getProc,setProc)
    @name=name
    @optstart=optstart
    @optend=optend
    @getProc=getProc
    @setProc=setProc
  end

  def next(current)
    index=current+@optstart
    index+=1
    if index>@optend
      index=@optstart
    end
    return index-@optstart
  end

  def prev(current)
    index=current+@optstart
    index-=1
    if index<@optstart
      index=@optend
    end
    return index-@optstart
  end
end



class SliderOption
  include PropertyMixin
  attr_reader :name
  attr_reader :optstart
  attr_reader :optend

  def initialize(name,optstart,optend,optinterval,getProc,setProc)
    @name=name
    @optstart=optstart
    @optend=optend
    @optinterval=optinterval
    @getProc=getProc
    @setProc=setProc
  end

  def next(current)
    index=current+@optstart
    index+=@optinterval
    if index>@optend
      index=@optend
    end
    return index-@optstart
  end

  def prev(current)
    index=current+@optstart
    index-=@optinterval
    if index<@optstart
      index=@optstart
    end
    return index-@optstart
  end
end

#####################
#
# Stores game options
# Default options are at the top of script section SpriteWindow.

$SpeechFrames=[
  MessageConfig::TextSkinName, # Default: speech hgss 1
  "speech hgss 2",
  "speech hgss 3",
  "speech hgss 4",
  "speech hgss 5",
  "speech hgss 6",
  "speech hgss 7",
  "speech hgss 8",
  "speech hgss 9",
  "speech hgss 10",
  "speech hgss 11",
  "speech hgss 12",
  "speech hgss 13",
  "speech hgss 14",
  "speech hgss 15",
  "speech hgss 16",
  "speech hgss 17",
  "speech hgss 18",
  "speech hgss 19",
  "speech hgss 20",
  "speech pl 18"
]

$TextFrames=[
  "Graphics/Windowskins/"+MessageConfig::ChoiceSkinName, # Default: choice 1
  "Graphics/Windowskins/choice 2",
  "Graphics/Windowskins/choice 3",
  "Graphics/Windowskins/choice 4",
  "Graphics/Windowskins/choice 5",
  "Graphics/Windowskins/choice 6",
  "Graphics/Windowskins/choice 7",
  "Graphics/Windowskins/choice 8",
  "Graphics/Windowskins/choice 9",
  "Graphics/Windowskins/choice 10",
  "Graphics/Windowskins/choice 11",
  "Graphics/Windowskins/choice 12",
  "Graphics/Windowskins/choice 13",
  "Graphics/Windowskins/choice 14",
  "Graphics/Windowskins/choice 15",
  "Graphics/Windowskins/choice 16",
  "Graphics/Windowskins/choice 17",
  "Graphics/Windowskins/choice 18",
  "Graphics/Windowskins/choice 19",
  "Graphics/Windowskins/choice 20",
  "Graphics/Windowskins/choice 21",
  "Graphics/Windowskins/choice 22",
  "Graphics/Windowskins/choice 23",
  "Graphics/Windowskins/choice 24",
  "Graphics/Windowskins/choice 25",
  "Graphics/Windowskins/choice 26",
  "Graphics/Windowskins/choice 27",
  "Graphics/Windowskins/choice 28"
]

$VersionStyles=[
  [MessageConfig::FontName], # Default font style - Power Green/"Pokemon Emerald"
  ["Power Red and Blue"],
  ["Power Red and Green"],
  ["Power Clear"]
]

def pbSettingToTextSpeed(speed)
  return 2 if speed==0
  return 1 if speed==1
  return -2 if speed==2
  return MessageConfig::TextSpeed if MessageConfig::TextSpeed
  return ((Graphics.frame_rate>40) ? -2 : 1)
end



module MessageConfig
  def self.pbDefaultSystemFrame
    if !$PokemonSystem
      return pbResolveBitmap("Graphics/Windowskins/"+MessageConfig::ChoiceSkinName)||""
    else
      return pbResolveBitmap($TextFrames[$PokemonSystem.frame])||""
    end
  end

  def self.pbDefaultSpeechFrame
    if !$PokemonSystem
      return pbResolveBitmap("Graphics/Windowskins/"+MessageConfig::TextSkinName)||""
    else
      return pbResolveBitmap("Graphics/Windowskins/"+$SpeechFrames[$PokemonSystem.textskin])||""
    end
  end

  def self.pbDefaultSystemFontName
    if !$PokemonSystem
      return MessageConfig.pbTryFonts(MessageConfig::FontName,"Arial Narrow","Arial")
    else
      return MessageConfig.pbTryFonts($VersionStyles[$PokemonSystem.font][0],"Arial Narrow","Arial")
    end
  end

  def self.pbDefaultTextSpeed
    return pbSettingToTextSpeed($PokemonSystem ? $PokemonSystem.textspeed : nil)
  end

  def pbGetSystemTextSpeed
    return $PokemonSystem ? $PokemonSystem.textspeed : ((Graphics.frame_rate>Graphics.frame_rate) ? 2 :  3)
  end
end



class PokemonSystem
  attr_accessor :textspeed
  attr_accessor :battlescene
  attr_accessor :battlestyle
  attr_accessor :frame
  attr_accessor :textskin
  attr_accessor :font
  attr_accessor :screensize
  attr_accessor :language
  attr_accessor :border
  attr_accessor :runstyle
  attr_accessor :bgmvolume
  attr_accessor :sevolume

  def language
    return (!@language) ? 0 : @language
  end

  def textskin
    return (!@textskin) ? 0 : @textskin
  end

  def border
    return (!@border) ? 0 : @border
  end

  def runstyle
    return (!@runstyle) ? 0 : @runstyle
  end

  def bgmvolume
    return (!@bgmvolume) ? 100 : @bgmvolume
  end

  def sevolume
    return (!@sevolume) ? 100 : @sevolume
  end

  def tilemap; return MAPVIEWMODE; end

  def initialize
    @textspeed   = 2   # Text speed (0=slow, 1=normal, 2=fast)
    @battlescene = 0   # Battle effects (animations) (0=on, 1=off)
    @battlestyle = 0   # Battle style (0=switch, 1=set)
    @frame       = 0   # Default window frame (see also $TextFrames)
    @textskin    = 0   # Speech frame
    @font        = 0   # Font (see also $VersionStyles)
    @screensize  = (DEFAULTSCREENZOOM.floor).to_i # 0=half size, 1=full size, 2=double size
    @border      = 0   # Screen border (0=off, 1=on)
    @language    = 0   # Language (see also LANGUAGES in script PokemonSystem)
    @runstyle    = 0   # Run key functionality (0=hold to run, 1=toggle auto-run)
    @bgmvolume   = 100 # Volume of background music and ME
    @sevolume    = 100 # Volume of sound effects
  end
end



class PokemonOptionScene
  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

 def pbStartScene(inloadscreen=false)
    @sprites={}
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    @sprites["title"]=Window_UnformattedTextPokemon.newWithSize(
       _INTL("Opciones"),0,0,Graphics.width,64,@viewport)
    unless NO_TETXBOX_OPTIONS
      @sprites["textbox"]=Kernel.pbCreateMessageWindow
      @sprites["textbox"].letterbyletter=false
      @sprites["textbox"].text=_INTL("Marco de diálogo {1}.",1+$PokemonSystem.textskin)
    end
    #Éstas son las distintas opciones del juego. Para agregar una opción, se debe definir un
    # setter y un getter para esa opción. Para borrar una opción, comentarla
    # o borrarla. Las opciones del juego se pueden ubicar en cualquier orden.
    @PokemonOptions=[
       SliderOption.new(_INTL("Volumen Música"),0,100,5,
          proc { $PokemonSystem.bgmvolume },
          proc {|value|
             if $PokemonSystem.bgmvolume!=value
               $PokemonSystem.bgmvolume=value
               if $game_system.playing_bgm != nil && !inloadscreen
                 $game_system.playing_bgm.volume=value
                 playingBGM=$game_system.getPlayingBGM
                 $game_system.bgm_pause
                 $game_system.bgm_resume(playingBGM)
               end
               if $game_map
                 $game_map.autoplay
               end
             end
          }
       ),
       SliderOption.new(_INTL("Volumen Efec. Esp."),0,100,5,
          proc { $PokemonSystem.sevolume },
          proc {|value|
             if $PokemonSystem.sevolume!=value
               $PokemonSystem.sevolume=value
               if $game_system.playing_bgs != nil
                 $game_system.playing_bgs.volume=value
                 playingBGS=$game_system.getPlayingBGS
                 $game_system.bgs_pause
                 $game_system.bgs_resume(playingBGS)
               end
               pbPlayCursorSE()
             end
          }
       ),
       EnumOption.new(_INTL("Velocidad del texto"),[_INTL("Lenta"),_INTL("Normal"),_INTL("Rápida")],
          proc { $PokemonSystem.textspeed },
          proc {|value|
             $PokemonSystem.textspeed=value 
             MessageConfig.pbSetTextSpeed(pbSettingToTextSpeed(value)) 
          }
       ),
       EnumOption.new(_INTL("Animación de batalla"),[_INTL("Sí"),_INTL("No")],
          proc { $PokemonSystem.battlescene },
          proc {|value| $PokemonSystem.battlescene=value }
       ),
       EnumOption.new(_INTL("Estilo de batalla"),[_INTL("Cambio"),_INTL("Mantener")],
          proc { $PokemonSystem.battlestyle },
          proc {|value| $PokemonSystem.battlestyle=value }
       ),
       EnumOption.new(_INTL("Tecla Correr"),[_INTL("Sostener"),_INTL("Pulsar")],
          proc { $PokemonSystem.runstyle },
          proc {|value|
             if $PokemonSystem.runstyle!=value
               $PokemonSystem.runstyle=value
               $PokemonGlobal.runtoggle=false if $PokemonGlobal
             end
          }
       ),

    ]
    
    unless NO_TETXBOX_OPTIONS
      @PokemonOptions+=[
        NumberOption.new(_INTL("Marco de diálogo"),1,$SpeechFrames.length,
            proc { $PokemonSystem.textskin },
            proc {|value| 
               $PokemonSystem.textskin=value
               MessageConfig.pbSetSpeechFrame("Graphics/Windowskins/"+$SpeechFrames[value])
            }
         ),
         NumberOption.new(_INTL("Marco del menú"),1,$TextFrames.length,
            proc { $PokemonSystem.frame },
            proc {|value|
               $PokemonSystem.frame=value
               MessageConfig.pbSetSystemFrame($TextFrames[value]) 
            }
         )
      ]
    end
# ------------------------------------------------------------------------------
# Quote this section out if you don't want to allow players to change the screen
# size.

# BES-T OPCIONES LEGACY, quita el =begin y el =end si quieres usarlas.
=begin
@PokemonOptions.push(
      EnumOption.new(_INTL("Estilo de fuente"),[_INTL("Em"),_INTL("R/S"),_INTL("FRLG"),_INTL("DP")],
          proc { $PokemonSystem.font },
          proc {|value|
             $PokemonSystem.font=value
             MessageConfig.pbSetSystemFontName($VersionStyles[value])
          }
        ),
    
       EnumOption.new(_INTL("Tamaño de ventana"),[_INTL("P"),_INTL("M"),_INTL("G"),_INTL("MG"),_INTL("Compl")],
          proc { $PokemonSystem.screensize },
          proc {|value|
             oldvalue=$PokemonSystem.screensize
             $PokemonSystem.screensize=value
             if value!=oldvalue
               pbSetResizeFactor($PokemonSystem.screensize)
               ObjectSpace.each_object(TilemapLoader){|o| next if o.disposed?; o.updateClass }
             end
          }
       ),
# ------------------------------------------------------------------------------
       EnumOption.new(_INTL("Borde de pantalla"),[_INTL("No"),_INTL("Sí")],
          proc { $PokemonSystem.border },
          proc {|value|
             oldvalue=$PokemonSystem.border
             $PokemonSystem.border=value
             if value!=oldvalue
               pbSetResizeFactor($PokemonSystem.screensize)
               ObjectSpace.each_object(TilemapLoader){|o| next if o.disposed?; o.updateClass }
             end
          }
       )
    ]
=end
    @PokemonOptions=pbAddOnOptions(@PokemonOptions)
    unless NO_TETXBOX_OPTIONS
      @sprites["option"]=Window_PokemonOption.new(@PokemonOptions,0,
                         @sprites["title"].height,Graphics.width,
                         Graphics.height-
                         @sprites["title"].height-@sprites["textbox"].height)
    else
      @sprites["option"]=Window_PokemonOption.new(@PokemonOptions,0,
                         @sprites["title"].height,Graphics.width,
                         Graphics.height-
                         @sprites["title"].height)
    end
    @sprites["option"].viewport=@viewport
    @sprites["option"].visible=true
    # Get the values of each option
    for i in 0...@PokemonOptions.length
      @sprites["option"][i]=(@PokemonOptions[i].get || 0)
    end
    pbDeactivateWindows(@sprites)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbAddOnOptions(options)
    return options
  end

  def pbOptions
    pbActivateWindow(@sprites,"option"){
       loop do
         Graphics.update
         Input.update
         pbUpdate
         if @sprites["option"].mustUpdateOptions
           # Set the values of each option
           for i in 0...@PokemonOptions.length
             @PokemonOptions[i].set(@sprites["option"][i])
           end
           unless NO_TETXBOX_OPTIONS
             @sprites["textbox"].setSkin(MessageConfig.pbGetSpeechFrame())
             @sprites["textbox"].width=@sprites["textbox"].width  # Necessary evil
             pbSetSystemFont(@sprites["textbox"].contents)
             @sprites["textbox"].text=_INTL("Cuadro diálogo {1}.",1+$PokemonSystem.textskin)
           end
         end
         if Input.trigger?(Input::B)
           break
         end
         if Input.trigger?(Input::C) && @sprites["option"].index==@PokemonOptions.length
           break
         end
       end
    }
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    # Set the values of each option
    for i in 0...@PokemonOptions.length
      @PokemonOptions[i].set(@sprites["option"][i])
    end
    Kernel.pbDisposeMessageWindow(@sprites["textbox"]) unless NO_TETXBOX_OPTIONS
    pbDisposeSpriteHash(@sprites)
    pbRefreshSceneMap
    @viewport.dispose
  end
end



class PokemonOption
  def initialize(scene)
    @scene=scene
  end

  def pbStartScreen(inloadscreen=false)
    @scene.pbStartScene(inloadscreen)
    @scene.pbOptions
    @scene.pbEndScene
  end
end