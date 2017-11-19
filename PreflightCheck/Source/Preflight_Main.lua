-- ############################################################################# 
-- # DC/DS Preflight Check - Lua application for JETI DC/DS transmitters  
-- #
-- # Copyright (c) 2016 - 2017, JETI model s.r.o.
-- # All rights reserved.
-- #
-- # Redistribution and use in source and binary forms, with or without
-- # modification, are permitted provided that the following conditions are met:
-- # 
-- # 1. Redistributions of source code must retain the above copyright notice, this
-- #    list of conditions and the following disclaimer.
-- # 2. Redistributions in binary form must reproduce the above copyright notice,
-- #    this list of conditions and the following disclaimer in the documentation
-- #    and/or other materials provided with the distribution.
-- # 
-- # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- # ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- # WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- # DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
-- # ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- # (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- # LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- # ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- # (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- # SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-- # 
-- # The views and conclusions contained in the software and documentation are those
-- # of the authors and should not be interpreted as representing official policies,
-- # either expressed or implied, of the FreeBSD Project.                    
-- #                       
-- # V1.0 - Initial release
-- # V1.1 - Added Spanish and Italian language
-- # V1.2 - The readFile() function has been replaced by internal io.readall() (DC/DS FW V4.22)
-- # V1.2.1 - Modified by Geierwally: adapted with optional audiofiles for check and  full \ partial check 
-- # V1.2.2 - Bugfixed by Geierwally: 
-- #          1. question full or partial check opens if no switch is configured 
-- #          2. failure in partial check, wrong listindex set on optionExec- list
-- # V1.2.3 - Bugfixes and modifications by Geierwally
-- # 		  1. new feature overwrite option full or partial check model specific
-- #          2. bugfix audio of first preflight check interrupts startup sound of transmitters
-- #          3. bugfix set audio option default as switched official
-- # V1.2.4 - Bugfixes and modifications by Geierwally
-- # 		  1. new behavior to avoid storage lack on 16 and 14 transmitters 
-- # 		  2. control 1 implemented , active if all checks were done 
-- #          3. additional audio message preflight check finished
-- #############################################################################

--Configuration
local optionsValues={}
local cfgAudio
local cfgSwitch
--Local variables
local lang
local options={}    
local optionAudios={} -- modified by Geierwally: contains audio filenames for the preflight check slices
local optionExec={}   -- modified by Geierwally: contains information of preflight check slices executed in full - or partial check 
local appName="Preflight Check"
local selectboxes={} 
local checkboxes={}
local currentForm=0
local MAX_ITEMS = 20
local lastSwitchValue=true
local fullCheck=false -- modified by Geierwally: if value is true, a full preflight check is executed (done each 12 hours)
local currentTime=0	  -- modified by Geierwally: time stamp for calculation 12 hour full check time
local prevRow=0		  -- modified by Geierwally: previous row for detection new checkbox is selected  (play corresponding audio file of check slice)
local audioListIndex={}	  -- modified by Geierwally: contains corresponding index to audio files list 
local lng = nil	
 
--------------------------------------------------------------------
-- Configure language settings
--------------------------------------------------------------------
local function setLanguage()
  -- Set language
  lng=system.getLocale();
  local file = io.readall("Apps/Preflight/lang/"..lng.."/locale.jsn")
  local obj = json.decode(file)  
  if(obj) then
    lang = obj
  end
end
--------------------------------------------------------------------
-- Setting forms
--------------------------------------------------------------------
local function checkButtons()
  if(currentForm==1) then
    form.setButton(3,":add", #optionsValues < MAX_ITEMS and ENABLED or DISABLED)
    form.setButton(4,":delete",#optionsValues>0 and ENABLED or DISABLED)
    form.setButton(1,":tools",ENABLED)
  end
end
--------------------------------------------------------------------

local function optionChanged()
  for k, v in ipairs(selectboxes) do 
    optionsValues[k]=form.getValue(v)
  end
  system.pSave("items",optionsValues)
end

local function optionExecChanged()
  system.pSave("optionExec",optionExec)
end

local function audioChanged(value)
  cfgAudio=value
  system.pSave("audioOn",value)
end
local function switchChanged(value)
  cfgSwitch=value
  system.pSave("switch",value)
end
--------------------------------------------------------------------
-- init form
--------------------------------------------------------------------
local function initForm(formID)
  selectboxes={}
  currentForm=formID
  if(formID==1) then 
    for index=1,#optionsValues do
      form.addRow(2)
      form.addLabel({label=index..")",alignRight=true,width=40,font=FONT_BOLD})
      selectboxes[index]=form.addSelectbox(options,optionsValues[index],true,optionChanged,{width=260})
    end 
  else 
    form.addLabel({label=lang.cfgName,font=FONT_BOLD})
    -- Assigned audio file
    form.addRow(2)
    form.addLabel({label=lang.audio})
	form.addIntbox(cfgAudio,0,1,0,0,1,audioChanged)
    -- Assigned switch
    form.addRow(2)
    form.addLabel({label=lang.switch})
    form.addInputbox(cfgSwitch,false,switchChanged)
    
  end
  checkButtons()
end 

 
--------------------------------------------------------------------
--Geierwally Key pressed on init form
local function keyPressed(key)
  if(currentForm==1) then
    if(key==KEY_3 and #optionsValues < MAX_ITEMS) then
      form.addRow(2)
      local vals = #optionsValues+1
      form.addLabel({label=(vals)..")",alignRight=true,width=40,font=FONT_BOLD})
      optionsValues[vals] = 0
      selectboxes[vals]=form.addSelectbox(options,0,true,optionChanged,{width=260})
      form.setFocusedRow(vals)
      --Save current selection
      optionChanged()
      checkButtons()
      return
    end
    local row = form.getFocusedRow()
	if ((optionsValues[row] ~=nil)and (optionsValues[row] >0)) then
	-- Modified by Geierwally: set full or partial check model specific (overwrite default list)
		if(key==KEY_2) then
			if (optionExec[optionsValues[row]]==lang.option_full_check) then
				optionExec[optionsValues[row]]=lang.option_partial_check
			else
				optionExec[optionsValues[row]]=lang.option_full_check
			end
			optionExecChanged()
		end
	end
	
    if(key==KEY_4 and row>0) then
      table.remove(optionsValues,row)
      table.remove(selectboxes,row) 
      optionChanged()
      form.reinit(1)
      return
    end 
    if(key==KEY_1) then
      form.reinit(2)
    end
  else
    if(key==KEY_1) then
      -- file playback
	  if(cfgAudio==1) then
	    --print("Apps/Preflight/Audio/"..lng.."/P_PlBack.wav")
		system.playFile("/Apps/Preflight/Audio/"..lng.."/P_PlBack.wav",AUDIO_QUEUE)
	  end	
    elseif(key==KEY_5 or key==KEY_ESC) then
      form.preventDefault()
      form.reinit(1)
    end
  end
end

  
--------------------------------------------------------------------
-- Preflight check form
--------------------------------------------------------------------
local function clickedCallback(value)
  local row = form.getFocusedRow()
  form.setValue(checkboxes[row],true)
  local removeForm = true
  for index=1,#checkboxes do
    if(form.getValue(checkboxes[index]) == 0) then
      removeForm = false
    end
  end
  if (removeForm) then
  	-- modified by Geierwally: if last preflight check was a full check, then safe current time as cycle time for next full check
	if(fullCheck==true)then
		fullCheck=false
		system.pSave("fullCheckTime",currentTime)
	end
	system.setControl(1,1,0,0) -- set control preflight check finished
	if(cfgAudio==1) then
		--print("Apps/Preflight/Audio/"..lng.."/P_Finish.wav")
		system.playFile("/Apps/Preflight/Audio/"..lng.."/P_Finish.wav",AUDIO_QUEUE)
	end	
    form.close()
  end
end


--------------------------------------------------------------------
local function initFormPrefl(formID)
  -- form.setButton(5,"",ENABLED) 
  local i=1
  audioListIndex={}
  checkboxes={}
  system.setControl(1,0,0,0) -- reset control preflight check finished
  currentTime=system.getTime()
  local fullCheckTime = system.pLoad("fullCheckTime",0)
  prevRow=1 -- bugfixed by Geierwally: set previous row to 1 to avoid failure on playing first audio file
  
  -- modified by Geierwally: if time difference to last full preflight check is higher than 12 hours then start full preflight check 
  --                         otherwise only partial 
  if((currentTime-fullCheckTime > 43200)or (fullCheckTime == 0)) then
	fullCheck=true
  else
    fullCheck=false
	if(lastSwitchValue == true) then
		if(form.question(lang.qu_full_check,lang.qu_full_check_label,lang.qu_full_check_descr)==1)then
		--"Full check?","Full preflight check is started"
			fullCheck=true
		end	
	end	
  end

    
  for index=1,#optionsValues do
    -- modified by Geierwally:  if option is configured for full preflight check and timeout is not reached, don't fill corresponding 
 
	if(optionsValues[index] > 0)then
		if(optionExec[optionsValues[index]]==lang.option_full_check and fullCheck==false) then -- bugfixed by Geierwally failure in partial check, wrong listindex set on optionExec- list
		-- modified by Geierwally: skip full checks if allready done
		else
			audioListIndex[i]=optionsValues[index] -- modified by Geierwally: set index for audio file
			form.addRow(3)
			form.addLabel({label=i..")",alignRight=true,width=40,font=FONT_BOLD})
			form.addLabel({label=options[optionsValues[index]],width=220})
			checkboxes[i] = form.addCheckbox(false,clickedCallback)
			i=i+1
		end
	end
  end
  form.setButton(3,":down",ENABLED)
  -- Empty form - immediately close
  if(#checkboxes==0) then
  	system.setControl(1,0,0,0) -- reset control preflight check finished
    form.close()
  end 
  prevRow=0 --modified by Geierwally reset previous row that the audio file is played for first focused row
  
end 


--------------------------------------------------------------------
local function keyPressedPrefl(key)
  local row = form.getFocusedRow()
  local nextRow = row+1
  if(key==KEY_MENU or key==KEY_ESC) then
    form.preventDefault()
  elseif(key==KEY_3)then
    -- modified by Geierwally: next step pressed set actual box to checked and jump to next checkbox
    form.setValue(checkboxes[row],true)
	clickedCallback()
    if(nextRow <= #checkboxes) then
		form.setFocusedRow(nextRow)
	else
		form.setFocusedRow(1)
	end
  end
  -- modified by Geierwally if focus changes to other row, play corresponding audio file
  if(row ~= prevRow)then
    if(cfgAudio==1)then
	  --print(optionAudios[audioListIndex[row]]) 
	  system.playFile("/Apps/Preflight/Audio/"..lng.."/"..optionAudios[audioListIndex[row]].." ",AUDIO_QUEUE)
	end  
    prevRow = row 
  end
end 

-------------------------------------------------------------------- 
-- Initialization
--------------------------------------------------------------------
-- Init function
local function init(code) 
  -- Load data
  local lng=system.getLocale();
  local file = io.readall("Apps/Preflight/lang/"..lng.."/data.jsn")
  system.registerControl(1,lang.preflightCheckCtrl,lang.preflightSw)
  -- modified by Geierwally separate from data file options , 
  --                        corresponding audio files and conditions for 
  --                        full or partial preflight check
  if(file) then
	local sa = string.find(file,"[%[]")
	local ea = string.find(file,"[%]]")
	local sb = string.find(file,"[%[]",ea+1)
	local eb = string.find(file,"[%]]",ea+1)
	local sc = string.find(file,"[%[]",eb+1)
	local ec = string.find(file,"[%]]",eb+1)
	options = json.decode(string.sub(file,sa,ea))
	optionAudios = json.decode(string.sub(file,sb,eb))
	optionExec =  json.decode(string.sub(file,sc,ec))
  end
 
  optionsValues = system.pLoad("items",{})
  local tempExec = system.pLoad("optionExec",{})
  
  -- modified by Geierwally overwrite default exec if modelspecific list exists
  if((#tempExec ~= nil )and (#tempExec >0))then
	optionExec = tempExec
  end
  
  cfgAudio = system.pLoad("audioOn","0")
  cfgSwitch = system.pLoad("switch")
  system.registerForm(1,MENU_ADVANCED,lang.appName,initForm,keyPressed,printForm);
  -- Show the form 
  if(#optionsValues > 0) then
    system.registerForm(0,0,lang.appName,initFormPrefl,keyPressedPrefl);
  end 
end


--------------------------------------------------------------------
-- Loop function
local function loop() 
  local val
  if(cfgSwitch == nil)then -- bugfixed by Geierwally, don't open yes no box if no switch is configured
	val = 0
  else	
    val = system.getInputsVal(cfgSwitch)
  end	
  if(val and val>0 and not lastSwitchValue) then
    lastSwitchValue = true
    local frm=form.getActiveForm() 
    if(frm==0) then
      for index=1,#checkboxes do
        form.setValue(checkboxes[index],false)
      end
    elseif(#optionsValues > 0) then
      system.registerForm(0,0,lang.appName,initFormPrefl,keyPressedPrefl);
    end 
  elseif(val and val<=0) then 
    lastSwitchValue=false  
  end 
  local frm=form.getActiveForm() 
	if(frm==0) then
		if(prevRow ==0)then
      -- modified by Geierwally: play audio file of first preflight check after initialization
			if(cfgAudio==1)then
				--print("Preflightcheck start")
				system.playFile("/Apps/Preflight/Audio/"..lng.."/P_PlBack.wav",AUDIO_QUEUE)
				--print(optionAudios[audioListIndex[1]]) 
				system.playFile("/Apps/Preflight/Audio/"..lng.."/"..optionAudios[audioListIndex[1]].." ",AUDIO_QUEUE)
			end  
			prevRow = 1 
		end
	elseif((frm==1)and(currentForm == 1))then	
	  -- modified by Geierwally: set KEY 3 value at init screen for full, partial and non check
        local row = form.getFocusedRow()
		if ((optionsValues[row] ~=nil)and (optionsValues[row] >0)) then
			form.setButton(2,optionExec[optionsValues[row]],ENABLED)
		else
			form.setButton(2,"N",DISABLED)
		end
	end

end
 

--------------------------------------------------------------------
setLanguage()
--------------------------------------------------------------------
local Preflight_Main = {init,loop}
return Preflight_Main