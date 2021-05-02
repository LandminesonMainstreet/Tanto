-- Tanto sample slicer

-- K1 alt
-- K2 toggle play
-- K3 load sample
-- E1 sample speed
-- E2 sample start
-- E3 sample end
-- Alt+E1 
-- Alt+E2 pre level
-- Alt+E3 rec level


fileselect = require 'fileselect'

beatclock = require 'beatclock'

local saved = "..."
local level = 1.0
local rate = 1.0
local loop_start = 1.0
local loop_end = 2.0
local rec = 1.0
local pre = 0.0
local length = 1
local position = 1
local selecting = false
local waveform_loaded = false
local dimiss_K2_message = false
local record = false
local playing = false
local current_postion = 0

clk = beatclock.new()
clk_midi = midi.connect()
clk_midi.event = clk.process_midi

function load_file(file)
  softcut.buffer_clear_region(1,-1)
  selecting=false
  if file ~= "cancel" then
    local ch, samples = audio.file_info(file)
    length = samples/48000
    softcut.buffer_read_mono(file,0,1,-1,1,1)
    softcut.buffer_read_mono(file,0,1,-1,1,2)
    reset()
    waveform_loaded = true
  end
end

function set_loop_start(v)
  v = util.clamp(v, 0, params:get("loop_end") - .01)
  softcut.loop_start(1, v)
end

function set_loop_end(v)
  v = util.clamp(v, params:get("loop_start") + .01, 350.0)
  softcut.loop_end(1,v)
end

function update_positions(i,pos)
  position = (pos - 1) / length
  if selecting == false then redraw() end
end

function reset()
  for i=1,2 do
    softcut.enable(i,1)
    softcut.buffer(i,i)
    softcut.level(i,1.0)
    softcut.loop(i,1)
    softcut.loop_start(i,1)
    softcut.loop_end(i,1+length)
    softcut.position(i,1)
    softcut.rate(i,1.0)
    softcut.play(i,1)
  end

  softcut.rec_level(2,rec)
  softcut.pre_level(2,pre)
  softcut.rec(2,1)
  update_content(1,1,length,128)
end

function copy_cut()
  local rand_copy_end = math.random(1,util.round(length))
  local rand_copt_start = math.random(1,util.round(rande_copy_end - (rand_copy_end/10)))
  local rand_dest = math.random(1,util.round(length))
  softcut.buffer_copy_mono(2,1,rnd_copy_start, rand_dest,rand_copy_end - rand_copy_start,0.1,math.random(0,1))
  update_content(1,1,length,128)
end

-- WAVEFORMS
local interval = 0
waveform_samples = {}
scale = 30

function on_render(ch,start, i,s)
  waveform_samples = s
  interval = i
  redraw()
end

function update_content(buffer,winstart,winend,samples)
  softcut.render_buffer(buffer, winstart, winend - winstart, 128)
end

--/ WAVEFORMS

function init()
  softcut.buffer_clear()

  audio.level_adc_cut(1)
  softcut.level_input_cut(1,2,1.0)
  softcut.level_input_cut(2,2,1.0)

  softcut.phase_quant(1,0.025)
  softcut.event_phase(update_positions)
  softcut.poll_start_phase()
  softcut.event_render(on_render)
  
  clk.on_select_internal = function() clk:start() end
  clk.on_select_external = function() print("external") end
  clk:add_clock_params()
  
  params:add_separator()
  params:add_file("sample", "sample")
  params:set_action("sample", function(file) load_sample(file) end)
  
  --sample start
  params:add_control("loop_start", "loop start", controlspec.new(0.0, 349.99, "lin", .01, 0, "secs"))
  params:set_action("loop_start", function(x) set_loop_start(x) end)
  --sample end
  params:add_control("loop_end", "loop end", controlspec.new(.01, 350, "lin", .01, 4, "secs"))
  params:set_action("loop_end", function(x) set_loop_end(x) end)
  
  --screen metro
  local screen_timer = metro.init()
  screen_timer.time = 1/15
  screen_timer_event = function() redraw() end
  screen_timer:start()
  
  softcut.phase_quant(1, .01)
  softcut.event_phase(update_positions)
  softcut.poll_start_phase()
  
  
  
  clk:start()
    end

function key(n,z)
  -- set alt key
  if n==1 then alt = z==1 and true or false
  end
  
  if n==2 and z==1 then
     if alt then
    -- nothing here
   else
     -- toggle rec sample playback
      if playing == true then
        softcut.play(1,0)
        playing = false
      else
        softcut.position(1,0)
        softcut.play(1,1)
        playing = true
      end    
    end
  elseif n==3 and z==1 then
    if alt then
      -- save file
    saved = "ss7-"..string.format("%04.0f",10000*math.random())..".wav"
    softcut.buffer_write_mono(_path.dust.."/audio/"..saved,1,length,1)
  
  else
    -- load file
    selecting = true
    fileselect.enter(_path.dust,load_file)

end
end
end

function enc(n,d)
    if n==1 then
      if alt then
        -- maybe filter, don't know yet
      elseif n==1 then
         -- rate control
        rate = util.clamp(rate+d/100,-4,4)
        softcut.rate(1,rate)
      end
        
    else
    if n==2 then
      if alt then
      -- pre level
      pre=utli.clamp(pre+d/100,0,1)
      softcut.pre_level(1,pre)
      elseif n==2 then
        -- loop start
        params:delta("loop_start", d * .005)     
        
      end
    else
    if n==3 then
      if alt then
      -- rec level
      rec=util.clamp(rec+d/100,0,1)
      softcut.rec_level(1,rec)
      elseif n==3 then
        -- loop end
        params:delta("loop_end",d * .005)   
        
      end
  end
end
  redraw()
end
end

function redraw()
  screen.clear()
  screen.aa(1)

  if not waveform_loaded then
    screen.level(15)
    screen.move(62,40)
    screen.text_center("hold K3 to load sample")
    screen.move(80,20)
    screen.text("rate: ")


  else
    screen.level(15)
    screen.move(85,5)
    if not dismiss_K2_message then
    else
      screen.text_center("K3: save new clip")
    end

 screen.level(4)
    local x_pos = 0
    for i,s in ipairs(waveform_samples) do
      local height = util.round(math.abs(s) * (scale*level))
      screen.move(util.linlin(0,128,10,120,x_pos), 35 - height)
      screen.line_rel(0, 2 * height)
      screen.stroke()
      x_pos = x_pos + 1
    end
    screen.level(15)
    screen.move(util.linlin(0,1,10,120,position),18)
    screen.line_rel(0, 35)
    screen.stroke()
  end
  
  screen.level(15)
  screen.move(80,20)
  screen.text("rate: ")
  screen.move(120,20)
  screen.text_right(string.format("%.2f",rate))

  screen.move(40,60)
  screen.text_center("start: " .. string.format("%.2f", params:get("loop_start")))

  screen.move(90,60)
  screen.text_center("end: " .. string.format("%.2f", params:get("loop_end")))
  screen.update()
end
 