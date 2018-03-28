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
-- # V1.2.5 - Folderhirarchy for audiofiles moved into apps folder
-- # V1.3.5 - special version lock yes no option box on partial check  
-- #############################################################################

--Configuration
--Local variables
local appLoaded = false
local main_lib = nil  -- lua main script
local initDelay = 0
local mem = 0
local debugmem = 0

-------------------------------------------------------------------- 
-- Initialization
--------------------------------------------------------------------
local function init(code)
	if(initDelay == 0)then
		initDelay = system.getTimeCounter()
	end	
	if(main_lib ~= nil) then
		local func = main_lib[1]
		func(0) --init(0)
	end
end


--------------------------------------------------------------------
-- main Loop function
--------------------------------------------------------------------
local function loop() 
	currentTimeF3K = system.getTimeCounter()
	 -- load current task
    if(main_lib == nil)then
		init(0)
		if((system.getTimeCounter() - initDelay > 5000)and(initDelay ~=0)) then
			if(appLoaded == false)then
				local memTxt = "max: "..mem.."K act: "..debugmem.."K"
				print(memTxt)
				main_lib = require("Preflight/Task/Preflight_Main")
				if(main_lib ~= nil)then
					appLoaded = true
					init(0)
					initDelay = 0
				end
				collectgarbage()
			end
		end
	else
		local func = main_lib[2] --loop()
		func() -- execute main loop
	end	
	debugmem = math.modf(collectgarbage('count'))
	if (mem < debugmem) then
		mem = debugmem
		local memTxt = "max: "..mem.."K act: "..debugmem.."K"
		print(memTxt)
	end
end
 
--------------------------------------------------------------------

return { init=init, loop=loop, author="JETI model", version="1.3.5",name="Preflight Check"}