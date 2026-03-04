-- Initialize tables to store the initial voxel counts of parts
local initialVoxelCounts = {}

local fuselage = 0
local seatLoc = 0
local seatOffset = Transform(Vec(0,0,0))
camAngleX, camAngleY = 0, 0
camDistance = 15
shared.sensitivity = 0.005
shared.zoomSpeed = 1.5
local CameraMode = 1
 shared.mouseaimPos = Vec(0,0,0)

shared.manned = false
shared.pilot = nil

#version 2
#include "script/include/player.lua"
#include "script/include/common.lua"

function server.init()
overheat_timer=0
jammed=false
shared.lock_alarm = LoadLoop("MOD/Dynamic-Aircraft/Snd/aircraft-sfx/shared.lock_alarm.ogg")
WaterLights=FindLights("waterbomb")
waterbomb=false
waterbomb_timer=1.5
shared.aoa_timer=0
ammo=1000
shared.missile_count=0
reloadSnd=LoadSound("MOD/Dynamic-Aircraft/Snd/reload.ogg")
shared.aoa_limiter=true

col_main  = {1.0, 0.55, 0.2, 1.0}   -- warm orange (main HUD)
col_glow  = {1.0, 0.6, 0.25, 0.3}   -- soft glow accent

baillight=FindLight("bailout")
paradrops=FindLights("paradrop")
bailouttimer=0
droptimer=0
dropdoors=FindShapes("dropdoor")
reaction_timer=0
ignition_timer=0
shorter_ignition_timer=0

mouse_steer=Vec(0,0,0)
RPMMute=1
CamPosition=Vec(0,0,0)
CamZoomSmoother=0
	DopplerDistance=0
	DopplerDistanceNew=0
	DopplerDifference=0
	RoarTimer=2
	RoarCooldown=2

		RoarSndTable = {
		"MOD/Dynamic-Aircraft/Snd/aircraft-sfx/JetScream1.ogg",
		"MOD/Dynamic-Aircraft/Snd/aircraft-sfx/JetScream2.ogg",
		"MOD/Dynamic-Aircraft/Snd/aircraft-sfx/JetScream3.ogg"
	}

				PropSndTable = {
		"MOD/Dynamic-Aircraft/Snd/aircraft-sfx/prop_fail1.ogg",
		"MOD/Dynamic-Aircraft/Snd/aircraft-sfx/prop_fail2.ogg",
		"MOD/Dynamic-Aircraft/Snd/aircraft-sfx/prop_fail3.ogg",
		"MOD/Dynamic-Aircraft/Snd/aircraft-sfx/prop_fail4.ogg",
		"MOD/Dynamic-Aircraft/Snd/aircraft-sfx/prop_fail5.ogg",
		"MOD/Dynamic-Aircraft/Snd/aircraft-sfx/prop_fail6.ogg",
		"MOD/Dynamic-Aircraft/Snd/aircraft-sfx/prop_fail7.ogg",
	}
					JetSndTable = {
		"MOD/Dynamic-Aircraft/Snd/aircraft-sfx/crash1.ogg",
		"MOD/Dynamic-Aircraft/Snd/aircraft-sfx/crash2.ogg"
	}
						CrashSndTable = {
		"MOD/Dynamic-Aircraft/Snd/aircraft-sfx/crash1.ogg",
		"MOD/Dynamic-Aircraft/Snd/aircraft-sfx/crash2.ogg",
		"MOD/Dynamic-Aircraft/Snd/aircraft-sfx/crash3.ogg",
		"MOD/Dynamic-Aircraft/Snd/aircraft-sfx/crash4.ogg",
		"MOD/Dynamic-Aircraft/Snd/aircraft-sfx/crash5.ogg",
		"MOD/Dynamic-Aircraft/Snd/aircraft-sfx/crash6.ogg",
		"MOD/Dynamic-Aircraft/Snd/aircraft-sfx/crash7.ogg",
		"MOD/Dynamic-Aircraft/Snd/aircraft-sfx/crash8.ogg",
		"MOD/Dynamic-Aircraft/Snd/aircraft-sfx/crash9.ogg",
		"MOD/Dynamic-Aircraft/Snd/aircraft-sfx/crash10.ogg",
		"MOD/Dynamic-Aircraft/Snd/aircraft-sfx/crash11.ogg",
		"MOD/Dynamic-Aircraft/Snd/aircraft-sfx/crash12.ogg",
	}


	CameraMode=1

	brakesound_timer=0
	total_loss=false
	
	target=GetPlayerTransform()
	
	downtimer=1

	    camDistance = 20  -- Default camera distance from the center
    camAngleX = 0    -- Horizontal rotation angle (Yaw)
    camAngleY = 0    -- Vertical rotation angle (Pitch)
    shared.sensitivity = 0.004  -- Mouse shared.sensitivity for rotation
    shared.zoomSpeed = 1    -- Zoom speed with scroll
	--QUICKTIME LIST
	
	bombbay_timer=2
	bayhinges=FindJoints("bay")

	
	---WIERD DOPPLER PITCH ON CAM CHANGE
	---AMMO
	--NEW EXPLOSION EFFECTS + NAPALM
	--RELOAD RESTRICTION AND ICON
	--GUNNERS
	--RELOAD POINTS FOR PLAYERS
	--GUIDED BOMBS/shared.missiles
	
	--AG AI
	--FIREFIGHTING

	
	
				---TABLE OF CONTENTS---
	
	
	--TO DO

																							--1 Flight Physics 					DONE
																							--2 engine management  				DONE
																							--3 Damage model 					DONE
																							--landing gear/autolaunch 			WORKAROUND
																							--CHASE CAM MOUSE AIMING ASSIST		DONE
																							--GUN SPREAD						DONE
																							--EXHAUST BACKFIRE					DONE
	  																						--WINGTIP SMOKE FOR ALL				DONE
																							--RAGDOLLS                          LESS IMPORTANT
	--BETTER UI
																							--SOUND BARRIER DRAG + MACH 1 AT vel100    DONE
																							--floatplanes								DONE
		
																							--ANIMATED CONTROL SURFACES			DONE																				
																							--TARGET AI			DONE
																							--wing countering					DONE
																							--4 camera and shared.reticle 				DONE
																							--wind countering					DONE
																							--5 Guns							 DONE
																							--6 Other ordnance					DONE
																							--bombs EFFECTS LEFT				DONE
																							--rockets EFFECTS LEFT				DONE
																							--shared.missiles							DONE		
	--BOMBER DEFENCE MODE
	--SHIPS
	--MISSIONS
	
	--END OF TO DO
	
	
	
	
	
	
	
	
	
	
--		1. FUNCTION INIT
		
	--variable values taken from tags
	--steering
	--stabilisation/drag (???)
	--crash tolerance
	
	--gun rpm
	--ordnance (n/a)
	
	--(get) parts
	
	--sound
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	

		
	
		-- Find fuselage and player seat
	fuselage = FindBody("fuselage")
	seatLoc = FindLocation("player")
	-- Calculate static offset between fuselage and seat
	local fuselageT = GetBodyTransform(fuselage)
	local seatT = GetLocationTransform(seatLoc)

	-- Convert seat transform to fuselage local space
	local localPos = TransformToLocalPoint(fuselageT, seatT.pos)
	local localRot = TransformToLocalTransform(fuselageT, seatT)
	seatOffset = Transform(localPos, localRot.rot)
	
	
	
	
	--VARIABLE VALUES
	
		--steering intensity
	troops=tonumber(GetTagValue(fuselage, "troops")) or 18
	
	yaw_force=tonumber(GetTagValue(fuselage, "yaw")) or 0
	
	roll_force=tonumber(GetTagValue(fuselage, "roll")) or 0
		
	pull_force=tonumber(GetTagValue(fuselage, "pull")) or 0
	
	push_force=tonumber(GetTagValue(fuselage, "push")) or 0
	
	pitch_comp=tonumber(GetTagValue(fuselage, "pitch_comp")) or tonumber(GetTagValue(fuselage, "pt_cp")) or 0
	
	yaw_comp=tonumber(GetTagValue(fuselage, "yaw_comp")) or tonumber(GetTagValue(fuselage, "yw_cp")) or 0
	
	pitch_trim=tonumber(GetTagValue(fuselage, "trim")) or tonumber(GetTagValue(fuselage, "trm")) or 0
	
	gyro=tonumber(GetTagValue(fuselage, "gyro")) or tonumber(GetTagValue(fuselage, "gr")) or 0
		
	agility_vel=tonumber(GetTagValue(fuselage, "agility_vel")) or tonumber(GetTagValue(fuselage, "ag_vel")) or 0
	
	engine_power=tonumber(GetTagValue(fuselage, "engine_power")) or tonumber(GetTagValue(fuselage, "pwr")) or 0
	shared.afterburner_strength=tonumber(GetTagValue(fuselage, "shared.afterburner_strength")) or tonumber(GetTagValue(fuselage, "aft_pwr")) or 0
			--stabilisation and drag
	
	    horizontal_stabiliser_stabilisation=tonumber(GetTagValue(fuselage, "pt_stabilisation")) or tonumber(GetTagValue(fuselage, "pt_stab")) or 0
		
		vertical_stabiliser_stabilisation=tonumber(GetTagValue(fuselage, "yw_stabilisation")) or tonumber(GetTagValue(fuselage, "yw_stab")) or 0
		
		wingtip_stabilisation=tonumber(GetTagValue(fuselage, "wingtip_stabilisation")) or tonumber(GetTagValue(fuselage, "wit_stab")) or 0
		
		--horizontal_stabiliser_stabilisation=50
		
		--vertical_stabiliser_stabilisation=120
		
		--wingtip_stabilisation=40
		
	size=tonumber(GetTagValue(fuselage, "size")) or 1	
	
	--default drag
		air_drag=tonumber(GetTagValue(fuselage, "drg")) or 25
		

	
	--terminal airspeed (high drag after exceeding)
	terminal_speed=tonumber(GetTagValue(fuselage, "Vne")) or 25
		--corresponding drag
				terminal_drag=tonumber(GetTagValue(fuselage, "drag")) or 30
			--velocity at which the plane falls apart
			
			windlessdrag_force=tonumber(GetTagValue(fuselage, "wdrg")) or air_drag
			
	breakup_speed=70
	
	--crash tolerance on impact
	crash_tolerance=30
	
	--burn time after impact
	
					--other systems


	
		--gun rpm
	speedmg=.1
	speedcannon=.1
	speedrotary=.1
	speedflare=.1
	speedrocket=.1
	speedbarrage=.1
	
	
	
	timerrocket=.8
	timerbarrage=.4
	timermg=.1
	timercannon=.2
	timerrotary=.05
	timerflare=0.5
	
	direction = Vec(0,0,0)
		
	mgs = FindLights("mg")
	cannons = FindLights("cannon")
	rotarys = FindLights("rotary")

		projectileSpeed = 200
	projectileLifetime = 1.5

	damageMG = 0.15
	damageCannon = 0.3
	damageRotary = 0.2

	penetrationLengthMG = 30


	projectiles = {}

	flares = FindLights("flare")
	tips = FindLights("tip")
	clouds=FindLights("cloud")

		
		
		--ordnance
		weapons=FindLights("weapon")
		rocketpoints=FindJoints("rocketpoint")
		hardpoints=FindJoints("hardpoint")
		dumbbombs=FindShapes("dumbbomb")
		rockets=FindShapes("rocket")
		jetjoints=FindJoints("jettinson")
		
		launcherpoints=FindLights("launcher")
		barragepoints=FindLights("barrage")
		
		shared.missiles=FindBodies("missile")
		missilepoints=FindJoints("missile_point")
	
		currentBombIndex = 1
		currentHardpointIndex = 1
		currentRocketIndex = 1
		currentMissileIndex = 1
		
		
		shared.radar_on=false
		radar_cooldown=0.5
	
	
	
		veltimer=0
	velspeed=.33
	
	
	life = 5.0
	
	
	--parts
	
	props = FindJoints("prop")
	aux_props = FindJoints("aux_prop")
	shared.engines = FindShapes("engine")
	
	WingL1=FindShape("L1")
	WingL2=FindShape("L2")
	
	WingR1=FindShape("R1")
	WingR2=FindShape("R2")

	Rudder=FindShape(rudder)
	Elevator=FindShape(elevator)
	
	Tail=FindShape(tail)
	shared.reticle=FindShape(shared.reticle)

	GearPartRetracteds=FindShapes(gear_closed)
	GearPartExtendeds=FindShapes(gear_open)

	rotor = FindBody("rotor")
	
	wheels=FindEntities("", false, "wheel")
	dish=FindJoint("dish")
	
	    -- Find all shapes labeled as "part" or "parts"
    local parts = FindShapes("part")
	
	local gears = FindShapes("gears")


    -- Store the initial voxel count of each part in the table
    for _, part in ipairs(parts) do
        initialVoxelCounts[part] = GetShapeVoxelCount(part)
    end
	
	
	
		--landing gear
		
		
		if HasTag(fuselage, "start_retracted") then
		gear_out=false		
		gear_in=true
		else
		gear_out=true		
		gear_in=false
		end
		
		gear_cooldown=0
	
	
	
	
	tail_prop = FindBody("tail_prop")
	tail_prop_joint = FindJoint("tail_prop_joint")
	
	fueltank = FindBody("tank")

tank1 = FindBody("tank1")
tank2 = FindBody("tank2")
	
	broken=false
	shared.activated=false
	shared.throttle = 0
	doorstate=0
	brakestate=0
	rotor = FindBody("rotor")
	
	--lights
	
	--Position_lights=FindLights(poslight)
	--Landing_lights=FindLights(landinglight)
	
	
	--sound


	
	engine_break_sound = LoadSound("MOD/Dynamic-Aircraft/Snd/aircraft-sfx/engine_break.ogg")
	
	small_explosion = LoadSound("MOD/Dynamic-Aircraft/Snd/aircraft-sfx/small_explosion.ogg")
	medium_explosion = LoadSound("MOD/Dynamic-Aircraft/Snd/aircraft-sfx/medium_explosion.ogg")
	big_explosion = LoadSound("MOD/Dynamic-Aircraft/Snd/aircraft-sfx/crash_explosion.ogg")
	splash = LoadSound("MOD/Dynamic-Aircraft/Snd/aircraft-sfx/splash.ogg")
	
	stresssound = LoadLoop("MOD/Dynamic-Aircraft/Snd/aircraft-sfx/stress.ogg")
	firesound = LoadLoop("MOD/Dynamic-Aircraft/Snd/aircraft-sfx/fireloop.ogg")
	
	dead=false
	detonated=false
	
	joint_structurals=FindJoints("structural1")	
	joint_crits=FindJoints("crit")

	
	coupler=FindShape("coupler")



brake_force=tonumber(GetTagValue(fuselage, "brake")) or 0


--leave as it is








rotor_init=GetBodyMass(rotor)

v_old = 1
shared.manned=false


shared.activated=false
shared.manned=false
initial=true
initialgear=true
shared.cooldown=0
gearcooldown=0

shared.missile_mode=false
missile_cooldown=0
alarm_cooldown=0



lightcooldown=0
lightstate=0
warninglightson=false

instruments=FindLights("instruments")
lights=FindLights("light")
landinglights=FindLights("landing")
warninglights=FindLights("warning")
emergencylights=FindLights("emergency")
beacons=FindLights("beacon")
strobes=FindLights("strobe")

warning=false

damage_light=false
shared.damage_medium=false
damage_total=false
wreck=false
kill=false
burntime=90
burning=false
wet=false

--lights_step_1=false
--lights_step_2=false

motorjoints=FindJoints("motorjoint")

brakejoints=FindJoints("brakejoint")

sweptjoints=FindJoints("swept")

LeftTipLoss=false
lt=0
LeftWingLoss=false
lw=0
RightTipLoss=false
rt=0
RightWingLoss=false
rw=0
RudderLoss=false
rud=1
ElevatorLoss=false
elev=1
RAileronLoss=false
ral=1
LAileronLoss=false
lal=1
TailLoss=false
tl=1


--CONTROL SURFACE JOINTS
rudder_joints=FindJoints("rudder_joint")
elevator_joints=FindJoints("elevator_joint")
aileron_R_joint=FindJoint("aileron_R_joint")
aileron_L_joint=FindJoint("aileron_L_joint")





--lift INITIAL

	--wing = FindBody("wing")

	mass_init = GetBodyMass(fuselage)

	--lif coefficient (increase for heavier aircraft)
	coeff=tonumber(GetTagValue(fuselage, "lift")) or 0
	
	
	--velocity for highest lift
	liftcap=tonumber(GetTagValue(fuselage, "lcap")) or 30


camdist=20
ChaseCam=false
exhausts=FindLights("exhaust")


TankRandom=rnd(50,65)

starter=false
smoky_fire=true





---ELIMINATE WING FUCKY-WUCKY
--WingR2
--WingL2

--WingRinitial=GetBodyTransform(GetShapeBody(WingR1))





point_R=FindLight("keeper_R")
wingpoint_R=FindLight("wingpoint_R")

point_L=FindLight("keeper_L")
wingpoint_L=FindLight("wingpoint_L")


WingLengthInitialR=VecLength(VecSub(GetLightTransform(point_R).pos,GetLightTransform(wingpoint_R).pos))
WingLengthInitialL=VecLength(VecSub(GetLightTransform(point_L).pos,GetLightTransform(wingpoint_L).pos))

LeftRipTimer=rnd(2,5)
RightRipTimer=rnd(2,5)

antiforcer=1


---SPIKES FOR EXPLOSIONS

		spike0=Vec(rnd(-40,40),rnd(0,40), rnd(-40,40))
		spike1=Vec(rnd(-40,40),rnd(0,40), rnd(-40,40))
		spike2=Vec(rnd(-40,40),rnd(0,40), rnd(-40,40))
		spike3=Vec(rnd(-40,40),rnd(0,40), rnd(-40,40))
		spike4=Vec(rnd(-40,40),rnd(0,40), rnd(-40,40))
		spike5=Vec(rnd(-40,40),rnd(0,40), rnd(-40,40))
		spike6=Vec(rnd(-40,40),rnd(0,40), rnd(-40,40))
		spike7=Vec(rnd(-40,40),rnd(0,40), rnd(-40,40))
		spike8=Vec(rnd(-40,40),rnd(0,40), rnd(-40,40))
		spike9=Vec(rnd(-40,40),rnd(0,40), rnd(-40,40))


small_tank_dt=1
big_tank_dt=1
part_float=1
watertimer=10


flare_effect=1.5
lightstimer=0


shared.mapcooldown=0


spinout_stopper=false

----BETTER PROJECTILE SECTION


end

function client.init()

local_fuselage=FindBody("fuselage")
    if HasTag(local_fuselage, "propplane") then
        client.enginesound = LoadLoop("MOD/Dynamic-Aircraft/Snd/aircraft-sfx/double_prop_1.ogg")
        client.idlesound   = LoadLoop("MOD/Dynamic-Aircraft/Snd/aircraft-sfx/idle_1.ogg")
    end

    if HasTag(local_fuselage, "jet") then
        client.enginesound = LoadLoop("MOD/Dynamic-Aircraft/Snd/aircraft-sfx/jet_high_rpm.ogg")
        client.idlesound   = LoadLoop("MOD/Dynamic-Aircraft/Snd/aircraft-sfx/jet_idle.ogg")
    end

    if HasTag(local_fuselage, "turboprop") then
        client.enginesound = LoadLoop("MOD/Dynamic-Aircraft/Snd/aircraft-sfx/double_prop_1.ogg")
        client.idlesound   = LoadLoop("MOD/Dynamic-Aircraft/Snd/aircraft-sfx/jet_idle.ogg")
    end

    -- client-only sound handles (DO NOT put in shared)
    client.afterburner = LoadLoop("MOD/Dynamic-Aircraft/Snd/aircraft-sfx/afterburner.ogg")
    client.lock_alarm  = LoadLoop("MOD/Dynamic-Aircraft/Snd/aircraft-sfx/lock_alarm.ogg")
end


function clamp(value, mi, ma)
	if value < mi then value = mi end
	if value > ma then value = ma end
	return value
end

function rnd(mi, ma)
	return math.random()*(ma-mi)+mi
end

function DeleteConnectedCrits(part)


						
    local joints = GetShapeJoints(part)
    if joints then
        for _, joint in ipairs(joints) do
            if HasTag(joint, "crit") then
			

                Delete(joint) -- Delete the critical joint with the tag "crit"
              --  DebugPrint("Critical joint deleted") -- Print a debug message for each deleted critical joint
            end
        end
    end
end


function SecondaryEffects(part_body, effectType)
    -- Apply secondary effects based on the effect type
  -- smoketime=smoketime-dt
		local part_body_trans = GetBodyTransform(part_body) -- Get the transform of the part body
		local part_speed = VecLength(GetBodyVelocity(part_body))
		local part_vec = GetBodyVelocity(part_body)
		local part_mass = GetBodyMass(part_body)
		--DebugWatch("part_speed",part_speed)
		
		
		--if smoketime>0 then
--DebugWatch("smoketime", smoketime)
   if effectType == 1 then

if not HasTag(part_body, "blown") then

				for i=1, 50 do

				ParticleReset()
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleTile(5)
				ParticleType("plain")
				ParticleCollide(0)
				ParticleRadius(1, 2)
				ParticleDrag(0.5)
				ParticleEmissive(2, 0)
				ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
				ParticleGravity(rnd(4,9))
				ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), Vec(rnd(-30,30),rnd(-30,30),rnd(-30,30)), 3)

				ParticleReset()
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleTile(5)
				ParticleType("plain")
				ParticleCollide(0)
				ParticleRadius(1, 2)
				ParticleDrag(0.5)
				ParticleEmissive(1.5, 0)
				
				ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
				ParticleGravity(rnd(4,9))
				
				ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), Vec(rnd(-30,30),rnd(-30,30),rnd(-30,30)), 5)


				ParticleReset()
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleTile(8)
				ParticleType("plain")
				ParticleCollide(0)
				ParticleRadius(2, 2.5)
				ParticleDrag(0.1)
				ParticleEmissive(2, 0)
				ParticleColor(0, 0, 0)
				ParticleGravity(rnd(-10,-20))
				ParticleAlpha(1, 1)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), Vec(rnd(-20,20),rnd(-20,20),rnd(-20,20)), 20)


				ParticleReset()
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleType("plain")
				ParticleCollide(0)
				ParticleRadius(2, 4)
				ParticleDrag(0.5)
				ParticleEmissive(0, 0)
				ParticleColor(.2,.2,.2)
				ParticleGravity(rnd(2,6))
				ParticleAlpha(0.9, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), Vec(rnd(-30,30),rnd(-30,30),rnd(-30,30)), 12)
				
				
				
				
								--spikes
								ParticleReset()
				ParticleTile(5)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRotation(rnd(0.5,1.5), 0.0, "easeout")
					ParticleRadius(rnd(0.0015*450,0.004*450), rnd(0.004*450,0.008*450))
					ParticleDrag(rnd(0.12,0.8))
					ParticleEmissive(0, 0)
					ParticleColor(.25,.22,.2)
					ParticleGravity(rnd(-1,1))
					ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike0, 500*0.015)
								SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike1, 500*0.015)
												SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike2, 500*0.015)
																SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike3, 500*0.015)
																				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike4, 500*0.015)
																								SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike5, 500*0.015)
																												SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike6, 500*0.015)
																																SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike7, 500*0.015)
																																				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike8, 500*0.015)
																																								SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike9, 500*0.015)
				
				
				
				
				
				
				
				
				
				
				
				
				for i=1, 15 do
				            ParticleReset()
			ParticleEmissive(1, 0, "easeout")
			ParticleGravity(rnd(-7,-10))
			ParticleRadius(math.random(6, 10)*.01, 0.0, "smooth") 
			ParticleColor(1,.8,0.6, 1,.2,0) 
			ParticleTile(4)
			ParticleDrag(0.04, 0.2)
			ParticleCollide(0, 1, "easeout")

				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-1,1),rnd(-1,1),rnd(-1,1))), VecAdd(Vec(rnd(-15,15),rnd(-15,15),rnd(-15,15)),Vec(0.1*part_vec[1]*rnd(0,10),0.1*part_vec[2]*rnd(0,10),0.1*part_vec[3]*rnd(0,10))), rnd(5,10))
			end
				
				end

			







small_tank_dt=small_tank_dt+0.3
PlaySound(small_explosion, GetBodyTransform(fuselage).pos, 20)
--Explosion(part_body_trans.pos, 0.1)
--DebugPrint("tagset")
SetTag(part_body, "blown")				
end
			
			if HasTag(part_body, "blown") then
				if part_speed > 2 then
					for i=1, 5 do
				
				if smoky_fire then
				ParticleReset()
				ParticleRotation(rnd(2,3), 0.0, "easeout")
					ParticleType("plain")
					ParticleCollide(0)
					ParticleRadius(0.7, 3)
					ParticleDrag(0.5)
					ParticleEmissive(0, 0)
					ParticleColor(.2,.2,.2)
					ParticleGravity(rnd(2,6))
					ParticleAlpha(0.9, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), Vec(rnd(-4,4),rnd(4,4),rnd(-4,4)), 10)
				end
				
				ParticleReset()
				ParticleTile(5)
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(0.7, 0.9)
					ParticleDrag(rnd(0.1,0.5))
					ParticleEmissive(3, 0)
					ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
					ParticleGravity(rnd(4,9))
					ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), Vec(rnd(-4+fus_vec[1],4+fus_vec[1]),rnd(4+fus_vec[2],4+fus_vec[2]),rnd(-4+fus_vec[3],4+fus_vec[3])), 0.2)
				
				ParticleReset()
				ParticleTile(8)
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(1.2, 1.3)
					ParticleDrag(1)
					ParticleEmissive(2, 0)
					ParticleColor(0.9,.6,.3)
					ParticleGravity(rnd(3,6))
					ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), Vec(rnd(-4,4),rnd(4,4),rnd(-4,4)), 0.3)
				
				ParticleReset()
				ParticleType("plain")
				ParticleCollide(0)
				ParticleTile(5)
				ParticleRotation(rnd(2,3), 0.0, "easeout")
					ParticleRadius(0.8, 1.2)
					ParticleDrag(0.5)
					ParticleEmissive(2, 0)
					ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
					ParticleGravity(rnd(4,9))
					ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), Vec(rnd(-4,4),rnd(4,4),rnd(-4,4)), 0.5)
				--Paint(part_body_trans.pos, 2, "explosion", 0.001)
				PointLight(part_body_trans.pos, 255, .20, .0130, 5)
				SpawnFire(VecAdd(VecScale(VecNormalize(Vec(math.random()-0.5, math.random()-0.5, math.random()-0.5)), math.random()*4), part_body_trans.pos))
				PlayLoop(firesound, part_body_trans.pos, 5)
			
			end
		
		else
		
					for i=1, 1 do
					if smoky_fire then
					ParticleReset()
					ParticleType("smoke")
					ParticleCollide(0)
					ParticleRadius(0.7)
					ParticleDrag(0.5)
					ParticleEmissive(0, 0)
					ParticleColor(.2,.2,.2)
					ParticleGravity(rnd(2,6))
					ParticleAlpha(0.6, 0.9)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))), Vec(rnd(-2,2),rnd(0,1),rnd(-2,2)), 4)
				end
									ParticleReset()
					ParticleType("plain")
					ParticleCollide(0)
					ParticleRadius(0.7, 5)
					ParticleDrag(rnd(0.2,0.4))
					ParticleEmissive(0, 0)
					ParticleColor(.2,.2,.2)
					ParticleGravity(rnd(4,9))
					ParticleAlpha(0.4, 0.1)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.1,0.1),rnd(-0.1,0.1),rnd(-0.1,0.1))), Vec(rnd(-2,2),rnd(0,1),rnd(-2,2)), rnd(12,18))
				
				ParticleReset()
				ParticleTile(5)
				ParticleType("smoke")
				ParticleCollide(0)
					ParticleRadius(0.5, 0.8)
					ParticleDrag(0.5)					
					ParticleEmissive(2, 0)
					ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
					ParticleGravity(rnd(4,9))
					ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))), Vec(rnd(-2,2),rnd(0,1),rnd(-2,2)), 1)
				
				ParticleReset()
				ParticleTile(8)
				ParticleType("smoke")
				ParticleCollide(0)
					ParticleRadius(0.7, 0.9)
					ParticleDrag(1)
					ParticleEmissive(2, 0)
					ParticleColor(0.9,.6,.3)
					ParticleGravity(rnd(3,6))
					ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))), Vec(rnd(-1,1),rnd(0,0.5),rnd(-1,1)), 2)
				
				ParticleReset()
				ParticleType("smoke")
				ParticleCollide(0)
				ParticleTile(5)
					ParticleRadius(0.5, 0.8)
					ParticleDrag(0.5)
					ParticleEmissive(3, 0)
					ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
					ParticleGravity(rnd(4,9))
					ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))), Vec(rnd(-2,2),rnd(0,1),rnd(-2,2)), 0.8)
				--Paint(part_body_trans.pos, 2, "explosion", 0.001)
				PointLight(part_body_trans.pos, 255, .20, .0130, 5)
				SpawnFire(VecAdd(VecScale(VecNormalize(Vec(math.random()-0.5, math.random()-0.5, math.random()-0.5)), math.random()*4), part_body_trans.pos))
				PlayLoop(firesound, part_body_trans.pos, 5)
			end		
		end
end
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		

    elseif effectType == 2 then
        --t_medium
		if not HasTag(part_body, "blown") then
		
						for i=1, 50 do
				
				
				
				--mushroom flame
							ParticleReset()
				ParticleTile(5)
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleType("plain")
				ParticleCollide(0)
				ParticleRadius(2, 3)
				ParticleDrag(0.2)
				ParticleEmissive(3, 0)
				ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
				ParticleGravity(rnd(2,3))
				ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), Vec(rnd(-2,2),rnd(0,20),rnd(-2,2)), 7)

				ParticleReset()
				ParticleTile(5)
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleType("plain")
				ParticleCollide(0)
				ParticleRadius(1, 2)
				ParticleDrag(0.2)
				ParticleEmissive(2, 0)
				ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
				ParticleGravity(rnd(2,3))
				ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), Vec(rnd(-3,3),rnd(0,25),rnd(-3,3)), 6)

				ParticleReset()
				ParticleTile(5)
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleType("plain")
				ParticleCollide(0)
				ParticleRadius(2, 3)
				ParticleDrag(0.2)
				ParticleEmissive(3, 0)
				ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
				ParticleGravity(rnd(0,1))
				ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), Vec(rnd(-10,10),rnd(-10,10),rnd(-10,10)), 5)

				ParticleReset()
				ParticleTile(5)
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleType("plain")
				ParticleCollide(0)
				ParticleRadius(2, 3)
				ParticleDrag(0.2)
				ParticleEmissive(3, 0)
				ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
				ParticleGravity(rnd(0,1))
				ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), Vec(rnd(-10,10),rnd(-10,10),rnd(-10,10)), 5)

				ParticleReset()
				ParticleTile(5)
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleType("plain")
				ParticleCollide(0)
				ParticleRadius(2, 3)
				ParticleDrag(0.2)
				ParticleEmissive(2, 0)
				ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
				ParticleGravity(rnd(0,1))
				ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), Vec(rnd(-10,10),rnd(-10,10),rnd(-10,10)), 7)

				ParticleReset()
				ParticleTile(5)
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleType("plain")
				ParticleCollide(0)
				ParticleRadius(2, 3)
				ParticleDrag(0.1)
				ParticleEmissive(3, 0)
				ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
				ParticleGravity(rnd(0,1))
				ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), Vec(rnd(-10,10),rnd(-10,10),rnd(-10,10)), 7)


				ParticleReset()
				ParticleTile(8)
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleType("plain")
				ParticleCollide(0)
				ParticleRadius(3, 4)
				ParticleDrag(0.1)
				ParticleEmissive(0, 0)
				ParticleColor(0, 0, 0)
				ParticleGravity(rnd(-10,-20))
				ParticleAlpha(1, 1)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), Vec(rnd(-20,20),rnd(-20,20),rnd(-20,20)), 20)

				ParticleReset()
				ParticleTile(8)
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleType("plain")
				ParticleCollide(0)
				ParticleRadius(3, 4)
				ParticleDrag(0.1)
				ParticleEmissive(0, 0)
				ParticleColor(0, 0, 0)
				ParticleGravity(rnd(-10,-20))
				ParticleAlpha(1, 1)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), Vec(rnd(-20,20),rnd(-20,20),rnd(-20,20)), 20)


				ParticleReset()
				ParticleType("plain")
				ParticleCollide(0)
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleRadius(2, 4)
				ParticleDrag(0.3)
				ParticleEmissive(0, 0)
				ParticleColor(.2,.2,.2)
				ParticleGravity(rnd(0,1))
				ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), Vec(rnd(-50,50),rnd(-10,10),rnd(-50,50)), 12)
				
				
				
												--spikes
								ParticleReset()
				ParticleTile(5)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRotation(rnd(0.5,1.5), 0.0, "easeout")
					ParticleRadius(rnd(0.0015*450,0.004*500), rnd(0.004*450,0.008*500))
					ParticleDrag(rnd(0.1,0.8))
					ParticleEmissive(0, 0)
					ParticleColor(.25,.22,.2)
					ParticleGravity(rnd(-1,1))
					ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike0, 500*0.025)
								SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike1, 500*0.025)
												SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike2, 500*0.025)
																SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike3, 500*0.025)
																				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike4, 500*0.025)
																								SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike5, 500*0.025)
																												SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike6, 500*0.025)
																																SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike7, 500*0.025)
																																				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike8, 500*0.025)
																																								SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike9, 500*0.025)
				
				
				
				
				
				
				
				
				

				for i=1, 20 do
				            ParticleReset()
			ParticleEmissive(1, 0, "easeout")
			ParticleGravity(rnd(-7,-10))
			ParticleRadius(math.random(6, 10)*.01, 0.0, "smooth") 
			ParticleColor(1,.8,0.6, 1,.2,0) 
			ParticleTile(4)
			ParticleDrag(0.04, 0.2)
			ParticleCollide(0, 1, "easeout")

				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-1,1),rnd(-1,1),rnd(-1,1))), VecAdd(Vec(rnd(-20,20),rnd(-20,20),rnd(-20,20)),Vec(0.1*part_vec[1]*rnd(0,10),0.1*part_vec[2]*rnd(0,10),0.1*part_vec[3]*rnd(0,10))), rnd(5,10))
			end
				end
		
big_tank_dt=big_tank_dt+1
PlaySound(medium_explosion, GetBodyTransform(fuselage).pos, 20)

--Explosion(part_body_trans.pos, 0.1)
--DebugPrint("tagset")
SetTag(part_body, "blown")				
end
		
							if HasTag(part_body, "blown") then
				if part_speed > 2 then
					for i=1, 5 do
					ParticleReset()
					ParticleType("plain")
					ParticleRotation(rnd(2,3), 0.0, "easeout")
					ParticleCollide(0)
					ParticleRadius(1, 4)
					ParticleDrag(0.5)
					ParticleEmissive(0, 0)
					ParticleColor(.2,.2,.2)
					ParticleGravity(rnd(2,6))
					ParticleAlpha(0.9, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-1,1),rnd(-1,1),rnd(-1,1))), Vec(rnd(-8,8),rnd(8,8),rnd(-8,8)), 10)
				
				ParticleReset()
				ParticleTile(5)
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(1.3, 1.5)
					ParticleDrag(rnd(0.1,0.5))
					ParticleEmissive(1.5, 0)
					ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
					ParticleGravity(rnd(4,9))
					ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-1,1),rnd(-1,1),rnd(-1,1))), Vec(rnd(-8+fus_vec[1],8+fus_vec[1]),rnd(8+fus_vec[2],8+fus_vec[2]),rnd(-8+fus_vec[3],8+fus_vec[3])), 2)
				
				ParticleReset()
				ParticleTile(8)
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(1.3, 1.5)
					ParticleDrag(1)
					ParticleEmissive(2, 0)
					ParticleColor(0.9,.6,.3)
					ParticleGravity(rnd(3,6))
					ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-1,1),rnd(-1,1),rnd(-1,1))), Vec(rnd(-8,8),rnd(8,8),rnd(-8,8)), 2)
				
				ParticleReset()
				ParticleType("plain")
				ParticleCollide(0)
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleTile(5)
					ParticleRadius(1.3, 1.5)
					ParticleDrag(0.5)
					ParticleEmissive(2, 0)
					ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
					ParticleGravity(rnd(4,9))
					ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-1,1),rnd(-1,1),rnd(-1,1))), Vec(rnd(-8,8),rnd(8,8),rnd(-8,8)), 1)
				--Paint(part_body_trans.pos, 4, "explosion", 0.001)
				PointLight(part_body_trans.pos, 255, .20, .0130, 10)
				SpawnFire(VecAdd(VecScale(VecNormalize(Vec(math.random()-0.5, math.random()-0.5, math.random()-0.5)), math.random()*4), part_body_trans.pos))
				PlayLoop(firesound, part_body_trans.pos, 10)
			
			end
		
		else
		
					for i=1, 1 do
					ParticleReset()
					ParticleType("smoke")
					ParticleCollide(0)
					ParticleRadius(0.7)
					ParticleDrag(0.3)
					ParticleEmissive(0, 0)
					ParticleColor(.2,.2,.2)
					ParticleGravity(rnd(2,6))
					ParticleAlpha(0.6, 0.9)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-4,4),rnd(-0.3,0.3),rnd(-4,4))), Vec(rnd(-6,6),rnd(0,2),rnd(-6,6)), 8)
				
													ParticleReset()
					ParticleType("plain")
					ParticleCollide(0)
					ParticleRadius(1.2, 8)
					ParticleDrag(rnd(0.2,0.4))
					ParticleEmissive(0, 0)
					ParticleColor(.2,.2,.2)
					ParticleGravity(rnd(4,9))
					ParticleAlpha(0.3, 0.05)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.1,0.1),rnd(-0.1,0.1),rnd(-0.1,0.1))), Vec(rnd(-2,2),rnd(0,1),rnd(-2,2)), rnd(15,20))
				
				ParticleReset()
				ParticleTile(5)
				ParticleType("smoke")
				ParticleCollide(0)
					ParticleRadius(0.5, 0.8)
					ParticleDrag(0.5)
					ParticleEmissive(2, 0)
					ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
					ParticleGravity(rnd(4,9))
					ParticleAlpha(1, 0.5)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-4,4),rnd(-0.3,0.3),rnd(-4,4))), Vec(rnd(-6,6),rnd(0,2),rnd(-6,6)), 1.5)
				
				ParticleReset()
				ParticleTile(8)
				ParticleType("smoke")
				ParticleCollide(0)
					ParticleRadius(0.7, 0.9)
					ParticleDrag(1)
					ParticleEmissive(2, 0)
					ParticleColor(0.9,.6,.3)
					ParticleGravity(rnd(3,6))
					ParticleAlpha(1, 0.5)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-4,4),rnd(-0.3,0.3),rnd(-4,4))), Vec(rnd(-3,3),rnd(0,1),rnd(-2,2)), 3)
				
				ParticleReset()
				ParticleType("smoke")
				ParticleCollide(0)
				ParticleTile(5)
					ParticleRadius(0.5, 0.8)
					ParticleDrag(0.5)
					ParticleEmissive(3, 0)
					ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
					ParticleGravity(rnd(4,9))
					ParticleAlpha(1, 0.5)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-4,4),rnd(-0.3,0.3),rnd(-4,4))), Vec(rnd(-6,6),rnd(0,2),rnd(-6,6)), 1.2)
				--Paint(part_body_trans.pos, 4, "explosion", 0.001)
				PointLight(part_body_trans.pos, 255, .20, .0130, 10)
				SpawnFire(VecAdd(VecScale(VecNormalize(Vec(math.random()-0.5, math.random()-0.5, math.random()-0.5)), math.random()*4), part_body_trans.pos))
				PlayLoop(firesound, part_body_trans.pos, 10)
			end		
		end
end
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
       








--	   Explosion(part_body_trans.pos, 2)
    elseif effectType == 3 then
	
        --fueled_large
        Explosion(part_body_trans.pos, 4)
	elseif effectType == 4 then
		--propeller
		Explosion(part_body_trans.pos, 0.2)
		
	elseif effectType == 5 then
		--turbine
		--Explosion(part_body_trans.pos, 4)
		
	elseif effectType == 6 then
		--fuel leak
			for i=1, 1 do
					ParticleReset()
					ParticleType("plain")
					--ParticleTile(1)
					ParticleCollide(0)
					ParticleRadius(0.2, 0.7)
					ParticleDrag(0.3)
					ParticleEmissive(0, 0)
					ParticleColor(0.9,1,1)
					ParticleGravity(rnd(-7, -15))
					ParticleAlpha(0.4, 0)
								SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.1,0.1),rnd(-0.1,0.1),rnd(-0.1,0.1))),VecAdd(TransformToParentVec(part_body_trans, Vec(rnd(-0.1,0.1),rnd(-0.1,0.1),rnd(-0.1,0.1))), GetBodyVelocity(fuselage)), 4)
			end
		--UPGRADE FUEL LEAK LOGIC
		
	elseif effectType == 7 then
		--cooler vapour leak
		
			--if shared.speed_vec > 2 then
			for i=1, 1 do
					ParticleReset()
					ParticleType("plain")
					ParticleCollide(0)
					ParticleRadius(0.45, 0.6)
					ParticleDrag(0.5)
					ParticleEmissive(0, 0)
					ParticleColor(.9,.9,.9)
					ParticleGravity(rnd(4, 9))
					ParticleAlpha(0.2, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))), Vec(rnd(-2,2),rnd(0,1),rnd(-2,2)), 5)
			end
			
		--end
		
	elseif effectType == 8 then
		--engine-damage
		
		
								 		for i=1,#exhausts do 
					local exhaust = exhausts[i]
					exhaustt = GetLightTransform(exhaust)	
					
					if VecLength(VecSub(exhaustt.pos,part_body_trans.pos))<1.5 then
					
					local ashrandom=rnd(0,10)
					Paint(VecAdd(Vec(rnd(-0.1,0.1),rnd(-0.1,0.1),rnd(-0.1,0.1)),VecAdd(exhaustt.pos,VecScale(GetBodyVelocity(fuselage),-ashrandom*0.005))),(10-ashrandom)*0.03,"explosion",0.007)
					end
					end
		
		
		
		
		
		
		if part_speed > 2 then
							for i=1, 1 do	
							ParticleReset()
							ParticleTile(0)
							ParticleRotation(rnd(2,3), 0.0, "easeout")
							ParticleType("plain")
							ParticleCollide(0)
							ParticleRadius(0.8, 1.2)
							ParticleDrag(0.5)
							ParticleEmissive(0.1, 0)
							ParticleColor(.2,.2,.2)
							ParticleGravity(rnd(4,9))
							ParticleAlpha(0.5, 0)
							SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))), Vec(rnd(-2,2),rnd(0,1),rnd(-2,2)), 6)
							end
		else
							for i=1, 1 do
							ParticleReset()
							ParticleTile(0)
							ParticleType("smoke")
							ParticleCollide(0)
							ParticleRadius(0.3, 0.4)
							ParticleDrag(0.5)
							ParticleEmissive(0.1, 0)
							ParticleColor(.2,.2,.2)
							ParticleGravity(rnd(4,9))
							ParticleAlpha(0.9, 0)
							SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))), Vec(rnd(-2,2),rnd(0,1),rnd(-2,2)), 6)
							end

		end

		
	elseif effectType == 9 and HasTag(part_body,"ex_done")==false then
		--engine-broken		
		if HasTag(part_body,"preignited")==false then
		ignition_timer=0
		if shared.activated then
		if HasTag(fuselage,"jet") then
								FailSnd = LoadSound(JetSndTable[math.random(1, 2)])
						PlaySound(FailSnd,GetBodyTransform(part_body).pos, 3)
						else
														FailSnd = LoadSound(PropSndTable[math.random(1, 7)])
						PlaySound(FailSnd,GetBodyTransform(part_body).pos, 5)			
		end
		end
		SetTag(part_body,"preignited")
		end
		
		if HasTag(part_body,"ignited")==false then	
		--IGNITION ANIMATION
		if ignition_timer>7.5 then
		SetTag(part_body,"ignited")
		ignition_timer=0
		end
		ignition_regulator=ignition_timer*0.13
		if ignition_timer<1 then
		shorter_ignition_timer=ignition_timer
		else
		shorter_ignition_timer=1
		end
		---exhausts fire
						 		for i=1,#exhausts do 
					local exhaust = exhausts[i]
					exhaustt = GetLightTransform(exhaust)					
					exhaust_random=rnd(0,100)
						if VecLength(VecSub(exhaustt.pos,part_body_trans.pos))<3 then
											ParticleReset()
					ParticleType("plain")
					ParticleRotation(rnd(2,3), 0.0, "easeout")
					ParticleCollide(0)
					ParticleRadius(0.3*shorter_ignition_timer)
					ParticleDrag(0.5)
					ParticleEmissive(0, 0)
					ParticleColor(.2,.2,.2)
					ParticleGravity(rnd(2,6))
					ParticleAlpha(0.2, 0)
				SpawnParticle(VecAdd(exhaustt.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))), Vec(rnd(-2,2),rnd(0,1),rnd(-2,2)), 5)
										ParticleReset()
				ParticleType("plain")
				ParticleTile(5)
				ParticleStretch(0,50)
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleCollide(0)
					ParticleRadius(0.3*shorter_ignition_timer)
					ParticleDrag(0.09)
					ParticleEmissive(3, 3)
					ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
					ParticleGravity(0)
					ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(exhaustt.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))),GetBodyVelocity(part_body), 0.4)
						end
					end
		engine_spark_random=rnd(0,200)	

if engine_spark_random>175 and HasTag(fuselage, "jet") and shared.activated then


									for i=1, 10 do	
							ParticleReset()
							ParticleTile(5)
							ParticleType("plain")
							ParticleCollide(0)
							ParticleRadius(0.7, 0)
							ParticleDrag(0.09)
							ParticleEmissive(3, 3)
							ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
							ParticleGravity(rnd(0,0))
							ParticleAlpha(0.9, 0)
							SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))), TransformToParentVec(part_body_trans, Vec(0,0,-70)), 0.24)
							PointLight(part_body_trans.pos, 255, .20, .0130, 2)
							end


end






		
			if part_speed > 2 then
			if HasTag(fuselage, "propplane") then
														ParticleReset()
					ParticleType("plain")
					ParticleRotation(rnd(2,3), 0.0, "easeout")
					ParticleCollide(0)
					ParticleRadius(0.3*shorter_ignition_timer)
					ParticleDrag(0.5)
					ParticleEmissive(0, 0)
					ParticleColor(.2,.2,.2)
					ParticleGravity(rnd(2,6))
					ParticleAlpha(0.2, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))), Vec(rnd(-2,2),rnd(0,1),rnd(-2,2)), 5)
			end
					for i=1, 3 do
					
					if smoky_fire then
					ParticleReset()
					ParticleType("plain")
					ParticleRotation(rnd(2,3), 0.0, "easeout")
					ParticleCollide(0)
					ParticleRadius(0.7*ignition_regulator)
					ParticleDrag(0.5)
					ParticleEmissive(0, 0)
					ParticleColor(.2,.2,.2)
					ParticleGravity(rnd(2,6))
					ParticleAlpha(0.5, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))), Vec(rnd(-2,2),rnd(0,1),rnd(-2,2)), 12)
				
				ParticleReset()
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleTile(5)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(0.9*ignition_regulator)
					ParticleDrag(0.09)
					ParticleEmissive(2, 2)
					ParticleStretch(0,50)
					ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
					ParticleGravity(0)
					ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))),GetBodyVelocity(part_body), 0.8)
				
				ParticleReset()
				ParticleTile(8)
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleType("plain")
				ParticleCollide(0)
				ParticleStretch(0,50)
					ParticleRadius(0.8*ignition_regulator, 0.9*ignition_regulator)
					ParticleDrag(0.09)
					ParticleEmissive(2, 2)
					ParticleColor(0.9,.6,.3)
					ParticleGravity(0)
					ParticleAlpha(1, 0.5)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))),GetBodyVelocity(part_body), 1)
				
				ParticleReset()
				ParticleType("plain")
				ParticleTile(5)
				ParticleStretch(0,50)
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleCollide(0)
					ParticleRadius(0.85*ignition_regulator)
					ParticleDrag(0.09)
					ParticleEmissive(3, 3)
					ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
					ParticleGravity(0)
					ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))),GetBodyVelocity(part_body), 0.4)
				else
						fire_rand=rnd(0,10)
						if fire_rand>7 then
							
							for i=1, 3 do
								ParticleReset()
					ParticleType("plain")
					ParticleRotation(rnd(2,3), 0.0, "easeout")
					ParticleCollide(0)
					ParticleRadius(0.7*ignition_regulator)
					ParticleDrag(0.5)
					ParticleEmissive(0, 0)
					ParticleColor(.2,.2,.2)
					ParticleGravity(rnd(2,6))
					ParticleAlpha(0.1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))), Vec(rnd(-2,2),rnd(0,1),rnd(-2,2)), 12)
								ParticleReset()
				ParticleTile(5)
				ParticleType("plain")
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleCollide(0)
					ParticleRadius(1.1*ignition_regulator)
					ParticleDrag(0.09)
					ParticleStretch(0,50)
					ParticleEmissive(2, 2)
					ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
					ParticleGravity(0)
					ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))),GetBodyVelocity(part_body), 0.8)
				
				ParticleReset()
				ParticleTile(8)
				ParticleType("plain")
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleCollide(0)
					ParticleRadius(1.1*ignition_regulator, 1.2*ignition_regulator)
					ParticleDrag(0.09)
					ParticleStretch(0,50)
					ParticleEmissive(2, 2)
					ParticleColor(0.9,.6,.3)
					ParticleGravity(0)
					ParticleAlpha(1, 0.5)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))),GetBodyVelocity(part_body), 1)
				
				ParticleReset()
				ParticleType("plain")
				ParticleCollide(0)
				ParticleTile(5)
				ParticleStretch(0,50)
				ParticleRotation(rnd(2,3), 0.0, "easeout")
					ParticleRadius(1*ignition_regulator)
					ParticleDrag(0.09)
					ParticleEmissive(3, 3)
					ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
					ParticleGravity(0)
					ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))),GetBodyVelocity(part_body), 0.4)
				end
				end
				end
				
				Paint(part_body_trans.pos, 2, "explosion", 0.001*ignition_regulator)
				PointLight(part_body_trans.pos, 255*ignition_regulator, .20, .0130, 5)
				SpawnFire(VecAdd(VecScale(VecNormalize(Vec(math.random(0, 0.5), math.random(0, 0.5), math.random(0, 0.5))), math.random(0, 0.5)*4), part_body_trans.pos))
				PlayLoop(firesound, part_body_trans.pos, 5)
			
			end
		
		else
		
					for i=1, 1 do
					ParticleReset()
					ParticleType("smoke")
					ParticleCollide(0)
					ParticleRadius(0.7*ignition_regulator)
					ParticleDrag(0.5)
					ParticleEmissive(0, 0)
					ParticleColor(.2,.2,.2)
					ParticleGravity(rnd(2,6))
					ParticleAlpha(0.3, 0.3)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))), Vec(rnd(-2,2),rnd(0,1),rnd(-2,2)), 4)
				
				ParticleReset()
				ParticleTile(5)
				ParticleType("smoke")
				ParticleCollide(0)
					ParticleRadius(0.3*ignition_regulator, 0.6*ignition_regulator)
					ParticleDrag(0.5)
					ParticleEmissive(2, 2)
					ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
					ParticleGravity(rnd(4,9))
					ParticleAlpha(1, 0.5)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))), Vec(rnd(-2,2),rnd(0,1),rnd(-2,2)), 1)
				
				ParticleReset()
				ParticleTile(8)
				ParticleType("smoke")
				ParticleCollide(0)
					ParticleRadius(0.5*ignition_regulator, 0.8*ignition_regulator)
					ParticleDrag(1)
					ParticleEmissive(2, 2)
					ParticleColor(0.9,.6,.3)
					ParticleGravity(rnd(3,6))
					ParticleAlpha(1, 0.5)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))), Vec(rnd(-1,1),rnd(0,0.5),rnd(-1,1)), 2)
				
				ParticleReset()
				ParticleType("smoke")
				ParticleCollide(0)
				ParticleTile(5)
					ParticleRadius(0.3*ignition_regulator, 0.6*ignition_regulator)
					ParticleDrag(0.5)
					ParticleEmissive(3, 3)
					ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
					ParticleGravity(rnd(4,9))
					ParticleAlpha(1, 0.5)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))), Vec(rnd(-2,2),rnd(0,1),rnd(-2,2)), 0.8)
				Paint(part_body_trans.pos, 2, "explosion", 0.001)
				PointLight(part_body_trans.pos, 255, .20, .0130, 5)
				SpawnFire(VecAdd(VecScale(VecNormalize(Vec(math.random(0, 0.5), math.random(0, 0.5), math.random(0, 0.5))), math.random(0, 0.5)*4), part_body_trans.pos))
				PlayLoop(firesound, part_body_trans.pos, 5)
			end		
		end
	else
	
							 		for i=1,#exhausts do 
					local exhaust = exhausts[i]
					exhaustt = GetLightTransform(exhaust)					
					exhaust_random=rnd(0,100)
						if VecLength(VecSub(exhaustt.pos,part_body_trans.pos))<3 then
											ParticleReset()
					ParticleType("plain")
					ParticleRotation(rnd(2,3), 0.0, "easeout")
					ParticleCollide(0)
					ParticleRadius(0.3)
					ParticleDrag(0.5)
					ParticleEmissive(0, 0)
					ParticleColor(.2,.2,.2)
					ParticleGravity(rnd(2,6))
					ParticleAlpha(0.2, 0)
				SpawnParticle(VecAdd(exhaustt.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))), Vec(rnd(-2,2),rnd(0,1),rnd(-2,2)), 5)
										ParticleReset()
				ParticleType("plain")
				ParticleTile(5)
				ParticleStretch(0,50)
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleCollide(0)
					ParticleRadius(0.3)
					ParticleDrag(0.09)
					ParticleEmissive(3, 0)
					ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
					ParticleGravity(0)
					ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(exhaustt.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))),GetBodyVelocity(part_body), 0.4)
						end
					end
	
			if engine_spark_random>199 then
						for i=1, 30 do
				            ParticleReset()
			ParticleEmissive(1, 0, "easeout")
			ParticleGravity(rnd(-7,-10))
			ParticleRadius(math.random(6, 10)*.01, 0.0, "smooth") 
			ParticleColor(1,.8,0.6, 1,.2,0) 
			ParticleTile(4)
			ParticleDrag(0.04, 0.2)
			ParticleCollide(0, 1, "easeout")
			SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-1,1),rnd(-1,1),rnd(-1,1))),Vec(0.1*part_vec[1]*rnd(4,10),0.1*part_vec[2]*rnd(4,10),0.1*part_vec[3]*rnd(4,10)), rnd(5,10))
			
											ParticleReset()
					ParticleType("plain")
					ParticleRotation(rnd(2,3), 0.0, "easeout")
					ParticleCollide(0)
					ParticleRadius(rnd(0,1),rnd(2,3))
					ParticleDrag(rnd(0.3,0.5))
					ParticleEmissive(0, 0)
					ParticleColor(.2,.2,.2)
					ParticleGravity(rnd(1,5))
					ParticleAlpha(0.5, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))), Vec(rnd(-1,1),rnd(0,0.5),rnd(-1,1)), 10)
			end	
		end
		
		
		
		
		
		
			if part_speed > 2 then
					for i=1, 3 do
					
					if smoky_fire then
					ParticleReset()
					ParticleType("plain")
					ParticleRotation(rnd(2,3), 0.0, "easeout")
					ParticleCollide(0)
					ParticleRadius(0.7)
					ParticleDrag(0.5)
					ParticleEmissive(0, 0)
					ParticleColor(.2,.2,.2)
					ParticleGravity(rnd(2,6))
					ParticleAlpha(0.5, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))), Vec(rnd(-2,2),rnd(0,1),rnd(-2,2)), 12)
				
				ParticleReset()
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleTile(5)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(0.9)
					ParticleDrag(0.09)
					ParticleEmissive(2, 0)
					ParticleStretch(0,50)
					ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
					ParticleGravity(0)
					ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))),GetBodyVelocity(part_body), 0.8)
				
				ParticleReset()
				ParticleTile(8)
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleType("plain")
				ParticleCollide(0)
				ParticleStretch(0,50)
					ParticleRadius(0.8, 0.9)
					ParticleDrag(0.09)
					ParticleEmissive(2, 0)
					ParticleColor(0.9,.6,.3)
					ParticleGravity(0)
					ParticleAlpha(1, 0.5)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))),GetBodyVelocity(part_body), 1)
				
				ParticleReset()
				ParticleType("plain")
				ParticleTile(5)
				ParticleStretch(0,50)
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleCollide(0)
					ParticleRadius(0.85)
					ParticleDrag(0.09)
					ParticleEmissive(3, 0)
					ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
					ParticleGravity(0)
					ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))),GetBodyVelocity(part_body), 0.4)
				else
						fire_rand=rnd(0,10)
						if fire_rand>7 then
							
							for i=1, 3 do
								ParticleReset()
					ParticleType("plain")
					ParticleRotation(rnd(2,3), 0.0, "easeout")
					ParticleCollide(0)
					ParticleRadius(0.7)
					ParticleDrag(0.5)
					ParticleEmissive(0, 0)
					ParticleColor(.2,.2,.2)
					ParticleGravity(rnd(2,6))
					ParticleAlpha(0.1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))), Vec(rnd(-2,2),rnd(0,1),rnd(-2,2)), 12)
								ParticleReset()
				ParticleTile(5)
				ParticleType("plain")
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleCollide(0)
					ParticleRadius(1.1)
					ParticleDrag(0.09)
					ParticleStretch(0,50)
					ParticleEmissive(2, 0)
					ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
					ParticleGravity(0)
					ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))),GetBodyVelocity(part_body), 0.8)
				
				ParticleReset()
				ParticleTile(8)
				ParticleType("plain")
				ParticleRotation(rnd(2,3), 0.0, "easeout")
				ParticleCollide(0)
					ParticleRadius(1.1, 1.2)
					ParticleDrag(0.09)
					ParticleStretch(0,50)
					ParticleEmissive(2, 0)
					ParticleColor(0.9,.6,.3)
					ParticleGravity(0)
					ParticleAlpha(1, 0.5)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))),GetBodyVelocity(part_body), 1)
				
				ParticleReset()
				ParticleType("plain")
				ParticleCollide(0)
				ParticleTile(5)
				ParticleStretch(0,50)
				ParticleRotation(rnd(2,3), 0.0, "easeout")
					ParticleRadius(1)
					ParticleDrag(0.09)
					ParticleEmissive(3, 0)
					ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
					ParticleGravity(0)
					ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))),GetBodyVelocity(part_body), 0.4)
				end
				end
				end
				
				Paint(part_body_trans.pos, 2, "explosion", 0.001)
				PointLight(part_body_trans.pos, 255, .20, .0130, 5)
				SpawnFire(VecAdd(VecScale(VecNormalize(Vec(math.random(0, 0.5), math.random(0, 0.5), math.random(0, 0.5))), math.random(0, 0.5)*4), part_body_trans.pos))
				PlayLoop(firesound, part_body_trans.pos, 5)
			
			end
		
		else
		
					for i=1, 1 do
					ParticleReset()
					ParticleType("smoke")
					ParticleCollide(0)
					ParticleRadius(0.7)
					ParticleDrag(0.5)
					ParticleEmissive(0, 0)
					ParticleColor(.2,.2,.2)
					ParticleGravity(rnd(2,6))
					ParticleAlpha(0.3, 0.3)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))), Vec(rnd(-2,2),rnd(0,1),rnd(-2,2)), 4)
				
				ParticleReset()
				ParticleTile(5)
				ParticleType("smoke")
				ParticleCollide(0)
					ParticleRadius(0.3, 0.6)
					ParticleDrag(0.5)
					ParticleEmissive(2, 0)
					ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
					ParticleGravity(rnd(4,9))
					ParticleAlpha(1, 0.5)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))), Vec(rnd(-2,2),rnd(0,1),rnd(-2,2)), 1)
				
				ParticleReset()
				ParticleTile(8)
				ParticleType("smoke")
				ParticleCollide(0)
					ParticleRadius(0.5, 0.8)
					ParticleDrag(1)
					ParticleEmissive(2, 0)
					ParticleColor(0.9,.6,.3)
					ParticleGravity(rnd(3,6))
					ParticleAlpha(1, 0.5)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))), Vec(rnd(-1,1),rnd(0,0.5),rnd(-1,1)), 2)
				
				ParticleReset()
				ParticleType("smoke")
				ParticleCollide(0)
				ParticleTile(5)
					ParticleRadius(0.3, 0.6)
					ParticleDrag(0.5)
					ParticleEmissive(3, 0)
					ParticleColor(rnd(0.9,1),rnd(0.45,0.55),rnd(0.25,0.35))
					ParticleGravity(rnd(4,9))
					ParticleAlpha(1, 0.5)
				SpawnParticle(VecAdd(part_body_trans.pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))), Vec(rnd(-2,2),rnd(0,1),rnd(-2,2)), 0.8)
				Paint(part_body_trans.pos, 2, "explosion", 0.001)
				PointLight(part_body_trans.pos, 255, .20, .0130, 5)
				SpawnFire(VecAdd(VecScale(VecNormalize(Vec(math.random(0, 0.5), math.random(0, 0.5), math.random(0, 0.5))), math.random(0, 0.5)*4), part_body_trans.pos))
				PlayLoop(firesound, part_body_trans.pos, 5)
			end		
		end
	
	
	
	
	
	
	end
	elseif effectType == 10 then
	--WING BROKEN FLIGHT PHYSICS here
	
	BreakForce=part_mass*shared.speed_vec*rnd(0,10)*0.001
	
	if HasTag(Part,"L2") or HasTag(part,"R2") then
ApplyBodyImpulse(part_body, GetBodyTransform(part_body).pos, Vec(0,BreakForce*1*antiforcer,0))
else
ApplyBodyImpulse(part_body, GetBodyTransform(part_body).pos, Vec(0,BreakForce*1,0))
end
    else
       -- DebugPrint("No additional effects for the part") -- No additional tags found, no effect applied
    end
	--end
end


function Part_Damage(part, voxelPercentage)
   -- DebugPrint("part damage") -- Print debug message when the part is damaged
 if voxelPercentage < 99 then
	if shared.speed_vec>35 then
downtimer=0
end
end
    -- Check if the part's voxel percentage is below 75%
    if voxelPercentage < 95 and voxelPercentage > 5 then
	

	
	
        local part_body = GetShapeBody(part) -- Get the body associated with the damaged shape
		local part_body_trans = GetBodyTransform(part_body) -- Get the transform of the part body
		
			if HasTag(part, "propeller") then
			SecondaryEffects(part_body, 4)
			end
			
			if HasTag(part, "turbine") then
			SecondaryEffects(part_body, 5)
			end
			
			
			if voxelPercentage < 95 and voxelPercentage > 65 then
			if HasTag(part, "tank") then
			SecondaryEffects(part_body, 6)
			end
			end
			
			
			if HasTag(part, "vapour") then
			SecondaryEffects(part_body, 7)
			end


				if voxelPercentage < 95 and voxelPercentage > 90 and burntime>0 then
				if HasTag(part, "engine") then
				SecondaryEffects(part_body, 8)
				end
				end



				if voxelPercentage < 90 and burntime>0 then			
				if HasTag(part, "engine") and HasTag(part_body,"ex_done")==false then
				SecondaryEffects(part_body, 9)
				
								if HasTag(part_body, "broken")==false then
				SetTag(part_body, "burning")
				end
				
--extinguisher
if HasTag(part_body, "ex") and HasTag(fuselage,"downed")==false then
	if reaction_timer>5 then
	SetTag(part_body,"ex_done")
	end

else	
				burning=true
end
				
				
				if HasTag(fuselage,"eb") and HasTag(part_body, "broken")==false and HasTag(fuselage,"4e")==false then
				SetTag(fuselage,"downed")
				end
				
				if HasTag(fuselage,"eb") and HasTag(fuselage,"2b") and HasTag(part_body, "broken")==false and HasTag(fuselage,"4e") then
				SetTag(fuselage,"downed")
				end
				
				if HasTag(fuselage,"eb") and HasTag(fuselage,"2b")==false and HasTag(part_body, "broken")==false and HasTag(fuselage,"4e") then
				SetTag(fuselage,"2b")
				end
				

				
				
				if HasTag(fuselage,"me") then
				SetTag(fuselage,"eb")
				else
				SetTag(fuselage,"downed")
				end


							
				SetTag(part_body, "broken")

				
				end

				--LOGIC FOR DOWNED FOR ME


		
				end

		if voxelPercentage < 65 then
        -- Delete connected critical joints with the tag "crit"
        DeleteConnectedCrits(part)
		if not HasTag(part,"sound_played") then
								CrashSnd = LoadSound(CrashSndTable[math.random(1, 12)])
						PlaySound(CrashSnd,GetBodyTransform(part_body).pos, 5)
						SetTag(part,"sound_played")
		end
		--Left Wingtip
		if HasTag(part,"L2") then
		--DebugPrint("YOU HAVE A HOLE IN YOUR LEFT WING!!!")
		SetTag(fuselage,"downed")
		LeftTipLoss=true
		SecondaryEffects(part_body, 10)
		lt=0.5
		end

		--left Wing
		if HasTag(part,"L1") then
		--DebugPrint("YOU DONT HAVE A LEFT WING!!!")
		SetTag(fuselage,"downed")
		SecondaryEffects(part_body, 10)
		LeftWingLossLoss=true
		lw=0.5
		end

		--Right Wingtip
		if HasTag(part,"R2") then
		--DebugPrint("YOU HAVE A HOLE IN YOUR RIGHT WING!!!")
		SetTag(fuselage,"downed")
		SecondaryEffects(part_body, 10)
		LeftTipLoss=true
		rt=0.5
		end

		--Right Wing
		if HasTag(part,"R1") then
	--	DebugPrint("YOU DONT HAVE A RIGHT WING!!!")
		SetTag(fuselage,"downed")
		SecondaryEffects(part_body, 10)
		LeftWingLossLoss=true
		rw=0.5
		end

		if HasTag(part,"vital") then
		SetTag(fuselage, "downed")
		end

		if HasTag(part,"deco") then
		EdgeMin, EdgeMax = GetShapeBounds(part)
		MinX=EdgeMin[1]
		MinY=EdgeMin[2]
		MinZ=EdgeMin[3]
		
		MaxX=EdgeMax[1]
		MaxY=EdgeMax[2]
		MaxZ=EdgeMax[3]
		
		AvX=(MinX+MaxX)/2
		AvY=(MinY+MaxY)/2
		AvZ=(MinZ+MaxZ)/2
		
		AvVec=Vec(AvX,AvY,AvZ)
		--DebugCross(AvVec)
		
		if not HasTag(part,"blown") then
		--particles
		
							for i=1, 20 do				
				--dust
								ParticleReset()
				ParticleTile(5)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(0.5, 1)
					ParticleDrag(rnd(0,0.2))
					ParticleEmissive(0, 0)
					ParticleColor(.5,.5,.5)
					ParticleGravity(rnd(-0.7,0.5))
					ParticleAlpha(0.7, 0)
				SpawnParticle(VecAdd(AvVec, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), Vec(rnd(-0.5+fus_vec[1],0.5+fus_vec[1]),rnd(-0.5+fus_vec[2],0.5+fus_vec[2]),rnd(-0.5+fus_vec[3],0.5+fus_vec[3])), 3)
		
		
										ParticleReset()
				ParticleTile(8)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(1, 2)
					ParticleDrag(rnd(0,0.1))
					ParticleEmissive(0, 0)
					ParticleColor(.3,.3,.3)
					ParticleGravity(rnd(-1,00))
					ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(AvVec, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), Vec(rnd(-0.6+fus_vec[1],0.6+fus_vec[1]),rnd(-0.6+fus_vec[2],0.6+fus_vec[2]),rnd(-0.6+fus_vec[3],0.6+fus_vec[3])), 5)
		
		
				            ParticleReset()
			ParticleEmissive(1, 0, "easein")
			ParticleGravity(rnd(-2,-8))
			ParticleRadius(math.random(6, 10)*.01, 0.0, "smooth") 
			ParticleColor(1,.8,0.6, 1,.2,0) 
			ParticleTile(4)
			ParticleDrag(0, 0.2)
			ParticleCollide(0, 1, "easeout")
				SpawnParticle(VecAdd(AvVec, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), Vec(rnd(-3+fus_vec[1],3+fus_vec[1]),rnd(-3+fus_vec[2],3+fus_vec[2]),rnd(-3+fus_vec[3],3+fus_vec[3])), 5)
				SpawnParticle(VecAdd(AvVec, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), Vec(rnd(-3+fus_vec[1],3+fus_vec[1]),rnd(-3+fus_vec[2],3+fus_vec[2]),rnd(-3+fus_vec[3],3+fus_vec[3])), 5)				
		
		
		end		
			   SetTag(part,"blown")		
		end
		end






		
		if HasTag(part,"rudder") then
		--DebugPrint("rudder lost")
		SetTag(fuselage,"downed")
		end
		

		
		if HasTag(part,"tail") then
		--DebugPrint("tail lost")
		SetTag(fuselage,"downed")
		TailLoss=true
		tl=0.01
		elev=0.01
		rud=0.01
		end
		
		if HasTag(part,"ailR") then
		--DebugPrint("elevator lost")
		RAileronLoss=true
		ral=0.01
		end
		
		if HasTag(part,"ailL") then
		--DebugPrint("elevator lost")
		LAileronLoss=true
		lal=0.01
		end




        -- Get the effect type based on tags (0: none, 1: fueled_small, 2: fueled_medium, 3: fueled_large, 4: turbine)  

	   local effectType = 0
	    if voxelPercentage < TankRandom then
        if HasTag(part, "fueled_small") and burntime>0 then
            effectType = 1
			SetTag(fuselage,"downed")
			burning=true
        elseif HasTag(part, "fueled_medium") and burntime>0 then
            effectType = 2
			SetTag(fuselage,"downed")
			burning=true
        elseif HasTag(part, "fueled_large") and burntime>0 then
            effectType = 3
			SetTag(fuselage,"downed")
			burning=true
end

        -- Add more effect types here if needed
        -- elseif HasTag(part, "custom_effect") then
        --     effectType = 5
        end

        -- Trigger an explosion at the body's position with size '1'
        --Explosion(part_body_trans.pos, 1)

       -- DebugPrint("Part exploded") -- Print a debug message when the part explodes

        -- Apply secondary effects based on the effect type
        SecondaryEffects(part_body, effectType)

        -- Don't delete the part_body here (keeping the body in the scene)
    else
       -- DebugPrint("Part health: " .. voxelPercentage .. "%") -- Print the current health of the part
    end
	end
end

function makeRotLocal(vec_in)		
				transformoriginal = TransformToParentPoint(shared.FuselageTrans, vec_in)
				suboriginal = VecSub(transformoriginal, shared.FuselageTrans.pos)
				tthing = VecNormalize(suboriginal)
				vecfinal = VecScale(tthing, 1.73)		
	return vecfinal
end

function UiGlowText(text, font, size, glowColor, textColor, offset)
    UiPush()
        UiFont(font, size)
        local offset = offset or 1

        -- GREENISH TOP LAYER (chromatic aberration)
        UiPush()
            UiColor(0.5, 1.0, 0.7, 0.5)  -- soft green tint
            UiTranslate(0, -offset)
            UiText(text)
        UiPop()

        -- PURPLE BOTTOM LAYER (chromatic aberration)
        UiPush()
            UiColor(0.8, 0.6, 1.0, 0.5)  -- soft magenta tint
            UiTranslate(0, offset)
            UiText(text)
        UiPop()

        -- MAIN TEXT (neutral center)
        UiColor(textColor[1], textColor[2], textColor[3], textColor[4] or 1)
        UiText(text)
    UiPop()
end

-- Draws an outline rectangle with a subtle chromatic aberration effect
function UiRectOutlineAberrated(w, h, color, thickness, offset)
    UiPush()
        local offset = offset or 1

        -- Safe color fallback handling
        local r = (color and color[1]) or 1.0
        local g = (color and color[2]) or 1.0
        local b = (color and color[3]) or 1.0
        local a = (color and color[4]) or 1.0

        -- GREENISH SHIFT (up-left)
        UiPush()
            UiColor(0.5, 1.0, 0.7, 0.5)
            UiTranslate(-offset, -offset)
            UiRectOutline(w, h, thickness)
        UiPop()

        -- MAGENTA SHIFT (down-right)
        UiPush()
            UiColor(0.8, 0.6, 1.0, 0.5)
            UiTranslate(offset, offset)
            UiRectOutline(w, h, thickness)
        UiPop()

        -- MAIN ORANGE OUTLINE
        UiColor(r, g, b, a)
        UiRectOutline(w, h, thickness)
    UiPop()
end

function client.draw()
if client.localPilot==true then
--SetBool("game.vehicle.interactive", false)
---OPTIONS--BLUR

-------GENERAL UI------------
 ---------------------------------
-- COLOR DEFINITIONS
---------------------------------
if HasTag(fuselage,"jet") then
col_main = {0.7, 1.0, 0.7, 1.0}      -- main HUD green
col_glow = {0.6, 1.0, 0.6, 0.35}     -- pale green glow
else
col_main  = {1.0, 0.55, 0.2, 1.0}   -- warm orange (main HUD)
col_glow  = {1.0, 0.6, 0.25, 0.3}   -- soft glow accent
end

local col_alert_red  = {1.0, 0.2, 0.2, 1.0}   -- alert red
local col_alert_blue = {0.2, 0.6, 1.0, 1.0}   -- radar/lock blue
---------------------------------
-- ABERRATED RECT OUTLINE FUNCTION
---------------------------------
---------------------------------
-- GENERAL UI ROOT
---------------------------------
if shared.manned == true then
    SetBool("game.vehicle.interactive", false)


    ---------------------------------
    -- TOP-LEFT FLIGHT DATA PANEL
    ---------------------------------
    UiPush()
        UiAlign("left top")
        UiTranslate(30, 60)
        UiFont("MOD/Dynamic-Aircraft/Fonts/HUD_bold.ttf", 24)

        local throttleDisp = math.floor(shared.throttle * 40 + 0.5)
        local airspeedDisp = math.floor(shared.speed_vec * 11 + 0.5)
        local altitudeDisp = math.floor(shared.FuselageTrans.pos[2] + 0.5)

        local labelCol, valueCol = 0, 120
        local boxWidth, boxHeight = 220, 110
        if airspeedDisp > 800 then boxHeight = 140 end

        -- blurred background
        UiPush()
            UiWindow(boxWidth, boxHeight, true)
                UiBlur(0.2)
            UiWindow()
        UiPop()

        -- aberrated outline
        UiRectOutlineAberrated(boxWidth, boxHeight, col_main, 2, 1)
        UiTranslate(10, 10)

        local fontPath = "MOD/Dynamic-Aircraft/Fonts/HUD_bold.ttf"

        -- THR
        UiPush(); UiTranslate(labelCol, 0)
            UiGlowText("THR", fontPath, 24, col_glow, col_main, 1)
        UiPop()
        UiPush(); UiTranslate(valueCol, 0)
            UiGlowText(string.format("%d%%", throttleDisp), fontPath, 24, col_glow, col_main, 1)
        UiPop()

        -- SPD
        UiTranslate(0, 28)
        UiPush(); UiTranslate(labelCol, 0)
            UiGlowText("SPD", fontPath, 24, col_glow, col_main, 1)
        UiPop()
        UiPush(); UiTranslate(valueCol, 0)
            UiGlowText(string.format("%d", airspeedDisp), fontPath, 24, col_glow, col_main, 1)
        UiPop()

        -- ALT
        UiTranslate(0, 28)
        UiPush(); UiTranslate(labelCol, 0)
            UiGlowText("ALT", fontPath, 24, col_glow, col_main, 1)
        UiPop()
        UiPush(); UiTranslate(valueCol, 0)
            UiGlowText(string.format("%d", altitudeDisp), fontPath, 24, col_glow, col_main, 1)
        UiPop()

        -- MACH (if applicable)
        if airspeedDisp > 800 then
            UiTranslate(0, 28)
            local mach = airspeedDisp / 1250.0
            mach = math.floor(mach * 10 + 0.5) / 10
            UiPush(); UiTranslate(labelCol, 0)
                UiGlowText("MACH", fontPath, 24, col_glow, col_main, 1)
            UiPop()
            UiPush(); UiTranslate(valueCol, 0)
                UiGlowText(string.format("%.1f", mach), fontPath, 24, col_glow, col_main, 1)
            UiPop()
        end
    UiPop()


    ---------------------------------
    -- BOTTOM-RIGHT MISSILE PANEL
    ---------------------------------
    if shared.missile_count and shared.missile_count > 0 then
        UiPush()
            UiAlign("right bottom")
            UiTranslate(UiWidth() - 30, UiHeight() - 60)
            UiFont("MOD/Dynamic-Aircraft/Fonts/HUD_bold.ttf", 24)

            local boxWidth, boxHeight = 300, 75
            local outlineThickness, padding, lineHeight = 2, 15, 28

            -- blur backdrop
            UiPush()
                UiWindow(boxWidth, boxHeight, true)
                    UiBlur(0.2)
                UiWindow()
            UiPop()

            -- aberrated outline
            UiRectOutlineAberrated(boxWidth, boxHeight, col_main, outlineThickness, 1)
            UiTranslate(0, -lineHeight * 1.2)

            -- missile type and seeker
            local current_missile = shared.missiles[currentMissileIndex]
            local missileLabel = HasTag(current_missile, "radar") and "MISSILE RADAR" or "HEATSEEKER"

            UiPush()
                UiAlign("left middle")
                UiTranslate(-boxWidth + padding, -lineHeight * 0.8)
                UiFont("MOD/Dynamic-Aircraft/Fonts/HUD_bold.ttf", 18)
				UiColor(col_main[1],col_main[2],col_main[3])
                UiText(shared.missile_mode and "SEEKER ACTIVE" or "'V' TO ENABLE SEEKER")
            UiPop()

            UiPush()
                UiAlign("left middle")
                UiTranslate(-boxWidth + padding, 0)
                UiFont("MOD/Dynamic-Aircraft/Fonts/HUD_bold.ttf", 24)
				UiColor(col_main[1],col_main[2],col_main[3])
                UiText(missileLabel)
            UiPop()

            -- missile count box
            local countBoxSize = 45
            UiPush()
                UiAlign("right middle")
                UiTranslate(-padding, 0)
                UiRectOutlineAberrated(countBoxSize, countBoxSize, col_main, outlineThickness, 1)
                UiAlign("center middle")
                UiTranslate(-countBoxSize / 2, 0)
				UiColor(col_main[1],col_main[2],col_main[3])
                UiText(string.format("%d", shared.missile_count))
            UiPop()
        UiPop()
    end


    ---------------------------------
    -- ALERT / WARNING BOXES
    ---------------------------------
    UiPush()
        UiAlign("center middle")

        local screenH = UiHeight()
        local alertTop = screenH * (4/6)
        local spacing = 60
        local boxWidth, boxHeight = 380, 40
        local outlineThickness = 2
        local yOffset = 0

        local function drawAlertBox(text, color)
            UiPush()
                UiTranslate(UiWidth() / 2, alertTop + yOffset)
                UiRectOutlineAberrated(boxWidth, boxHeight, color, outlineThickness, 1)
                UiFont("MOD/Dynamic-Aircraft/Fonts/HUD_bold.ttf", 28)
				UiGlowText(text, fontPath, 28, col_glow, color, 1)
            UiPop()
            yOffset = yOffset + spacing
        end

        -- Missile Lock (blue)
        if HasTag(fuselage, "missile_lock") then
            drawAlertBox("MISSILE LOCK", col_alert_blue)		
        end
		
		        -- AoA Limiter
        if shared.aoa_timer>0  then
            if shared.aoa_limiter==true then
				drawAlertBox("AoA LIMITER ENABLED", col_alert_blue)
			else
				drawAlertBox("AoA LIMITER DISABLED", col_alert_blue)
			end			
        end

        -- Stall (red)
        if stall == true then
            drawAlertBox("STALL", col_alert_red)
        end

        -- Missile Alarm (red)
        if shared.missile_alert == true then
            drawAlertBox("MISSILE ALARM", col_alert_red)
        end
    UiPop()


    ---------------------------------
    -- COMPASS / HEADING TAPE
    ---------------------------------
    UiPush()
        UiAlign("center top")

        local fwd = TransformToParentVec(shared.FuselageTrans, Vec(0,0,-1))
        local heading = math.deg(math.atan2(fwd[1], fwd[3]))
        if heading < 0 then heading = heading + 360 end
        local mirrored = (360 - heading) % 360
local headingStr = string.format("%03d", math.floor(mirrored + 0.5))

        UiTranslate(UiWidth() / 2, 40)
        UiFont("MOD/Dynamic-Aircraft/Fonts/HUD_bold.ttf", 36)
        UiColor(1, 1, 1, 1)
        UiText(headingStr)

        UiTranslate(0, 36)
        UiFont("MOD/Dynamic-Aircraft/Fonts/HUD_bold.ttf", 20)
        local tapeWidth, markerSpacing = 400, 10
        local visibleHalf = tapeWidth / 2
        local step = 10
        local range = math.floor(visibleHalf / (markerSpacing * step)) * step

for i = -range, range, step do
    local deg = (math.floor(heading / step) * step + i) % 360

    -- compute delta based on REAL heading
    local delta = (deg - heading)
    if delta > 180 then delta = delta - 360 end
    if delta < -180 then delta = delta + 360 end
    local x = -delta * markerSpacing

    if x > -visibleHalf - 40 and x < visibleHalf + 40 then
        UiPush()
            UiTranslate(x, 0)

            -- MIRRORED bearing
            local mirrored = (360 - deg) % 360

            -- mirrored cardinal directions
            local label = ({
                [0]   = "N",
                [90]  = "W",   -- flipped
                [180] = "S",
                [270] = "E"    -- flipped
            })[mirrored] or string.format("%03d", mirrored)

            UiText(label)
        UiPop()
    end
end

        UiPush()
            UiTranslate(0, 24)
            UiRect(2, 10)
        UiPop()

        -- Orange “V” for map center
        local pos = shared.FuselageTrans.pos
        local bearingToOrigin = math.deg(math.atan2(-pos[1], -pos[3]))
        if bearingToOrigin < 0 then bearingToOrigin = bearingToOrigin + 360 end
        local delta = bearingToOrigin - heading
        if delta > 180 then delta = delta - 360 end
        if delta < -180 then delta = delta + 360 end
        local vx = -delta * markerSpacing
        if vx > -visibleHalf and vx < visibleHalf then
            UiPush()
                UiTranslate(vx, 22)
                UiColor(1, 0.5, 0, 1)
                UiText("V")
            UiPop()
        end
    UiPop()
end
-------END OF GENERAL UI------------

			local air_targets = FindBodies("fuselage", true) --CHANGE TO QUERY
			for i=1,#air_targets do 
			local air_target = air_targets[i]
			local target_speed=VecLength(GetBodyVelocity(air_target))
			local target_pos=GetBodyTransform(air_target).pos
			local target_dist=VecLength(VecSub(GetBodyTransform(fuselage).pos,target_pos))
				--shared.radar_on==true and
			if  shared.radar_on==true and shared.manned and HasTag(fuselage,"downed")==false and HasTag(airTarget,"downed")==false and target_speed>5 and target_dist>450 and target_pos[2]>10 then
			local imx, imy, dist = UiWorldToPixel(target_pos)

if dist >0 then
UiTranslate(imx, imy)
UiColor(0,1,0)
UiFont("bold.ttf", 25)
UiText("[  ]")
end
end
			end
			if  shared.radar_on==true and HasTag(fuselage,"downed")==false and shared.manned then
			local imx2, imy2, dist2 = UiWorldToPixel(shared.reticle)
			if dist2 >0 then
UiTranslate(imx2, imy2)
UiColor(1,1,1)
UiFont("bold.ttf", 30)
UiText("+")
end
elseif shared.manned then
			local imx2, imy2, dist2 = UiWorldToPixel(shared.reticle)
			if dist2 >0 then
UiTranslate(imx2, imy2)
UiColor(1,1,1)
UiFont("bold.ttf", 30)
UiText("+")
end
			end



			if  shared.radar_on==true and HasTag(fuselage,"downed")==false and shared.manned and shared.mapcooldown<2 then
			local imx3, imy3, dist3 = UiWorldToPixel(Vec(0,0,0))
			if dist3 >0 then
UiTranslate(imx3, imy3)
UiColor(1,0,0)
UiFont("bold.ttf", 30)
UiText(".")
end

			end




			--if HasTag(fuselage,"iff") and shared.missile_mode==true and shared.manned and HasTag(fuselage,"downed")==false then
		--	local imx, imy, dist = UiWorldToPixel(Vec(0,0,0))
--if dist > 0 then
--UiTranslate(imx, imy)
--UiFont("bold.ttf", 48)
--UiColor(1,0,0)
--UiText("radar iff")
		--	end




			end
end


function server.update(dt)	
		shared.aoa_timer=shared.aoa_timer-dt
		ignition_timer=ignition_timer+dt
		playerIds = GetAllPlayers()
		
		
		
		

		
		
		
		
		
		
		
		
		
		
		
		
		
		if InputDown("lmb",shared.pilot) and jammed==false and shared.manned then
		overheat_timer=overheat_timer+dt*2
		elseif overheat_timer>=0 then
		overheat_timer=overheat_timer-dt
		end
		if shared.manned then
		end
		
		if overheat_timer>10 and jammed==false then
		jammed=true		
		if #mgs>0 or #cannons>0 or #rotarys>0 then
		PlaySound(LoadSound("gas-l0.ogg"), GetBodyTransform(fuselage).pos, 3, false)	
		end
		end
		
		if overheat_timer<0 and jammed==true then
		jammed=false
		if #mgs>0 or #cannons>0 or #rotarys>0 then
		PlaySound(LoadSound("gas-l0.ogg"), GetBodyTransform(fuselage).pos, 3, false)	
		end
		end
		
		
		
		
		if waterbomb==true then
		waterbomb_timer=waterbomb_timer-dt
		end
		
		if waterbomb_timer<0 then
		waterbomb=false
		end
		
		
		if waterbomb_timer>0 and waterbomb==true then
		for _, WaterLight in ipairs(WaterLights) do
		WaterLightTrans=GetLightTransform(WaterLight)
			for i=1,10 do
		        ParticleReset()
				ParticleTile(5)
                ParticleRadius(rnd(1,1.5),rnd(2,3))
                ParticleColor(0.9,0.9,0.9)
                ParticleGravity(rnd(-9,-15))
	        	ParticleAlpha(1, 0)
				ParticleFlags(256)
	        	ParticleStretch(20.0)
				ParticleEmissive(0,0)
				ParticleCollide(0)
				ParticleDrag(rnd(0.05,0.075), 0.075)
	        	ParticleRotation(rnd(-1, 1), 0, "easeout")
                    SpawnParticle(WaterLightTrans.pos, VecAdd(GetBodyVelocity(fuselage),Vec(rnd(-2,2),rnd(-2,-1),rnd(-2,2))), rnd(5,10))
					end
		end
		end
		
if HasTag(fuselage,"downed") or HasTag(fuselage, "eb") then
	AllBodies=FindBodies()
	
	 for _, AllBody in ipairs(AllBodies) do
	 if VecLength(GetBodyVelocity(AllBody))>4 and HasTag(AllBody,"deco")==false then
	SetProperty(AllBody, "friction", 0.05)
	SetProperty(AllBody, "frictionMode", "minimum")
	else
		SetProperty(AllBody, "friction", 0.7)
	SetProperty(AllBody, "frictionMode", "minimum")
	end
	
	end
end


reaction_timer=reaction_timer+dt
if reaction_timer>5.1 then
reaction_timer=0
end

		if drop==true then
		droptimer=droptimer+dt
		
		if droptimer>1 then		
		--drop		
		for _, paradrop in ipairs(paradrops) do
		paratrans=GetLightTransform(paradrop)
		Spawn("MOD/Dynamic-Aircraft/Ragdolls/AI/bailouts/soldierUS.xml", paratrans)
		
		end
		
		troops=troops-1
		droptimer=0
		end
		end
		
		if troops<1 and drop==true then
		drop=false
		for _, dropdoor in ipairs(dropdoors) do
		SetTag(dropdoor,"open")
		end
		end
		

		

		bailouttimer=0

		
		if bailouttimer>1 then

		bailout=GetLightTransform(baillight)
		
Canopies=FindShapes("canopy")
for _, Canopy in ipairs(Canopies) do
Delete(Canopy)
end

if HasTag(baillight,"eject") then
Spawn("MOD/Dynamic-Aircraft/Ragdolls/AI/bailouts/pilot_player_eject.xml", bailout)
else
Spawn("MOD/Dynamic-Aircraft/Ragdolls/AI/bailouts/pilot_player.xml", bailout)	
end		
		
		bailouttimer=0
		end
		

		--the essentials
		CamZoomSmoother=CamZoomSmoother+dt
		RoarTimer=RoarTimer+dt
		RoarCooldown=RoarCooldown+dt
		bombbay_timer=bombbay_timer+dt
		alarm_cooldown=alarm_cooldown+dt
		shared.cooldown=shared.cooldown+dt
		radar_cooldown=radar_cooldown-dt
		gearcooldown=gearcooldown+dt
		missile_cooldown=missile_cooldown+dt
		lightstimer=lightstimer+dt
		shared.mapcooldown=shared.mapcooldown+dt
		downtimer=downtimer+dt
		
		
		
		fus_vec=GetBodyVelocity(fuselage)
		shared.speed_vec = VecLength(GetBodyVelocity(fuselage))		
		speed_side_vec=VecLength(Vec(GetBodyVelocity(fuselage)[1],0,GetBodyVelocity(fuselage)[3]))
		
		shared.FuselageTrans = GetBodyTransform(fuselage)
		
		CenterDistance=VecSub(Vec(0,0,0),shared.FuselageTrans.pos)
		CenterMapDistance=VecLength(Vec(CenterDistance[1],0,CenterDistance[3]))


--BOMB BAY DOOR


					 		for i=1,#bayhinges do 
		local bayhinge = bayhinges[i]
		local bmin, bmax = GetJointLimits(bayhinge)

		if bombbay_timer<2 then
		SetJointMotorTarget(bayhinge, bmax, 2.5)	

		else
		SetJointMotorTarget(bayhinge, bmin, 2.5)	

		end
		end









		--TOTAL AIRFRAME DEATH
		
		

		--downtimer events for speedvec above 35

		if downtimer<0.5 and shared.speed_vec<10 and total_loss==false and wet==false then
		--DebugPrint("total airframe death")
		MakeHole(shared.FuselageTrans.pos, 80, 80, 0)
		PlaySound(LoadSound("MOD/Dynamic-Aircraft/Snd/aircraft-sfx/crash_explosion.ogg"), shared.FuselageTrans.pos, 20, false)
		if shared.manned then
		SetPlayerHealth(0,shared.pilot)
		end
		--spawn little burning bitlets
		
		for i=1, 5 do
		Paint(VecAdd(shared.FuselageTrans.pos,Vec(rnd(-3,3),rnd(-3,3),rnd(-3,3))),3,"explosion",rnd(0.5,1))		
		end
		
		--PARTICLE EFFECTS
	--mashroomfire1
	for i=1,50 do
		        ParticleReset()
				ParticleTile(5)
                ParticleRadius(rnd(1,4),rnd(7,10))
                ParticleColor(rnd(0.7,0.8),rnd(0.25,0.35),rnd(0.15,0.25))
                --ParticleGravity(0, rnd(-6, 1))
	        	ParticleAlpha(1, 0)
	        	ParticleStretch(20.0)
				ParticleEmissive(1,0)
				ParticleCollide(0)
				ParticleDrag(0, 0.05)
	        	ParticleRotation(rnd(1, 1.5), 1, "easeout")
	        	ParticleEmissive(rnd(6,7), 0, "easeout")
                    SpawnParticle(shared.FuselageTrans.pos, Vec(rnd(-3,3), rnd(5,10), rnd(-3,3)), rnd(5,10))
					
							        ParticleReset()
									ParticleTile(0)
                ParticleRadius(rnd(1,4),rnd(7,10))
                ParticleColor(0.1,0.1,0.1)
                --ParticleGravity(0, rnd(-6, 1))
	        	ParticleAlpha(1, 0)
	        	ParticleStretch(20.0)
				ParticleEmissive(0,0)
				ParticleGravity(-1,5)
				ParticleCollide(0)
				ParticleDrag(0, 0.05)
	        	ParticleRotation(rnd(1, 1.5), 1, "easeout")
                    SpawnParticle(shared.FuselageTrans.pos, Vec(rnd(-3,3), rnd(1,10), rnd(-3,3)), rnd(10,15))
					
					
					
                end	
	
	
		
		for i=1, 20 do
		
												--spikes
								ParticleReset()
				ParticleTile(0)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRotation(rnd(0.5,1.5), 0.0, "easeout")
					ParticleRadius(rnd(0.0015*450,0.004*500), rnd(0.004*450,0.008*500))
					ParticleDrag(rnd(0.1,0.8))
					ParticleEmissive(0, 0)
					ParticleColor(.25,.22,.2)
					ParticleGravity(rnd(-1,1))
					ParticleAlpha(1, 0)
				SpawnParticle(VecAdd(shared.FuselageTrans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike0, 500*0.025)
								SpawnParticle(VecAdd(shared.FuselageTrans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike1, 500*0.025)
												SpawnParticle(VecAdd(shared.FuselageTrans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike2, 500*0.025)
																SpawnParticle(VecAdd(shared.FuselageTrans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike3, 500*0.025)
																				SpawnParticle(VecAdd(shared.FuselageTrans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike4, 500*0.025)
																								SpawnParticle(VecAdd(shared.FuselageTrans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike5, 500*0.025)
																												SpawnParticle(VecAdd(shared.FuselageTrans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike6, 500*0.025)
																																SpawnParticle(VecAdd(shared.FuselageTrans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike7, 500*0.025)
																																				SpawnParticle(VecAdd(shared.FuselageTrans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike8, 500*0.025)
																																								SpawnParticle(VecAdd(shared.FuselageTrans.pos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike9, 500*0.025)
		end
		
		
		
		
		
		
		explosion_bodies=FindBodies("",true)
		 for _, explosion_body in ipairs(explosion_bodies) do
		 if VecLength(VecSub(GetBodyTransform(explosion_body).pos,shared.FuselageTrans.pos))<10 then 
		 SetBodyVelocity(explosion_body,Vec(rnd(-15,15),rnd(0,15),rnd(-15,15)))
		 end
		end
		
		total_loss=true
		end





		--SPINOUT DETECTION
		
		spinout_value=VecLength(GetBodyAngularVelocity(fuselage))

		
		if spinout_value>10 then
		spinout_stopper=true
		else
		spinout_stopper=false
		end
		--MISSILE ALARM
		
		if alarm_cooldown>1 then
		RemoveTag(fuselage,"ma")
		RemoveTag(fuselage,"missile_lock")	
		alarm_cooldown=0
		end
		
		if HasTag(fuselage,"ma") then
		shared.missile_alert=true
		else
		shared.missile_alert=false
		end		

	
			--if dispense_flares==true
	if dispense_flares==true then
	flare_effect=1.5
	else
	flare_effect=flare_effect-dt
	end
	
	if flare_effect<0 then
	RemoveTag(fuselage,"fl")
	end
		
		
		--WING RIPPER-----------------------------------------------------------------------------------------------------------------------------------



		WingLengthCurrentR=VecLength(VecSub(GetLightTransform(point_R).pos,GetLightTransform(wingpoint_R).pos))
		

		WingLengthCurrentL=VecLength(VecSub(GetLightTransform(point_L).pos,GetLightTransform(wingpoint_L).pos))
		

		
		if shared.speed_vec>15 then
		if WingLengthCurrentR>1.5*WingLengthInitialR or WingLengthCurrentR<0.6*WingLengthInitialR then
		RightRipTimer=RightRipTimer-dt
		if RightRipTimer <0 then
		
		
		SetTag(fuselage,"downed")
		RightTipLoss=true
		rt=0.5
		antiforcer=0
		
		if spinout_stopper==false then
		ApplyBodyImpulse(GetShapeBody(WingR2), GetBodyTransform(part_body).pos, Vec(0,GetBodyMass(GetShapeBody(WingR2))*shared.speed_vec*rnd(0,10)*0.001*1,0))
		end
		end
		
		end
		
		if WingLengthCurrentL>1.5*WingLengthInitialL or WingLengthCurrentL<0.6*WingLengthInitialL then
		
		
				LeftRipTimer=LeftRipTimer-dt
		if LeftRipTimer <0 then
		
		
		SetTag(fuselage,"downed")
		LeftTipLoss=true
		lt=0.5
		antiforcer=0
		if spinout_stopper==false then
		ApplyBodyImpulse(GetShapeBody(WingL2), GetBodyTransform(part_body).pos, Vec(0,GetBodyMass(GetShapeBody(WingL2))*shared.speed_vec*rnd(0,10)*0.001*1,0))
		end
		
		end
		
		end		
		

		
		end


		
			tail=TransformToParentPoint(shared.FuselageTrans, Vec(0, 0, 10*size))
			--DebugCross(tail)
			tip_r=TransformToParentPoint(shared.FuselageTrans, Vec(10*size, 0, 0))
			--DebugCross(tip_r)
			tip_l=TransformToParentPoint(shared.FuselageTrans, Vec(-10*size, 0, 0))
			--DebugCross(tip_l)
			--engine_something=TransformToParentPoint(GetBodyTransform(shared.engine_body), Vec(-0, 0, 0))
			shared.reticle=TransformToParentPoint(shared.FuselageTrans, Vec(0, -40, -1000))


	
		if HasTag(fuselage,"downed")==false then
		roll_damp=1
---- bank stabiliser (PD control with gain scheduling)

wingspan = VecLength(VecSub(tip_r, tip_l))
bank_raw = tip_r[2] - tip_l[2]
bank = bank_raw / wingspan

local angVel = GetBodyAngularVelocity(fuselage)
local rollRate = angVel[3]

local correction = bank * roll_force

-- damping stronger near level flight
local dampingMultiplier = 1 - math.abs(bank)       -- 1 at level, 0 at full bank
local damping = rollRate * roll_damp * dampingMultiplier

ApplyBodyImpulse(
    fuselage,
    tip_r,
    TransformToParentVec(
        GetBodyTransform(fuselage),
        Vec(0, -(correction + damping), 0)
    )
)

ApplyBodyImpulse(
    fuselage,
    tip_l,
    TransformToParentVec(
        GetBodyTransform(fuselage),
        Vec(0, (correction + damping), 0)
    )
)

		
		end


--FLOATPLANE PHYSICS


        local floats = FindLights("float")
        if floats then
            for _, float in ipairs(floats) do
			if HasTag(fuselage,"downed")==false then
			floatTrans=GetLightTransform(float)
			--DebugCross(floatTrans.pos)
			
			--Water Depth
			
			local FloatinWater, Floatdepth = IsPointInWater(floatTrans.pos)
			
			if FloatinWater then
			--DebugPrint("float in water")
			FloatForce=Floatdepth*1000
			else
			FloatForce=0
			end
			
			ApplyBodyImpulse(fuselage, floatTrans.pos, TransformToParentVec(GetBodyTransform(fuselage), Vec(0,FloatForce,0)) )
			
			
			if shared.speed_vec>2 and FloatinWater then
			
                if HasTag(float, "float_back") then

			for i=1, 1 do

				--water splash
				ParticleReset()
				ParticleTile(5)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(0.08*shared.speed_vec, 0.3*shared.speed_vec)
					ParticleDrag(rnd(0.15,0.5))
					ParticleEmissive(0, 0)
					ParticleColor(.9,.9,1)
					ParticleGravity(rnd(-3,-4))
					ParticleAlpha(0.7, 0)
				SpawnParticle(VecAdd(floatTrans.pos, Vec(rnd(-0.1,0.1),Floatdepth,rnd(-0.1,0.5))), Vec(rnd(-1,1),rnd(shared.speed_vec*0.2,shared.speed_vec*0.5),rnd(-1,1)), 3)
				
				
				
				
				
                end
				end
				
				if HasTag(float, "float_front") then
				--FRONT WAVE
				
				for i=1, 2 do
								ParticleReset()
				ParticleTile(5)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(0.04*shared.speed_vec, 0.15*shared.speed_vec)
					ParticleDrag(0.01)
					ParticleEmissive(0, 0)
					ParticleColor(.9,.9,1)
					ParticleGravity(-0.01)
					ParticleAlpha(0.5, 0)
				SpawnParticle(VecAdd(floatTrans.pos, Vec(rnd(-0.1,0.1),Floatdepth,rnd(-0.1,0.5))), TransformToParentVec(GetBodyTransform(fuselage), Vec(2,0,0)), 1)
				SpawnParticle(VecAdd(floatTrans.pos, Vec(rnd(-0.1,0.1),Floatdepth,rnd(-0.1,0.5))), TransformToParentVec(GetBodyTransform(fuselage), Vec(-2,0,0)), 1)
				
				end
				
                end
				end
			
				
            end
			
			
		end	
        end

	


---SWEPT WING
if HasTag(fuselage,"downed")==false then
							 		for i=1,#sweptjoints do 
		local sweptjoint = sweptjoints[i]
		sweptmin, sweptmax = GetJointLimits(sweptjoint)
		
		sweptdifference=sweptmax-sweptmin
		
		sweptmotorposRaw=clamp(shared.speed_vec,30,100)
		sweptmotorpos=(sweptmotorposRaw-30)/70


		
		if shared.activated then
		SetJointMotorTarget(sweptjoint,(sweptmin+sweptmotorpos*sweptdifference),0.5)
		else
		SetJointMotorTarget(sweptjoint,sweptmax,0.5)
		end
	end	
end







--LIFT

		
		--Math calculation stuff
		velocity = GetBodyVelocity(fuselage)
		localVel = TransformToLocalVec(shared.FuselageTrans, velocity)
		
		airSpeed = -localVel[3]
		vertSpeed = -localVel[2]
		horSpeed = -localVel[1]
		

		
		c=((airSpeed^2)+(vertSpeed^2))^0.5
		var1=vertSpeed/c*(-90)		--basically degree (very simplified)
	

--shake

	
if vertSpeed > 0 then
	
	cx_add = 0.4
	if var1  < 20 then
	cx=(var1*0.005)+0.4
	end

	if var1 >20 and var1 <25 then
cx=(20*0.05)
	end
	
	if var1 >25 then
	cx=(var1*(-0.005))+0.475
	end
	
	else
	cx=0
	end
	
	
	
	--DebugWatch("vertSpeed", vertSpeed)
	if vertSpeed > 3 and shared.speed_vec>1 then
	stall=true
	else
	stall=false
	end
	
	if vertSpeed > 2 and shared.speed_vec>10 then


					for i=1,#tips do 
					local tip = tips[i]
					tipt = GetLightTransform(tip)																														
					tiprandom=rnd(0,100)
	if tiprandom<60 then
				for i=1, 20 do
				ParticleReset()
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(0.1, 0.3)
					ParticleDrag(rnd(1,1.6))
					ParticleEmissive(0, 0)
					ParticleColor(0.9, 0.9, 0.9)
					ParticleGravity(rnd(0,0.5))
					ParticleAlpha(0.2, 0)
				SpawnParticle(VecAdd(tipt.pos, Vec(rnd(-0.1,0.1),rnd(-0.1,0.1),rnd(-0.1,0.1))), TransformToParentVec(GetBodyTransform(fuselage), Vec(0,0,rnd(0,-20))), rnd(2,4))
				end
				end
	end
	end
	if vertSpeed > 2 and shared.speed_vec>50 then
					for i=1,#clouds do 
					local cloud = clouds[i]
					cloudt = GetLightTransform(cloud)
									for i=1, 30 do
				ParticleReset()
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(0.5, 0.8)
					ParticleDrag(rnd(1,1.6))
					ParticleEmissive(0, 0)
					ParticleColor(0.9, 0.9, 0.9)
					ParticleGravity(rnd(0,0.5))
					ParticleAlpha(0.4, 0)
				--	SpawnParticle(VecAdd(cloudt.pos, Vec(rnd(-3,3),rnd(-0.1,0.1),rnd(-1,1))), TransformToParentVec(GetBodyTransform(fuselage), Vec(0,0,rnd(0,-20))), rnd(0.05,0.1))
				SpawnParticle(VecAdd(cloudt.pos, VecAdd(TransformToParentVec(cloudt,Vec(rnd(-1.5,1.5),rnd(-0.1,0.1),rnd(-1,1))))), TransformToParentVec(GetBodyTransform(fuselage), Vec(0,0,rnd(0,-20))), rnd(0.05,0.1))
				--SpawnParticle(VecAdd(tt.pos, Vec(rnd(-0.05,0.05),rnd(-0.05,0.05),rnd(-0.05,0.05))),VecAdd(TransformToParentVec(GetBodyTransform(fuselage), Vec(0,0,20)), GetBodyVelocity(fuselage)), 3)
				end
				end
	end
	
	
	
	
	
	WingLeftHealth=(1-lt-lw)
	WingRightHealth=(1-rt-rw)
	

	if spinout_stopper==false then
	if  airSpeed>1 and airSpeed<liftcap then
	
	liftLeft = (airSpeed)*coeff*cx*mass_percent*WingLeftHealth*0.5
	liftRight = (airSpeed)*coeff*cx*mass_percent*WingRightHealth*0.5
	
	--ApplyBodyImpulse(fuselage,VecAdd(GetBodyCenterOfMass(fuselage),GetBodyTransform(fuselage).pos),TransformToParentVec(GetBodyTransform(fuselage), Vec(0,lift,0)))
					
	ApplyBodyImpulse(fuselage, tip_r, TransformToParentVec(GetBodyTransform(fuselage), Vec(0,liftRight,0)) )
	ApplyBodyImpulse(fuselage, tip_l, TransformToParentVec(GetBodyTransform(fuselage), Vec(0,liftLeft,0)) )
	
	elseif airSpeed>1 and airSpeed>liftcap then
	
		lift2Left = liftcap*coeff*cx*mass_percent*WingLeftHealth
		lift2Right = liftcap*coeff*cx*mass_percent*WingRightHealth
	
	--ApplyBodyImpulse(fuselage,VecAdd(GetBodyCenterOfMass(fuselage),GetBodyTransform(fuselage).pos),TransformToParentVec(GetBodyTransform(fuselage), Vec(0,lift2,0)))
	
		ApplyBodyImpulse(fuselage, tip_r, TransformToParentVec(GetBodyTransform(fuselage), Vec(0,lift2Right,0)) )
	ApplyBodyImpulse(fuselage, tip_l, TransformToParentVec(GetBodyTransform(fuselage), Vec(0,lift2Left,0)) )
	
	end
	end
mass = GetBodyMass(fuselage)

mass_percent = mass/mass_init


--BASIC DAMAGE STUFF--

if burning and burntime>0 then
burntime=burntime-dt*small_tank_dt*big_tank_dt

end



    -- Iterate through all registered parts and calculate their current voxel percentage
    for part, initialVoxelCount in pairs(initialVoxelCounts) do
        local currentVoxelCount = GetShapeVoxelCount(part)
        local voxelPercentage = currentVoxelCount / initialVoxelCount * 100

		
		--water damage
		
		local partWater, depth5 = IsPointInWater(GetBodyTransform(GetShapeBody(part)).pos)
		
	if not HasTag(part,"wet") then	

if partWater and shared.speed_vec>45 then
		SetTag(part,"very_wet")
		SetTag(fuselage,"wcr")
end		
		
if partWater and shared.speed_vec>30 then
DeleteConnectedCrits(part)
SetTag(fuselage,"wcr")
SetTag(part,"wet")
SetTag(GetShapeBody(part),"blown")
Part_Damage(part, 10)
end
end		
		
	if shared.FuselageTrans.pos[2]<10 then	
		if partWater and watertimer>=0 and not HasTag(part,"wet") and not HasTag(part,"very_wet") and total_loss==false then 
		watertimer=watertimer-dt*0.04*part_float
	ApplyBodyImpulse(GetShapeBody(part),GetBodyTransform(GetShapeBody(part)).pos, Vec(0,currentVoxelCount*watertimer*depth5*0.10+speed_side_vec*currentVoxelCount*watertimer*0.01,0))
			if shared.speed_vec>2 and (shared.FuselageTrans.pos)[2]>-10 and VecLength(VecSub(GetBodyTransform(GetShapeBody(part)).pos,Vec(0,0,0)))>10 then
			for i=1, 1 do
				--water splash
				ParticleReset()
				ParticleTile(5)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(0.08*shared.speed_vec, 0.3*shared.speed_vec)
					ParticleDrag(rnd(0.15,0.5))
					ParticleEmissive(0, 0)
					ParticleColor(.9,.9,1)
					ParticleGravity(rnd(-3,-4))
					ParticleAlpha(0.7, 0)
				SpawnParticle(VecAdd(GetBodyTransform(GetShapeBody(part)).pos, Vec(rnd(-0.1,0.1),depth5,rnd(-0.1,0.5))), Vec(rnd(-1,1),rnd(shared.speed_vec*0.2,shared.speed_vec*0.5),rnd(-1,1)), 3)
							end				
				--FRONT WAVE				
				for i=1, 2 do
								ParticleReset()
				ParticleTile(5)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(0.04*shared.speed_vec, 0.15*shared.speed_vec)
					ParticleDrag(0.01)
					ParticleEmissive(0, 0)
					ParticleColor(.9,.9,1)
					ParticleGravity(-0.01)
					ParticleAlpha(0.5, 0)
				SpawnParticle(VecAdd(GetBodyTransform(GetShapeBody(part)).pos, Vec(rnd(-0.1,0.1),depth5,rnd(-0.1,0.5))), TransformToParentVec(GetBodyTransform(fuselage), Vec(4,0,0)), 2)
				SpawnParticle(VecAdd(GetBodyTransform(GetShapeBody(part)).pos, Vec(rnd(-0.1,0.1),depth5,rnd(-0.1,0.5))), TransformToParentVec(GetBodyTransform(fuselage), Vec(-4,0,0)), 2)
				
				end
				
                end
	
	
	
	
	
	
	
		end
		
				if partWater and watertimer>=0 and HasTag(part,"wet") and not HasTag(part,"very_wet") then 
		watertimer=watertimer-dt*0.08*part_float
	ApplyBodyImpulse(GetShapeBody(part),GetBodyTransform(GetShapeBody(part)).pos, Vec(0,currentVoxelCount*watertimer*depth5*0.02+speed_side_vec*currentVoxelCount*watertimer*0.01,0))
	
				if shared.speed_vec>2 and (shared.FuselageTrans.pos)[2]>-10 then
			for i=1, 1 do
				--water splash
				ParticleReset()
				ParticleTile(5)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(0.08*shared.speed_vec, 0.3*shared.speed_vec)
					ParticleDrag(rnd(0.15,0.5))
					ParticleEmissive(0, 0)
					ParticleColor(.9,.9,1)
					ParticleGravity(rnd(-3,-4))
					ParticleAlpha(0.7, 0)
				SpawnParticle(VecAdd(GetBodyTransform(GetShapeBody(part)).pos, Vec(rnd(-0.1,0.1),depth5,rnd(-0.1,0.5))), Vec(rnd(-1,1),rnd(shared.speed_vec*0.2,shared.speed_vec*0.5),rnd(-1,1)), 3)
							end	
							
								for i=1, 2 do
								ParticleReset()
				ParticleTile(5)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(0.04*shared.speed_vec, 0.15*shared.speed_vec)
					ParticleDrag(0.01)
					ParticleEmissive(0, 0)
					ParticleColor(.9,.9,1)
					ParticleGravity(-0.01)
					ParticleAlpha(0.5, 0)
				SpawnParticle(VecAdd(GetBodyTransform(GetShapeBody(part)).pos, Vec(rnd(-0.1,0.1),depth5,rnd(-0.1,0.5))), TransformToParentVec(GetBodyTransform(fuselage), Vec(2,0,0)), 1)
				SpawnParticle(VecAdd(GetBodyTransform(GetShapeBody(part)).pos, Vec(rnd(-0.1,0.1),depth5,rnd(-0.1,0.5))), TransformToParentVec(GetBodyTransform(fuselage), Vec(-2,0,0)), 1)
				
				end			
							
							
							
							
							
							end
	
		end
	end	
		
		--Random landing gear logic part cause it doesnt work if i put it anywhere else lol
		
		if gear_out==true and damage_total==false then
							if HasTag(part, "gear_open") then
							RemoveTag(part, "invisible")
							end
						if HasTag(part, "gear_closed") then
						SetTag(part, "invisible")
						end

end
if gear_in==true or damage_total then
							if HasTag(part, "gear_open") then
							SetTag(part, "invisible")
							end
						if HasTag(part, "gear_closed") then
						RemoveTag(part, "invisible")
						end
					
					
end
		
		
		if HasTag(fuselage,"downed") then
		 		for i=1,#wheels do 
		local wheel = wheels[i]
		if HasTag(wheel,"keeper_wheel")==false then
		Delete(wheel)
		end
		end
		end
		
		
				if HasTag(fuselage,"downed") or HasTag(fuselage,"eb") then

		if HasTag(part,"emergency") then
		Delete(part)

		end
		end




        -- Apply damage logic based on the voxel percentage
        if voxelPercentage <= 99 then
            Part_Damage(part, voxelPercentage)
        elseif voxelPercentage <= 50 then
            -- Apply appropriate damage logic for parts with 50% or less voxel count remaining
            -- For example: SetShapeEmissiveScale(part, 2) -- Increase emissive scale to simulate heavier damage
        elseif voxelPercentage <= 25 then
            -- Apply appropriate damage logic for parts with 25% or less voxel count remaining
            -- For example: SetShapeEmissiveScale(part, 4) -- Increase emissive scale even more to simulate severe damage
        end
    end
		
		--
		
		--damage scale
	
	if GetVehicleHealth(vehicle) < 0.9 then
	damage_light=true
	--DebugPrint("light damage")
	else
	damage_light=false
	end	


	if GetVehicleHealth(vehicle) < 0.6 then
	shared.damage_medium=true
	--DebugPrint("medium damage")
		else
	shared.damage_medium=false
	end	

	
	if GetVehicleHealth(vehicle) < 0.5 then
	damage_total=true
	--DebugPrint("beyond control")
		else
	damage_total=false
	end	
		
if GetVehicleHealth(vehicle) < 0.3 then
	wreck=true
	--DebugPrint("wrecked")
		else
	wreck=false
	end	
		
		

		speedflare=speedflare+dt
		speedmg = speedmg + dt
		speedcannon = speedcannon + dt
		speedrotary = speedrotary + dt
		speedrocket=speedrocket+ dt
		speedbarrage=speedbarrage+ dt

	rotor_update=GetBodyMass(rotor)
	rotor_health=rotor_update/rotor_init
		

		
		








--WATER SPLASH


waterpos = GetBodyTransform(fuselage).pos
inWater, depth = IsPointInWater(waterpos)

if inWater then
SetTag(fuselage, "downed")
		 		for i=1,#shared.engines do 
		local engine = shared.engines[i]
		SetTag(GetShapeBody(engine), "broken")
		end
		
				 		for i=1,#props do 
		local prop = props[i]
		Delete(prop)
		end
end
if inWater and shared.speed_vec>25 and not wet then



--particle effects


						for i=1, 100 do
				
				
				
				
								--spikes

				--water splash vertical
				ParticleReset()
				ParticleTile(5)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRotation(rnd(0.5,1.5), 0.0, "easeout")
					ParticleRadius(0.008*500, 0.008*500)
					ParticleDrag(rnd(0.15,0.3))
					ParticleEmissive(0, 0)
					ParticleColor(.9,.9,1)
					ParticleGravity(rnd(-6,-8))
					ParticleAlpha(0.5, 0)
				SpawnParticle(VecAdd(waterpos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), Vec(rnd(-500*0.02*size,500*0.02*size),rnd(0,500*0.2*size),rnd(-500*0.02*size,500*0.02*size)), 300*0.035*size)
				
				--side splash
				ParticleReset()
				ParticleTile(0)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRotation(rnd(0.5,1.5), 0.0, "easeout")
					ParticleRadius(0.006*500, 0.008*500)
					ParticleDrag(rnd(0.1,0.15))
					ParticleEmissive(0, 0)
					ParticleColor(.9,.9,1)
					ParticleGravity(rnd(-1,-2))
					ParticleAlpha(0.5, 0)
				SpawnParticle(VecAdd(waterpos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), Vec(rnd(-200*0.08*size,200*0.08*size),rnd(0,200*0.02*size),rnd(-200*0.08*size,200*0.08*size)), 100*0.035*size)
				SpawnParticle(VecAdd(waterpos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), Vec(rnd(-200*0.08*size,200*0.08*size),rnd(0,200*0.02*size),rnd(-200*0.08*size,200*0.08*size)), 100*0.035*size)
				
				
				--spikes
								ParticleReset()
				ParticleTile(5)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRotation(rnd(0.5,1.5), 0.0, "easeout")
					ParticleRadius(rnd(0.0015*400,0.004*400), rnd(0.004*400,0.008*400))
					ParticleDrag(rnd(0.1,1))
					ParticleEmissive(0, 0)
					ParticleColor(.9,.9,1)
					ParticleGravity(rnd(-4,-5))
					ParticleAlpha(0.8, 0)
				SpawnParticle(VecAdd(waterpos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike0, 500*0.015)
								SpawnParticle(VecAdd(waterpos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike1, 500*0.015)
												SpawnParticle(VecAdd(waterpos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike2, 500*0.015)
																SpawnParticle(VecAdd(waterpos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike3, 500*0.015)
																				SpawnParticle(VecAdd(waterpos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike4, 500*0.015)
																								SpawnParticle(VecAdd(waterpos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike5, 500*0.015)
																												SpawnParticle(VecAdd(waterpos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike6, 500*0.015)
																																SpawnParticle(VecAdd(waterpos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike7, 500*0.015)
																																				SpawnParticle(VecAdd(waterpos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike8, 500*0.015)
																																								SpawnParticle(VecAdd(waterpos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike9, 500*0.015)
																																								
					
				--foam spikes								
												ParticleReset()
				ParticleTile(0)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRotation(rnd(0.5,1.5), 0.0, "easeout")
					ParticleRadius(rnd(0.0015*500,0.004*500), rnd(0.004*500,0.008*500))
					ParticleDrag(rnd(0.1,1))
					ParticleEmissive(0, 0)
					ParticleColor(.9,.9,1)
					ParticleGravity(rnd(-1,-3))
					ParticleAlpha(0.5, 0)
				SpawnParticle(VecAdd(waterpos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike0, 500*0.015)
								SpawnParticle(VecAdd(waterpos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike1, 500*0.015)
												SpawnParticle(VecAdd(waterpos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike2, 500*0.015)
																SpawnParticle(VecAdd(waterpos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike3, 500*0.015)
																				SpawnParticle(VecAdd(waterpos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike4, 500*0.015)
																								SpawnParticle(VecAdd(waterpos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike5, 500*0.015)
																												SpawnParticle(VecAdd(waterpos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike6, 500*0.015)
																																SpawnParticle(VecAdd(waterpos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike7, 500*0.015)
																																				SpawnParticle(VecAdd(waterpos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike8, 500*0.015)
																																								SpawnParticle(VecAdd(waterpos, Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5))), spike9, 500*0.015)
					
					end

PlaySound(splash, GetBodyTransform(fuselage).pos, 20)
wet=true
end

if wet then
burntime=0
end

reticle_trans = GetLightTransform(shared.reticle)
		
if shared.manned then
	


	

	
	
	--door
		if InputDown("downarrow",shared.pilot) and doorstate < 2.5 then
		doorstate = doorstate + 0.01
	elseif InputDown("uparrow",shared.pilot)  and doorstate > (-0.01)then
		doorstate = doorstate - 0.01
		end
		
				 		for i=1,#motorjoints do 
		local motorjoint = motorjoints[i]
		motormin, motormax = GetJointLimits(motorjoint)
		targetmotorpos=motormax*doorstate*0.4
	--	DebugWatch("targetmotorpos", targetmotorpos, "%")
		SetJointMotorTarget(motorjoint, targetmotorpos, 1)		
	end	

	brakesound=clamp(brakesound_timer,0,3)
	if brake_force>0 then	
--	DebugPrint("has brakes")



	PlayLoop(LoadLoop("MOD/Dynamic-Aircraft/Snd/aircraft-sfx/brake.ogg"),shared.FuselageTrans.pos,brakesound*shared.speed_vec*0.1)


		
			if InputDown("space",shared.pilot) then
			if brakesound_timer<0 then
			brakesound_timer=0
			else
			brakesound_timer=brakesound_timer+dt
			end
			--DebugPrint("extending airbrake")
		brakestate = 2.5
	else
		brakestate = 0
					if brakesound_timer>brakesound then
			brakesound_timer=brakesound
			else
			brakesound_timer=brakesound_timer-dt
			end
		end			
					 		for i=1,#brakejoints do 
		local brakejoint = brakejoints[i]
		brakemin, brakemax = GetJointLimits(brakejoint)
		brakemotorpos=brakemax*brakestate*0.4
		SetJointMotorTarget(brakejoint, brakemotorpos, 1)	
	end	
	end
	

	
	--shared.throttle
	
	if shared.activated then
	if InputDown("shift",shared.pilot) and shared.throttle < 2.5 then
		shared.throttle = shared.throttle + 0.01
	elseif InputDown("ctrl",shared.pilot)  and shared.throttle > (-0.01)then
		shared.throttle = shared.throttle - 0.01
	end
	end

			
			
			--SONIC BOOM
			
			if damage_total==false and shared.speed_vec>110 and shared.speed_vec<115 then		
					for i=1, 40 do
				ParticleReset()
				ParticleTile(1)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(1, 15)
					ParticleDrag(rnd(0.02, 0.03))
					ParticleEmissive(0, 0)
					ParticleColor(0.9, 0.9, 0.9)
					ParticleGravity(rnd(1,3))
					ParticleAlpha(0.3, 0)
				SpawnParticle(VecAdd(GetBodyTransform(fuselage).pos, Vec(rnd(-0.05,0.05),rnd(-0.05,0.05),rnd(-0.05,0.05))),VecAdd(TransformToParentVec(GetBodyTransform(fuselage), Vec(0,0,20)), GetBodyVelocity(fuselage)), 0.3)
				end
			end
			
			




			--PITCH
			
	
	----MOUSEAIM	



--shared.mouseaimPos
planerot=GetBodyAngularVelocity(fuselage)
planerottrans=TransformToLocalVec(GetBodyTransform(fuselage),planerot)
mouse_dir = QuatRotateVec(QuatLookAt(shared.FuselageTrans.pos, VecAdd(shared.mouseaimPos,Vec(0,100,0))), Vec(0, 0, -1))
mouse_steer=TransformToLocalVec(GetBodyTransform(fuselage), mouse_dir)	

local upVec = QuatRotateVec(GetBodyTransform(fuselage).rot, Vec(0,1,0))

-- Compare to world up (0,1,0)
local dot = VecDot(upVec, Vec(0,1,0))

-- Determine inverted state
local inverted = false
if dot < 0 then
    inverted = true
else
    inverted = false
end

if InputDown("a",shared.pilot) or InputDown("d",shared.pilot) then
mouseroll=planerottrans[3]
elseif mouse_steer[2]<-0.5 or mouse_steer[1]>0.6 or mouse_steer[1]<-0.6 then
mouseroll=-mouse_steer[1]*1.3
elseif mouse_steer[1]>0.1 or mouse_steer[1]<-0.1 and inverted==false and bank<0.8 and bank>-0.8 then
mouseroll=-mouse_steer[1]*1.3
else
if bank<-0.01 then
mouseroll=1
elseif bank>0.01 then
mouseroll=-1
else
mouseroll=-bank*5
end
end



		if shared.speed_vec>agility_vel and spinout_stopper==false then
		if shared.aoa_limiter==false then
		if WingRightHealth>0.7 and WingLeftHealth>0.7 and GetVehicleHealth(vehicle) > 0.6 then
				SetBodyAngularVelocity(fuselage, TransformToParentVec(GetBodyTransform(fuselage),Vec(mouse_steer[2]*1.5,-0.1*mouse_steer[1]+planerottrans[2],mouseroll)))
				end	
		else
			if mouse_steer[2]>0.4 then
		mouse_pitch=0.5
		elseif mouse_steer[2]<-0.4 then
		mouse_pitch=-0.5
		else
		mouse_pitch=mouse_steer[2]
		end
		if WingRightHealth>0.7 and WingLeftHealth>0.7 and GetVehicleHealth(vehicle) > 0.6 then
				SetBodyAngularVelocity(fuselage, TransformToParentVec(GetBodyTransform(fuselage),Vec(mouse_pitch*1.5,-0.1*mouse_steer[1]+planerottrans[2],mouseroll)))
		end	
		end
		rollRate = GetBodyAngularVelocity(fuselage)[3]



---END OF MOUSEAIM

			--YAW
				if InputDown("z",shared.pilot) and GetVehicleHealth(vehicle) > 0.6 then
				ApplyBodyImpulse(fuselage, tail, TransformToParentVec(GetBodyTransform(fuselage), Vec((yaw_force*rud*tl+yaw_force*shared.speed_vec*yaw_comp*rud*tl),0,0)) )
			elseif InputDown("x",shared.pilot) and GetVehicleHealth(vehicle) > 0.6 then
                ApplyBodyImpulse(fuselage, tail, TransformToParentVec(GetBodyTransform(fuselage), Vec((-yaw_force*rud*tl-yaw_force*shared.speed_vec*yaw_comp*rud*tl),0,0)) )
			end
			--ROLL
				if InputDown("a",shared.pilot) and GetVehicleHealth(vehicle) > 0.6 then
				ApplyBodyImpulse(fuselage, tip_r, TransformToParentVec(GetBodyTransform(fuselage), Vec(0,roll_force*WingRightHealth*ral,0)) )
				ApplyBodyImpulse(fuselage, tip_l, TransformToParentVec(GetBodyTransform(fuselage), Vec(0,-roll_force*WingLeftHealth*lal,0)) )
			elseif InputDown("d",shared.pilot) and GetVehicleHealth(vehicle) > 0.6 then
				ApplyBodyImpulse(fuselage, tip_r, TransformToParentVec(GetBodyTransform(fuselage), Vec(0,-roll_force*WingRightHealth*ral,0)) )
				ApplyBodyImpulse(fuselage, tip_l, TransformToParentVec(GetBodyTransform(fuselage), Vec(0,roll_force*WingLeftHealth*lal,0)) )

			end
	end
	
	
	
	
	











	

--guns

	

	
	
	

	
	
	--end
	--end of damage medium
end
--


--additional drag/stabilisation


--WIND COUNTERING

WindVel = GetWindVelocity(TransformToParentPoint(shared.FuselageTrans, Vec(0, 10, 0)))

WindSpeed=VecLength(WindVel)
--DebugWatch("Wind Speed ", WindSpeed)







		velocity_f = GetBodyVelocity(fuselage)
		bodyTrans_f = GetBodyTransform(fuselage)
		localVel_f = TransformToLocalVec(bodyTrans_f, velocity_f)
		air_speed_f = localVel_f[3]
		drag_force = -air_speed_f
		--DebugWatch("drag_force",drag_force)	
		--DebugWatch("drag_force", drag_force)
		
		
	if WindSpeed==0 then
SetEnvironmentProperty("wind", 0.01, 0, 0)
		
	else	
				if -air_speed_f < terminal_speed then
		ApplyBodyImpulse(fuselage,VecAdd(GetBodyCenterOfMass(fuselage),GetBodyTransform(fuselage).pos),TransformToParentVec(GetBodyTransform(fuselage), Vec(0,0,drag_force*air_drag*0.6)))	
		else 
		ApplyBodyImpulse(fuselage,VecAdd(GetBodyCenterOfMass(fuselage),GetBodyTransform(fuselage).pos),TransformToParentVec(GetBodyTransform(fuselage), Vec(0,0,drag_force*terminal_drag*0.6)))		
		end
				if shared.speed_vec>108 and shared.speed_vec<115 then
		ApplyBodyImpulse(fuselage,VecAdd(GetBodyCenterOfMass(fuselage),GetBodyTransform(fuselage).pos),TransformToParentVec(GetBodyTransform(fuselage), Vec(0,0,drag_force*terminal_drag*0.4*0.6)))	
		--DebugPrint("wave crisis+wind")
		end
		
		
	end


	--if air_speed_f > breakup_speed then
		--		Delete(crit1)
	--		Delete(crit2)
	--		Delete(crit3)
	--		Delete(crit4)
	--	end
			--prop pull

		pull = (shared.throttle * engine_power)

	
--vertical stabiliser stabilization
if damage_total==false then

		velocityT = GetBodyVelocity(fuselage, tail)
		tailTrans = GetBodyTransform(fuselage, tail)
		localVert = TransformToLocalVec(tailTrans, velocityT)
		side_speed= -localVert[1]
		
		--DebugWatch("side_speed", side_speed)
		--DebugWatch("stabforce", stabforce)
		
		
		vert_speed= -localVert[2]

	if spinout_stopper==false then			
	stabforce = side_speed * vertical_stabiliser_stabilisation *rud
				ApplyBodyImpulse(fuselage, tail, TransformToParentVec(GetBodyTransform(fuselage), Vec(stabforce, 0, 0)) )
end
--horizontal stabiliser stabilisation



--GYRO STABILISATION
if gyro>0 and shared.damage_medium==false then

GyroVecGlobal=GetBodyAngularVelocity(fuselage)
GyroVec = TransformToLocalVec(shared.FuselageTrans, GyroVecGlobal)

PitchVec = GyroVec[1]
--DebugWatch("RollVec", RollVec)
YawVec = GyroVec[2]
RollVec = GyroVec[3]


ApplyBodyImpulse(fuselage, tail, TransformToParentVec(GetBodyTransform(fuselage), Vec(0,(shared.speed_vec*PitchVec*gyro*tl), 0)) )

				ApplyBodyImpulse(fuselage, tip_r, TransformToParentVec(GetBodyTransform(fuselage), Vec(0,-RollVec*shared.speed_vec*gyro*0.07*WingRightHealth*WingLeftHealth,0)) )
				ApplyBodyImpulse(fuselage, tip_l, TransformToParentVec(GetBodyTransform(fuselage), Vec(0,RollVec*shared.speed_vec*gyro*0.07*WingLeftHealth*WingRightHealth,0)) )

end
--DebugWatch("vert_stabforce", vert_stabforce)
if spinout_stopper==false then
		vert_stabforce = vert_speed * horizontal_stabiliser_stabilisation *elev
				ApplyBodyImpulse(fuselage, tail, TransformToParentVec(GetBodyTransform(fuselage), Vec(0,vert_stabforce, 0)) )		
end





if shared.speed_vec>agility_vel then
		ApplyBodyImpulse(fuselage, tail, TransformToParentVec(GetBodyTransform(fuselage), Vec(0,pitch_trim*tl, 0)) )
end



end


--GENERAL DAMAGE SYSTEM--











--BIG AHH engine MANAGEMENT BLOCK OF CODE--
		--the ultimate engine solution according to chatGPT--
    for _, engine in ipairs(shared.engines) do
	shared.engine_body=GetShapeBody(engine)
			engine_something=TransformToParentPoint(GetBodyTransform(shared.engine_body), Vec(-0, 0, 0))
        -- Perform the set of commands for every engine independently
if burntime<0 then
 SetTag(shared.engine_body, "broken")
 end

        if shared.damage_medium == false and shared.activated and not HasTag(shared.engine_body, "broken") then
			
          		--  ApplyBodyImpulse(shared.engine_body, VecAdd(GetBodyCenterOfMass(shared.engine_body), GetBodyTransform(shared.engine_body).pos), TransformToParentVec(GetBodyTransform(shared.engine_body), Vec(0,0,pull)))
					ApplyBodyImpulse(shared.engine_body, engine_something, TransformToParentVec(GetBodyTransform(fuselage), Vec(0,0,-pull)) )
						if InputDown("ctrl",shared.pilot) and shared.throttle<0.1 and shared.speed_vec<2 then
							ApplyBodyImpulse(shared.engine_body, engine_something, TransformToParentVec(GetBodyTransform(fuselage), Vec(0,0,engine_power)) )
						end
			
					if shared.throttle>1 and HasTag(fuselage, "smoker") and HasTag(shared.engine_body, "broken")==false then
							for i=1, 10 do	
							ParticleReset()
							ParticleTile(5)
							ParticleType("plain")
							ParticleCollide(0)
							ParticleRadius(2, 0)
							ParticleDrag(rnd(0.1, 0.15))
							ParticleEmissive(0, 0)
							ParticleColor(0.2,0.2,0.2)
							ParticleGravity(rnd(0,0))
							ParticleAlpha(0.03, 0.06)		
			SpawnParticle(VecAdd(GetBodyTransform(shared.engine_body).pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))), TransformToParentVec(GetBodyTransform(shared.engine_body), Vec(rnd(-2,-2),rnd(-2,-2),-20+(-shared.throttle*50))), 3)
					end
					end
					
										if (shared.FuselageTrans.pos)[2]>320 and HasTag(shared.engine_body, "broken")==false then
			
							for i=1, 1 do	
							ParticleReset()
							ParticleTile(0)
							ParticleType("plain")
							ParticleCollide(0)
							ParticleRadius(3, 0)
							ParticleDrag(rnd(0.2, 0.3))
							ParticleEmissive(0, 0)
							ParticleColor(1,1,1)
							ParticleGravity(rnd(0,0))
							ParticleAlpha(0.02, 0.8)	
			SpawnParticle(VecAdd(GetBodyTransform(shared.engine_body).pos, Vec(rnd(-0.3,0.3),rnd(-0.3,0.2),rnd(-0.3,0.3))), TransformToParentVec(GetBodyTransform(shared.engine_body), Vec(rnd(-2,-2),rnd(-2,-2),-20+(-shared.throttle*50))), 15)
					end
					
			end
			
        end


		--airbrake InputDown("w")
		if shared.manned and InputDown("space",shared.pilot) and damage_total == false then	
			--ApplyBodyImpulse(shared.engine_body, VecAdd(GetBodyCenterOfMass(shared.engine_body), GetBodyTransform(shared.engine_body).pos), TransformToParentVec(GetBodyTransform(shared.engine_body), Vec(0,0,-brake_force*shared.speed_vec)))
			ApplyBodyImpulse(shared.engine_body, engine_something, TransformToParentVec(GetBodyTransform(fuselage), Vec(0,0,brake_force*shared.speed_vec)) )
		--DebugPrint("braking")
		end
			
		--shared.afterburner
		if shared.throttle > 2.4 and shared.damage_medium == false and shared.activated and shared.afterburner_strength>0 and HasTag(shared.engine_body, "broken")==false then
		ApplyBodyImpulse(shared.engine_body, VecAdd(GetBodyCenterOfMass(shared.engine_body), GetBodyTransform(shared.engine_body).pos), TransformToParentVec(GetBodyTransform(shared.engine_body), Vec(0,0,shared.afterburner_strength)))
		ApplyBodyImpulse(shared.engine_body, engine_something, TransformToParentVec(GetBodyTransform(fuselage), Vec(0,0,-shared.afterburner_strength)) )
		end



        local noise = shared.throttle * 1


        -- Find the joint tagged as 'prop' connected to the engine
        local prop = nil
        local joints = GetShapeJoints(engine)
        if joints then
            for _, joint in ipairs(joints) do
                if HasTag(joint, "prop") then
                    prop = joint
                    break
                end
            end
        end
					
					if HasTag(shared.engine_body, "broken")==true or burntime<0 then
			   Delete(prop)
				end
				if HasTag(fuselage,"downed") and shared.damage_medium==true then
				Delete(prop)
				end
				
        if prop then
            if shared.activated and shared.cooldown < 3 and not HasTag(shared.engine_body, "broken") then
                SetJointMotor(prop, 8.5 * shared.cooldown)
            end

            if not shared.activated and not initial and shared.cooldown < 3 then
                SetJointMotor(prop, 8.5 * (3 - shared.cooldown))
				
            end
        end
    end


--end of the epic ultimate solution


 
  if GetVehicleHealth(vehicle) < 0.3 then


 		for i=1,#joint_crits do 
		local joint_crit = joint_crits[i]
		Delete(joint_crit)
		end
		end
		
   
    if GetVehicleHealth(vehicle) < 0.8 then
 			Delete(coupler)
end

	if detonated then
	burntime=burntime - dt
	end

	
	
	
	
	---GUNS
	
	
	
	
	local newProjectiles = {}
	for i, p in ipairs(projectiles) do
		p.pos = VecAdd(p.pos, VecScale(p.dir, projectileSpeed * dt))
		p.life = p.life - dt

        local projectileWet, projectileDepth = IsPointInWater(p.pos)
        if projectileWet and projectileDepth < 0.5 and projectileDepth > -0.5 then
                for i = 1, 20 do
                    ParticleReset()
                    ParticleTile(5)
                    ParticleType("plain")
                    ParticleCollide(0)
                    ParticleRadius(1, 2)
                    ParticleDrag(rnd(0.2, 1))
                    ParticleEmissive(0, 0)
                    ParticleColor(.9, .9, .9)
                    ParticleGravity(rnd(-5, -9))
                    ParticleAlpha(1, 0)
                    SpawnParticle(p.pos, Vec(rnd(-2, 2), rnd(0, 60), rnd(-2, 2)), 2)
                    PlaySound(LoadSound("MOD/main/aircraft/Sounds/splash.ogg"), p.pos, 5)
                end
        end

        local hit, dist, normal, shape = QueryRaycast(p.pos, p.dir, projectileSpeed * dt)
 		if hit and GetShapeMaterialAtPosition(shape, VecAdd(p.pos, VecScale(p.dir, dist)))=="glass" and HasTag(shape,"trunk")==false then
		PaintRGBA(VecAdd(p.pos, VecScale(p.dir, dist)), (rnd(30, 45) / 200), 0.7, 0.7, 0.7, 1, (rnd(0, 10) / 8))
		MakeHole(VecAdd(p.pos, VecScale(p.dir, dist)), p.dmg, p.dmg, 0)
					for i=1, 30 do
                        ParticleReset()
                        ParticleGravity(rnd(-2, -8))
                        ParticleRadius(math.random(6, 10) * .002, 0.0, "smooth")
                        ParticleColor(0.95,0.95,0.95)
                        ParticleTile(4)
                        ParticleDrag(rnd(0.2,0.5))
                        ParticleCollide(0, 1, "easeout")
                        SpawnParticle(VecAdd(p.pos, VecScale(p.dir, dist)), VecScale(VecAdd(p.dir,Vec(rnd(-0.2,0.2),rnd(-0.2,0.2),rnd(-0.2,0.2))),rnd(-1,-3)), 3)
						                        ParticleReset()
                        ParticleGravity(0)
                        ParticleRadius(math.random(4, 8) * .01,math.random(6, 12) * .02, "smooth")
                        ParticleColor(0.95,0.95,0.95)
						ParticleAlpha(0.3,0)
                        ParticleTile(0)
                        ParticleDrag(0, 0.2)
                        ParticleCollide(0, 1, "easeout")
                        SpawnParticle(VecAdd(p.pos, VecScale(p.dir, dist)), VecScale(p.dir,rnd(-1,-2)), 0.3)
			end
		end
		
		

        if hit and GetShapeMaterialAtPosition(shape, VecAdd(p.pos, VecScale(p.dir, dist)))~="glass" then
            local hitPos = VecAdd(p.pos, VecScale(p.dir, dist))
            local material = GetShapeMaterialAtPosition(shape, hitPos)
            local hitbody = GetShapeBody(shape)
            local damage = (100)
            --CALLOUT FOR TABS NPC

            SendToListener(
                {
                    {
                        FunctionName = "RecieveHitData",
                        Arguments = {
                            {"Number", GetEntityParent(hitbody, "", "animator")},
                            {"Vec", hitPos},
                            {"String", GetTagValue(hitbody, "bone")},
                            {"Number", damage}
                        }
                    }
                },
                "TABS NPC Listener"
            )
			--check for living tissue

npcDamage(hitbody,p.dmg*400,hitPos,p.dir)



            if material == "metal" then
			PointLight(hitPos, 1, 0.8, 0.6, 5)
			PlaySound(LoadSound("MOD/Dynamic-Aircraft/Snd/blt_imp_metal_auto_0.ogg"), hitPos, 5)

			Paint(hitPos, (rnd(30,45)/100), "explosion", (rnd(0,10)/8))

			
						for i=1, 20 do				
				--dust
								ParticleReset()
				ParticleTile(5)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(0.5, 1)
					ParticleDrag(rnd(0,0.2))
					ParticleEmissive(0, 0)
					ParticleColor(.5,.5,.5)
					ParticleGravity(rnd(-0.7,0.5))
					ParticleAlpha(0.7, 0)
				SpawnParticle(hitPos, Vec(rnd(-1,1),rnd(-1,1),rnd(-1,1)),1.5)	
		--spark
				            ParticleReset()
			ParticleEmissive(1, 0, "easein")
			ParticleGravity(rnd(-2,-8))
			ParticleRadius(math.random(6, 10)*.01, 0.0, "smooth") 
			ParticleColor(0.8,.7,0.5, 0.6,.1,0)  
			ParticleTile(4)
			ParticleDrag(0, 0.2)
			ParticleCollide(0, 1, "easeout")
				SpawnParticle(hitPos, Vec(rnd(-10,10),rnd(-10,10),rnd(-10,10)),0.5)	
				end
		
		
        	elseif material == "heavymetal" then
			PaintRGBA(hitPos,(rnd(30,45)/100), 0.7,0.7,0.7,1, (rnd(0,10)/8))
			PlaySound(LoadSound("MOD/Dynamic-Aircraft/Snd/blt_imp_metal_auto_0.ogg"), hitPos, 5)
			PointLight(hitPos, 1, 0.8, 0.6, 5)
						for i=1, 20 do				
				--dust
								ParticleReset()
				ParticleTile(5)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(0.5, 1)
					ParticleDrag(rnd(0,0.2))
					ParticleEmissive(0, 0)
					ParticleColor(.5,.5,.5)
					ParticleGravity(rnd(-0.7,0.5))
					ParticleAlpha(0.7, 0)
				SpawnParticle(hitPos, Vec(rnd(-1,1),rnd(-1,1),rnd(-1,1)),1.5)	
		--spark
				            ParticleReset()
			ParticleEmissive(1, 0, "easein")
			ParticleGravity(rnd(-2,-8))
			ParticleRadius(math.random(6, 10)*.01, 0.0, "smooth") 
			ParticleColor(0.8,.7,0.5, 0.6,.1,0)  
			ParticleTile(4)
			ParticleDrag(0, 0.2)
			ParticleCollide(0, 1, "easeout")
				SpawnParticle(hitPos, Vec(rnd(-10,10),rnd(-10,10),rnd(-10,10)),0.5)	

		end
			elseif material == "hardmetal" then
			PaintRGBA(hitPos,(rnd(30,45)/100), 0.7,0.7,0.7,1, (rnd(0,10)/8))
			PlaySound(LoadSound("MOD/Dynamic-Aircraft/Snd/blt_imp_metal_auto_0.ogg"), hitPos, 5)
			PointLight(hitPos, 1, 0.8, 0.6, 5)
						for i=1, 20 do				
				--dust
								ParticleReset()
				ParticleTile(5)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(0.5, 1)
					ParticleDrag(rnd(0,0.2))
					ParticleEmissive(0, 0)
					ParticleColor(.5,.5,.5)
					ParticleGravity(rnd(-0.7,0.5))
					ParticleAlpha(0.7, 0)
				SpawnParticle(hitPos, Vec(rnd(-1,1),rnd(-1,1),rnd(-1,1)),1.5)	
		--spark
				            ParticleReset()
			ParticleEmissive(1, 0, "easein")
			ParticleGravity(rnd(-2,-8))
			ParticleRadius(math.random(6, 10)*.01, 0.0, "smooth") 
			ParticleColor(0.8,.7,0.5, 0.6,.1,0) 
			ParticleTile(4)
			ParticleDrag(0, 0.2)
			ParticleCollide(0, 1, "easeout")
				SpawnParticle(hitPos, Vec(rnd(-10,10),rnd(-10,10),rnd(-10,10)),0.5)	
	
		end
			elseif material == "concrete" or material == "rock" or material == "masonry" then
				PointLight(hitPos, 1, 0.8, 0.6, 5)
				PlaySound(LoadSound("explosion//m5.ogg"), hitPos, 5)
				for i=1, 5 do
												ParticleReset()
				ParticleTile(0)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(0.5, 1.5)
					ParticleDrag(rnd(0,0.2))
					ParticleEmissive(0, 0)
					ParticleColor(.5,.5,.5)
					ParticleGravity(rnd(-0.7,0.5))
					ParticleAlpha(0.7, 0)
				SpawnParticle(hitPos, Vec(rnd(-1.5,1.5),rnd(-1,2),rnd(-1.5,1.5)),1.5)
				ParticleTile(5)
				ParticleDrag(rnd(0,2))
				SpawnParticle(hitPos, Vec(rnd(-10,10),rnd(-1,10),rnd(-10,10)),0.5)
				end
			elseif material == "dirt" then
			for i=1, 5 do
				ParticleReset()
				ParticleTile(0)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(0.5, 2)
					ParticleDrag(rnd(0,0.7))
					ParticleEmissive(0, 0)
					ParticleColor(.6,.5,.4)
					ParticleGravity(rnd(-0.7,0.5))
					ParticleAlpha(0.7, 0)
				SpawnParticle(hitPos, Vec(rnd(-2,2),rnd(-1,2),rnd(-2,2)),3)
				ParticleTile(5)
				ParticleDrag(rnd(0,5))
				SpawnParticle(hitPos, Vec(rnd(-8,8),rnd(-1,15),rnd(-8,8)),0.5)
				
															ParticleReset()
				ParticleTile(5)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(1, 2)
					ParticleDrag(rnd(0.5,1))
					ParticleEmissive(0, 0)
					ParticleColor(.6,.5,.4)
					ParticleGravity(rnd(-7,-9))
					ParticleAlpha(0.7, 0)
				SpawnParticle(hitPos, Vec(rnd(-2,2),rnd(0,50),rnd(-2,2)),2)
				
				
				end
			end





			if p.dmg == damageCannon then
				MakeHole(hitPos, p.dmg, p.dmg, p.dmg * 0.3)
			else
				MakeHole(hitPos, p.dmg, p.dmg, 0)
			end

			if material ~= "heavymetal" and material ~= "foliage" and material ~= "hardmetal" and material ~= "concrete" and material ~= "dirt" and material ~= "rock" and material ~= "masonry" then
				local penetrationLength = penetrationLengthMG
				local penetrationDamage = p.dmg * 0.8
				for i = 1, penetrationLength do
					local penetrationPos = VecAdd(hitPos, VecScale(p.dir, (i / 10)))
					MakeHole(penetrationPos, penetrationDamage, penetrationDamage, 0)
				end
			end
		else
			if p.life > 0 then
				table.insert(newProjectiles, p)
				DrawLine(p.pos, VecSub(p.pos, VecScale(p.dir, 3)), p.color[1], p.color[2], p.color[3])
			end
		end
	end
	projectiles = newProjectiles
end

function client.update()

    -- missile lock alarm (client-local sound)
    if shared.missile_alert == true
    and HasTag(fuselage, "downed") == false
    and shared.manned == true then
        PlayLoop(client.lock_alarm, shared.FuselageTrans.pos, 20)
    end

    for _, engine in ipairs(shared.engines) do

        local engine_body = GetShapeBody(engine)

        -- afterburner
        if shared.throttle > 2.4
        and shared.damage_medium == false
        and shared.activated
        and shared.afterburner_strength > 0
        and HasTag(engine_body, "broken") == false then

            PlayLoop(client.afterburner, GetBodyTransform(engine_body).pos, 20)

            for i = 1, 10 do
                ParticleReset()
                ParticleTile(5)
                ParticleType("plain")
                ParticleCollide(0)
                ParticleRadius(0.4, 0)
                ParticleDrag(0.5)
                ParticleEmissive(1, 1)
                ParticleColor(1, .5, .5, 1, .5, .3)
                ParticleGravity(0)
                ParticleAlpha(0.9, 0)

                SpawnParticle(
                    VecAdd(
                        GetBodyTransform(engine_body).pos,
                        Vec(rnd(-0.3,0.3), rnd(-0.3,0.2), rnd(-0.3,0.3))
                    ),
                    TransformToParentVec(
                        GetBodyTransform(engine_body),
                        Vec(0, 0, -50)
                    ),
                    0.15
                )

                PointLight(GetBodyTransform(engine_body).pos, 255, .20, .0130, 2)
            end
        end

        local noise = shared.throttle

        if shared.cooldown > 15 then

            if shared.activated
            and not shared.damage_medium
            and HasTag(engine_body, "broken") == false then
                PlayLoop(
                    client.idlesound,
                    GetBodyTransform(engine_body).pos,
                    (10 - shared.throttle * 3) * 5,
                    true,
                    1 + shared.throttle * 0.15
                )
            end

            if shared.throttle > 0.1
            and shared.activated
            and not shared.damage_medium
            and HasTag(engine_body, "broken") == false then
                PlayLoop(
                    client.enginesound,
                    GetBodyTransform(engine_body).pos,
                    noise * 6,
                    true,
                    0.8 + shared.throttle * 0.25
                )
            end

        else

            if shared.activated
            and not shared.damage_medium
            and HasTag(engine_body, "broken") == false then
                PlayLoop(
                    client.idlesound,
                    GetBodyTransform(engine_body).pos,
                    (10 - shared.throttle * 3) * 5 * 0.0044 * shared.cooldown * shared.cooldown,
                    true,
                    1 + shared.throttle * 0.15
                )
            end

            if shared.throttle > 0.1
            and shared.activated
            and not shared.damage_medium
            and HasTag(engine_body, "broken") == false then
                PlayLoop(
                    client.enginesound,
                    GetBodyTransform(engine_body).pos,
                    noise * 6 * 0.0044 * shared.cooldown * shared.cooldown,
                    true,
                    0.8 + shared.throttle * 0.25
                )
            end
        end
    end
end
		
function server.tick(dt)
											for i=1,#rudder_joints do 
					local rudder_joint = rudder_joints[i]	
				ruddermin, ruddermax = GetJointLimits(rudder_joint)
				end
				aileronmin, aileronmax = GetJointLimits(aileron_L_joint)
				
										for i=1,#elevator_joints do 
					local elevator_joint = elevator_joints[i]	
				elevatormin, elevatormax = GetJointLimits(elevator_joint)
end





		vehicle = FindVehicle("plane")
		
		
shared.manned = false
shared.pilot = nil
local players = GetAllPlayers()

for i = 1, #players do
    local p = players[i]
    if IsPlayerValid(p) then
        if IsPlayerVehicleDriver(vehicle, p) then
            shared.manned = true
			shared.pilot=p
        end
    end
end




---aoa limiter button
if InputPressed("t",shared.pilot) and shared.manned then
if shared.aoa_limiter==true then
shared.aoa_limiter=false
shared.aoa_timer=1
else
shared.aoa_limiter=true
shared.aoa_timer=1
end
end

if shared.activated and shared.cooldown<3 then
starter=true
else
starter=false
already_started=false
end

if starter==true then
--DebugPrint("starter")
if already_started==false then
if HasTag(fuselage, "propplane") then
PlaySound(LoadSound("MOD/Dynamic-Aircraft/Snd/aircraft-sfx/startup_prop.ogg"), GetBodyTransform(fuselage).pos, 20, false)
else 
PlaySound(LoadSound("MOD/Dynamic-Aircraft/Snd/aircraft-sfx/startup_jet.ogg"), GetBodyTransform(fuselage).pos, 20, false)
end

already_started=true
end

				 		for i=1,#exhausts do 
					local exhaust = exhausts[i]
					exhaustt = GetLightTransform(exhaust)					
					exhaust_random=rnd(0,100)
		--DebugWatch("exhaust_random",exhaust_random)
					
	
	if exhaust_random<3 then
				for i=1, 40 do
				ParticleReset()
				ParticleTile(5)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(0.1, 0.2)
					ParticleDrag(rnd(0.05, 1))
					ParticleEmissive(2, 2)
					ParticleColor(1,.5,.5, 1,.5,.3)
					ParticleGravity(rnd(4,7))
					ParticleAlpha(0.5, 0)
				SpawnParticle(VecAdd(exhaustt.pos, Vec(rnd(-0.05,0.05),rnd(-0.05,0.05),rnd(-0.05,0.05))),VecAdd(TransformToParentVec(exhaustt, Vec(rnd(0.1,0.1),rnd(0.1,0.1),rnd(2,3))), GetBodyVelocity(fuselage)), 0.15)
				end
								for i=1, 40 do
				ParticleReset()
				ParticleTile(1)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(0.2, 1)
					ParticleDrag(rnd(0.05, 0.6))
					ParticleEmissive(0, 0)
					ParticleColor(0.9, 0.9, 0.9)
					ParticleGravity(rnd(1,3))
					ParticleAlpha(0.2, 0.05)
				SpawnParticle(VecAdd(exhaustt.pos, Vec(rnd(-0.05,0.05),rnd(-0.05,0.05),rnd(-0.05,0.05))),VecAdd(TransformToParentVec(exhaustt, Vec(rnd(0.1,0.1),rnd(0.1,0.1),rnd(2,3))), GetBodyVelocity(fuselage)), 1.5)
			
end
end







end
end






if not shared.manned then
					local missilepoint = missilepoints[currentMissileIndex]
			local missile = shared.missiles[currentMissileIndex]
			RemoveTag(missile,"seeking")
			
end

if shared.manned then

--SWITCH CAMERA
--CameraMode


if HasTag(fuselage,"downed")==false then
SetJointMotor(dish, 1)
else
SetJointMotor(dish, 0)
end
		--START/STOP
		if InputPressed("f",shared.pilot) and not shared.activated and shared.cooldown>3 then
		SetTag(fuselage,"letsgo")		
		shared.activated=true
		initial=false
		shared.cooldown=0	
		end
		
		if InputPressed("f",shared.pilot) and shared.activated and shared.cooldown>3 then
			 shared.activated=false
			 shared.cooldown=0
			 end
			 
		--GEAR OUT/in



		if InputPressed("g",shared.pilot) and gear_out and gearcooldown>3 then
			 gear_in=true
			 gear_out=false
			 gearcooldown=0
			 end
			 
		if InputPressed("g",shared.pilot) and gear_in and gearcooldown>3 then
		gear_out=true
		gear_in=false
		gearcooldown=0
		end	 
			 
			


		if InputPressed("l",shared.pilot) and lightstate<2 then
lightstate=lightstate+1
		elseif InputPressed("l",shared.pilot) then
		lightstate=0
		end




--	SetJointMotorTarget(rudder_joint, ruddermin, 200)	
			
					--	SetJointMotorTarget(elevator_joint,mousey*elevatormax*0.02, 15) 
		--	SetJointMotorTarget(aileron_L_joint,mousex*aileronmax*0.02, 15) 
		--	SetJointMotorTarget(aileron_R_joint,-mousex*aileronmax*0.02, 15) 
		--	SetJointMotorTarget(rudder_joint,-mousex*aileronmax*0.002, 15) 
			
		
	if ChaseCam==false then	
		
		
						for i=1,#elevator_joints do 
					local elevator_joint = elevator_joints[i]	
		if mouse_steer[2]>0 and damage_total==false then
			SetJointMotorTarget(elevator_joint,-elevatormin*mouse_steer[2]*2, 7)			
		elseif mouse_steer[2]<0 and damage_total==false then	
			SetJointMotorTarget(elevator_joint,elevatormax*mouse_steer[2]*2, 7)
			else			
			SetJointMotorTarget(elevator_joint, 0, 7)
			end
		end	
			
									for i=1,#rudder_joints do 
					local rudder_joint = rudder_joints[i]	
		if InputDown("z",shared.pilot) and damage_total==false then
			SetJointMotorTarget(rudder_joint,ruddermax, 7)
		elseif InputDown("x",shared.pilot) and damage_total==false then
			SetJointMotorTarget(rudder_joint,ruddermin, 7)
			else
			SetJointMotorTarget(rudder_joint, 0, 7)
			end	
		end	
			

		if InputDown("a",shared.pilot) and damage_total==false then
			SetJointMotorTarget(aileron_R_joint,aileronmin, 7)
			SetJointMotorTarget(aileron_L_joint,aileronmax, 7)			
		elseif InputDown("d",shared.pilot) and damage_total==false then
			SetJointMotorTarget(aileron_L_joint,aileronmin, 7)
			SetJointMotorTarget(aileron_R_joint,aileronmax, 7)			
			else
			SetJointMotorTarget(aileron_R_joint, 0, 7)
			SetJointMotorTarget(aileron_L_joint, 0, 7)
			
			end						
		end	 
 
	--GUNS		 
	
	
	
	if InputDown("c",shared.pilot) and (speedflare > timerflare) and GetVehicleHealth(vehicle) > 0.6 and shared.manned then
		SetTag(fuselage,"fl")
	
	
				 		for i=1,#flares do 
					local flare = flares[i]
					PlaySound(LoadSound("MOD/Dynamic-Aircraft/Snd/aircraft-sfx/flare.ogg"), GetLightTransform(flare).pos, 5, false)
					ftt = GetLightTransform(flare)					
					ffwd = TransformToParentVec(ftt,Vec(0, -1, 0))																									
				--	Shoot(tt.pos, ffwd, "bullet", ".25", "300" )
		
					speedflare=0
	
	
				for i=1, 40 do
				ParticleReset()
				ParticleTile(5)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(0.2, 0.3)
					ParticleDrag(rnd(0.05, 0.05))
					ParticleEmissive(2, 2)
					ParticleColor(.9,.5,.3)
					ParticleGravity(rnd(-9,-9))
					ParticleAlpha(0.8, 0)
				SpawnParticle(VecAdd(ftt.pos, Vec(rnd(-0.05,0.05),rnd(-0.05,0.05),rnd(-0.05,0.05))),VecAdd(TransformToParentVec(ftt, Vec(0,0,30)), GetBodyVelocity(fuselage)), 6)
				end	
				
				for i=1, 40 do
				ParticleReset()
				ParticleTile(1)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(0.5, 1)
					ParticleDrag(rnd(0.05, 0.9))
					ParticleEmissive(0, 0)
					ParticleColor(0.8, 0.8, 0.8)
					ParticleGravity(0)
					ParticleAlpha(1, 0.5)
				SpawnParticle(VecAdd(ftt.pos, Vec(rnd(-0.05,0.05),rnd(-0.05,0.05),rnd(-0.05,0.05))),VecAdd(TransformToParentVec(ftt, Vec(0,0,30)), GetBodyVelocity(fuselage)), 10)
				end	
	
	
	end
	
	end
	
	
	
	
			if InputDown("r",shared.pilot) and (speedrocket > timerrocket) and GetVehicleHealth(vehicle) > 0.6 and shared.manned and shared.missile_mode==false then

						 		for i=1,#launcherpoints do 
					local launcherpoint = launcherpoints[i]
			if HasTag(launcherpoint,"rocket_s") then
Spawn("MOD/Dynamic-Aircraft/Aircraft/Weaponry/rocket_sA.xml", GetLightTransform(launcherpoint), false, true)
elseif HasTag(launcherpoint,"rocket_m") then
Spawn("MOD/Dynamic-Aircraft/Aircraft/Weaponry/rocket_mA.xml", GetLightTransform(launcherpoint), false, true)
		end	
			
					launchedrockets=FindShapes("launched_rocket")
					


						 		for i=1,#launchedrockets do 
					local launchedrocket = launchedrockets[i]
					RemoveTag(launchedrocket, "launched_rocket")
				RemoveTag(launchedrocket, "unbreakable")
				SetTag(launchedrocket, "fired")
				SetTag(launchedrocket, "armed")
				SetBodyVelocity(GetShapeBody(launchedrocket),GetBodyVelocity(fuselage))	
					end
			
			
			
			speedrocket=0
			end
		end	
	
			if InputDown("r",shared.pilot) and (speedbarrage > timerbarrage) and GetVehicleHealth(vehicle) > 0.6 and shared.manned and shared.missile_mode==false then
			
									 		for i=1,#barragepoints do 
					local barragepoint = barragepoints[i]
			
			if HasTag(barragepoint,"rocket_s") then
Spawn("MOD/Dynamic-Aircraft/Aircraft/Weaponry/rocket_sA.xml", GetLightTransform(barragepoint), false, true)
elseif HasTag(barragepoint,"rocket_m") then
Spawn("MOD/Dynamic-Aircraft/Aircraft/Weaponry/rocket_mA.xml", GetLightTransform(barragepoint), false, true)
elseif HasTag(barragepoint,"rocket_g") then
Spawn("MOD/Dynamic-Aircraft/Aircraft/Weaponry/grippen_rocket.xml", GetLightTransform(barragepoint), false, true)
		end	

					launchedrockets=FindShapes("launched_rocket")
					


						 		for i=1,#launchedrockets do 
					local launchedrocket = launchedrockets[i]
					RemoveTag(launchedrocket, "launched_rocket")
				RemoveTag(launchedrocket, "unbreakable")
				SetTag(launchedrocket, "fired")
				SetTag(launchedrocket, "armed")
				SetBodyVelocity(GetShapeBody(launchedrocket),GetBodyVelocity(fuselage))	
					end
			
			
			
			speedbarrage=0
			end
		end		
	
	
	
	
			 
		if InputDown("lmb",shared.pilot) and jammed==false and (speedmg > timermg) and GetVehicleHealth(vehicle) > 0.6 and shared.manned then

			 		for i=1,#mgs do 
					local mg = mgs[i]
					PlaySound(LoadSound("tools/rifle1.ogg"), GetLightTransform(mg).pos, 5, false)
					tt = GetLightTransform(mg)																														
					fwd = TransformToParentVec(tt,Vec(rnd(-0.01,0.01), -1, rnd(-0.01,0.01)))	

				SpawnProjectile(tt.pos, fwd, {1, 0.8, 0.5}, damageMG)

					
					speedmg=0
					
					
					
					
					
				for i=1, 40 do
				ParticleReset()
				ParticleTile(1)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(0.2, 0.6)
					ParticleDrag(rnd(0.05, 0.6))
					ParticleEmissive(0, 0)
					ParticleColor(0.6, 0.6, 0.6)
					ParticleGravity(rnd(1,3))
					ParticleAlpha(0.2, 0)
				SpawnParticle(VecAdd(tt.pos, Vec(rnd(-0.05,0.05),rnd(-0.05,0.05),rnd(-0.05,0.05))),VecAdd(TransformToParentVec(GetBodyTransform(fuselage), Vec(0,0,20)), GetBodyVelocity(fuselage)), 3)
				end
					
				for i=1, 40 do
				ParticleReset()
				ParticleTile(5)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(0.1, 0.3)
					ParticleDrag(rnd(0.05, 0.8))
					ParticleEmissive(2, 2)
					ParticleColor(.9,.5,.3)
					ParticleGravity(rnd(1,3))
					ParticleAlpha(0.8, 0)
				SpawnParticle(VecAdd(tt.pos, Vec(rnd(-0.05,0.05),rnd(-0.05,0.05),rnd(-0.05,0.05))),VecAdd(TransformToParentVec(GetBodyTransform(fuselage), Vec(0,0,20)), GetBodyVelocity(fuselage)), 0.1)
				end	

					
					
					
					
					
					
					
					
		end	 
		
		
		
		
		end	 
			 
		if InputDown("lmb",shared.pilot) and jammed==false and (speedcannon > timercannon) and GetVehicleHealth(vehicle) > 0.6 and shared.manned then

					for i=1,#cannons do 
					local cannon = cannons[i]
					PlaySound(LoadSound("tools/shotgun1.ogg"), GetLightTransform(cannon).pos, 5, false)
					ct = GetLightTransform(cannon)																														
					fwd = TransformToParentVec(ct,Vec(rnd(-0.01,0.01), -1, rnd(-0.01,0.01)))


				SpawnProjectile(ct.pos, fwd, {0.9, 1, 0.5}, damageCannon)

					
					speedcannon = 0
					
				for i=1, 40 do
				ParticleReset()
				ParticleTile(1)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(0.35, 0.8)
					ParticleDrag(rnd(0.05, 0.6))
					ParticleEmissive(0, 0)
					ParticleColor(0.6, 0.6, 0.6)
					ParticleGravity(rnd(1,3))
					ParticleAlpha(0.2, 0)
				SpawnParticle(VecAdd(ct.pos, Vec(rnd(-0.05,0.05),rnd(-0.05,0.05),rnd(-0.05,0.05))),VecAdd(TransformToParentVec(GetBodyTransform(fuselage), Vec(0,0,20)), GetBodyVelocity(fuselage)), 4)
				end
					
				for i=1, 40 do
				ParticleReset()
				ParticleTile(5)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(0.25, 0.5)
					ParticleDrag(rnd(0.05, 0.8))
					ParticleEmissive(2, 2)
					ParticleColor(.9,.5,.3)
					ParticleGravity(rnd(1,3))
					ParticleAlpha(0.8, 0)
				SpawnParticle(VecAdd(ct.pos, Vec(rnd(-0.05,0.05),rnd(-0.05,0.05),rnd(-0.05,0.05))),VecAdd(TransformToParentVec(GetBodyTransform(fuselage), Vec(0,0,20)), GetBodyVelocity(fuselage)), 0.15)
				end	
					
					
					
					
					
					
					
					
					
					
					
					
					
					end
					

					
					
					
					
					
					
					
					
					
					
					
					
					
					
		end

		if InputDown("lmb",shared.pilot) and jammed==false and (speedrotary > timerrotary) and GetVehicleHealth(vehicle) > 0.6 and shared.manned then
					for i=1,#rotarys do 
					local rotary = rotarys[i]
					PlaySound(LoadSound("tools/gun1.ogg"), GetLightTransform(rotary).pos, 5, false)
					rtt = GetLightTransform(rotary)																														
					fwd = TransformToParentVec(rtt,Vec(rnd(-0.005,0.005), -1, rnd(-0.005,0.005)))	


SpawnProjectile(rtt.pos, fwd, {1, 0.6, 0.6}, damageRotary)

					
					speedrotary = 0
					
					
									for i=1, 40 do
				ParticleReset()
				ParticleTile(1)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(0.2, 0.6)
					ParticleDrag(rnd(0.05, 0.6))
					ParticleEmissive(0, 0)
					ParticleColor(0.6, 0.6, 0.6)
					ParticleGravity(rnd(1,3))
					ParticleAlpha(0.2, 0)
				SpawnParticle(VecAdd(rtt.pos, Vec(rnd(-0.05,0.05),rnd(-0.05,0.05),rnd(-0.05,0.05))),VecAdd(TransformToParentVec(GetBodyTransform(fuselage), Vec(0,0,20)), GetBodyVelocity(fuselage)), 3)
				end
					
				for i=1, 40 do
				ParticleReset()
				ParticleTile(5)
				ParticleType("plain")
				ParticleCollide(0)
					ParticleRadius(0.1, 0.3)
					ParticleDrag(rnd(0.05, 0.8))
					ParticleEmissive(2, 2)
					ParticleColor(.9,.5,.3)
					ParticleGravity(rnd(1,3))
					ParticleAlpha(0.8, 0)
				SpawnParticle(VecAdd(rtt.pos, Vec(rnd(-0.05,0.05),rnd(-0.05,0.05),rnd(-0.05,0.05))),VecAdd(TransformToParentVec(GetBodyTransform(fuselage), Vec(0,0,20)), GetBodyVelocity(fuselage)), 0.1)
				end					
					end		
		end





	--RELOAD MECHANICS
	--1 reload trigger 'h for now'
	--2 set fuselage tag for reload
	
	--3 delete all tagged orndance
	--4 spawn in new ordnance
	--5 remove tag from fuselagew
	
	--6 also make ot for intitial launch to keep consistency
	--weapon_transform=GetLightTransform(weapon)

--if pilot_model==1 then
--Spawn("MOD/Dynamic-Aircraft/Aircraft/Weaponry/bomb250.xml", bailout)



supplies=FindBodies("supplies",true)
for _, supply in ipairs(supplies) do
if InputPressed("h",shared.pilot) then
if VecLength(VecSub(shared.FuselageTrans.pos,GetBodyTransform(supply).pos))>10 then
elseif shared.speed_vec<1 then
SetTag(fuselage,"rld")
PlaySound(reloadSnd,shared.FuselageTrans.pos,1)
end
end
end
				CenterDistance=VecSub(Vec(0,0,0),shared.FuselageTrans.pos)
		CenterMapDistance=VecLength(Vec(CenterDistance[1],0,CenterDistance[3]))
if CenterMapDistance>2500 and InputPressed("h",shared.pilot) then
SetTag(fuselage,"rld")
PlaySound(reloadSnd)
end



if HasTag(fuselage,"rld") then
if not HasTag(fuselage,"downed") then
---------------------PLAY RELOAD SOUND
--UnwantedWeapons
waterbomb_timer=1.5

 UnwantedWeapons = QueryAabbBodies(VecAdd(GetBodyTransform(fuselage).pos, Vec(-5, -5, -5)), VecAdd(GetBodyTransform(fuselage).pos, Vec(5, 5, 5)))

			 		for i=1,#UnwantedWeapons do 
				local UnwantedWeapon = UnwantedWeapons[i]
				if HasTag(UnwantedWeapon,"weapon") then
				Delete(UnwantedWeapon)
				end
					end	
					
					
			--SPAWN IN WEAPONS		
				            for _, weapon in ipairs(weapons) do
			weapon_transform=GetLightTransform(weapon)
			--DebugCross(floatTrans.pos)	
	
---ORDNANCE LIST
--shared.missiles
if HasTag(weapon,"missile1") then
Spawn("MOD/Dynamic-Aircraft/Aircraft/Weaponry/missile_1P.xml", weapon_transform, false, true)
elseif HasTag(weapon,"missile2") then
Spawn("MOD/Dynamic-Aircraft/Aircraft/Weaponry/missile_2P.xml", weapon_transform, false, true)
elseif HasTag(weapon,"missileR") then
Spawn("MOD/Dynamic-Aircraft/Aircraft/Weaponry/missile_RP.xml", weapon_transform, false, true)
elseif HasTag(weapon,"missileG") then
Spawn("MOD/Dynamic-Aircraft/Aircraft/Weaponry/grippen_missile.xml", weapon_transform, false, true)
--end of ordnance list
end
end
			--REGISTER NEW WEAPONS

		dumbbombs=FindShapes("new_bomb")
		rockets=FindShapes("new_rocket")	
		shared.missiles=FindBodies("new_missile")

	
		currentBombIndex = 1
		currentHardpointIndex = 1
		currentRocketIndex = 1
		currentMissileIndex = 1


						 		for i=1,#dumbbombs do 
					local dumbbomb = dumbbombs[i]
					RemoveTag(dumbbomb, "new_bomb")
					end

								for i=1,#rockets do 
					local rocket = rockets[i]
					RemoveTag(rocket, "new_rocket")
					end
					
								for i=1,#shared.missiles do 
					local missile = shared.missiles[i]
					RemoveTag(missile, "new_missile")
					end
					




end
shared.missile_count=#shared.missiles
RemoveTag(fuselage,"rld")
end







		

--end


	--ORDNANCE

		if InputPressed("q",shared.pilot) and shared.manned then
		bombbay_timer=0
		
		if waterbomb_timer>0 then
		waterbomb=true
		end
		
		
		
		if drop==false then
		for _, dropdoor in ipairs(dropdoors) do
		SetTag(dropdoor,"open")
		end
		end
		
		
		drop=true
		
		
		
						 		for i=1,#jetjoints do 
					local jetjoint = jetjoints[i]
					Delete(jetjoint)
					end
		
		
		
			local bomb = dumbbombs[currentHardpointIndex]
			if bomb then
				
				RemoveTag(bomb, "unbreakable")
				SetTag(bomb, "armed")
				
				
				    local bombjoints = GetShapeJoints(bomb)
    if bombjoints then
				 		for i=1,#bombjoints do 
					local bombjoint = bombjoints[i]
					Delete(bombjoint)
					end
    end
				
				currentHardpointIndex = currentHardpointIndex + 1
				
			end

		end

				if InputPressed("r",shared.pilot) and shared.manned and shared.missile_mode==false then
			local rocket = rockets[currentRocketIndex]
			if rocket then
				
				currentRocketIndex = currentRocketIndex + 1
				RemoveTag(rocket, "unbreakable")
				SetTag(rocket, "fired")
				SetTag(rocket, "armed")
				
				
								    local rocketjoints = GetShapeJoints(rocket)
    if rocketjoints then
				 		for i=1,#rocketjoints do 
					local rocketjoint = rocketjoints[i]
					Delete(rocketjoint)
					end
    end
				
				
			end

		end
		
	---WEIRD AHH MISSILE SYSTEM--
		--shared.missiles=FindBodies("missile")
		--missilepoints=FindJoints("missile_point")
		--currentMissileIndex = 1

		
		
		
						if InputPressed("b",shared.pilot) and radar_cooldown<0 and shared.radar_on==false then
			 shared.radar_on=true
			 radar_cooldown=0.5
			 end
			 
		if InputPressed("b",shared.pilot) and radar_cooldown<0 and shared.radar_on==true then
		shared.mapcooldown=0
		shared.radar_on=false
		radar_cooldown=0.5
		end	 
		
		
		
		
				if InputPressed("v",shared.pilot) and missile_cooldown>0.5 and shared.missile_mode==false then
			 shared.missile_mode=true
			 missile_cooldown=0
			 end
			 
		if InputPressed("v",shared.pilot) and missile_cooldown>0.5 and shared.missile_mode==true then
		shared.missile_mode=false
		missile_cooldown=0
		end	 
		

		
		--missile seek
		if shared.missile_mode==true then
			local missilepoint = missilepoints[currentMissileIndex]
			local missile = shared.missiles[currentMissileIndex]
		--DrawBodyOutline(missile, 1)
		if HasTag(missile,"player") then
		SetTag(missile,"seeking")
		SetTag(missile,"sound")
		end
		else
					local missilepoint = missilepoints[currentMissileIndex]
			local missile = shared.missiles[currentMissileIndex]
			if HasTag(missile,"player") then
			RemoveTag(missile,"seeking")
			end
			end
		--missile launch
		
					if InputPressed("r",shared.pilot) and shared.manned and shared.missile_mode then
			local missilepoint = missilepoints[currentMissileIndex]
			local missile = shared.missiles[currentMissileIndex]
			if missile and HasTag(missile,"seeking") then
				currentMissileIndex = currentMissileIndex + 1
				RemoveTag(rocket, "unbreakable")
				SetTag(missile, "active")
				shared.missile_count=shared.missile_count-1
				
			local	missileshapes = GetEntityChildren(missile, "", true, "shape")
				
				for i=1,#missileshapes do
				local missileshape = missileshapes[i]
												    local missilejoints = GetShapeJoints(missileshape)
    if missilejoints then
				 		for i=1,#missilejoints do 
					local missilejoint = missilejoints[i]
					Delete(missilejoint)
					end
    end
				
				end
				
				
				
			end

		end
		



end

	
if lightstate==0 or HasTag(fuselage,"downed") then
				 		for i=1,#lights do 
					local light = lights[i]
					SetLightEnabled(light, false)
					end
					
									 		for i=1,#landinglights do 
					local landinglight = landinglights[i]
					SetLightEnabled(landinglight, false)
					end
end

if lightstate==1 and damage_total==false and HasTag(fuselage,"downed")==false then
				 		for i=1,#lights do 
					local light = lights[i]
					SetLightEnabled(light, true)
					end
end

if lightstate==2 and damage_total==false then
									 		for i=1,#landinglights do 
					local landinglight = landinglights[i]
					SetLightEnabled(landinglight, true)
					end
end

if HasTag(fuselage,"eb") and damage_total==false then
				 		for i=1,#warninglights do 
					local warninglight = warninglights[i]
					SetLightEnabled(warninglight, true)
					end
end

if HasTag(fuselage,"downed") and damage_total==false then

									 		for i=1,#emergencylights do 
					local emergencylight = emergencylights[i]
					SetLightEnabled(emergencylight, true)
					end
end

if damage_total==true or HasTag(fuselage,"broken")  then
lightstate=0
				 		for i=1,#lights do 
					local light = lights[i]
					SetLightEnabled(light, false)
					end
					
									 		for i=1,#landinglights do 
					local landinglight = landinglights[i]
					SetLightEnabled(landinglight, false)
					end
				 		for i=1,#warninglights do 
					local warninglight = warninglights[i]
					SetLightEnabled(warninglight, false)
					end
									 		for i=1,#emergencylights do 
					local emergencylight = emergencylights[i]
					SetLightEnabled(emergencylight, false)
					end

end
if lightstate==1 or lightstate==2 then
if lightstimer>0.75 then
				 		for i=1,#strobes do 
					local strobe = strobes[i]
					SetLightEnabled(strobe, true)
					end
else
				 		for i=1,#strobes do 
					local strobe = strobes[i]
					SetLightEnabled(strobe, false)
					end
end

if lightstimer>1 and lightstimer<1.5 then
				 		for i=1,#beacons do 
					local beacon = beacons[i]
					SetLightEnabled(beacon, true)
					end
else
				 		for i=1,#beacons do 
					local beacon = beacons[i]
SetLightEnabled(beacon, false)
end
end
else
				 		for i=1,#beacons do 
					local beacon = beacons[i]
SetLightEnabled(beacon, false)
end
				 		for i=1,#strobes do 
					local strobe = strobes[i]
					SetLightEnabled(strobe, false)
					end
end

if lightstimer>2 then
lightstimer=0	
end	
	if shared.manned then
if InputDown("rmb",shared.pilot) then
CamZoom=0.5
else
CamZoom=1
end	


end	

end
	
function client.render()


if shared.manned==true and client.localPilot==true  then
     if CameraMode==1 then
	if CameraMode ~= 1 then return end

	if not IsHandleValid(fuselage) then
		fuselage = FindBody("fuselage")
		if fuselage == 0 then return end
	end

	-- Handle camera rotation input
	local mx, my = InputValue("mousedx",client.localPilot)*0.3, InputValue("mousedy",client.localPilot)*0.3
	camAngleX = camAngleX + mx * shared.sensitivity
	camAngleY = camAngleY + my * shared.sensitivity
	camAngleY = clamp(camAngleY, -math.rad(89), math.rad(89))

	-- Handle zoom
	local scroll = InputValue("mousewheel",client.localPilot)
	if scroll<0 then ---zooming out
	camDistance = clamp(camDistance - scroll * shared.zoomSpeed, 2, 60) -- keep raw distance for zooming
	else --zooming in
	camDistance = clamp(camDistance - scroll * shared.zoomSpeed*1.5, 2, 60)
	end
	-- Only override camera if zoomed out past cockpit threshold

		-- Calculate orbit offset
		local offsetX = math.cos(camAngleX) * math.cos(camAngleY) * camDistance
		local offsetY = math.sin(camAngleY) * camDistance
		local offsetZ = math.sin(camAngleX) * math.cos(camAngleY) * camDistance
		local orbitOffset = Vec(offsetX, offsetY, offsetZ)

		-- Fuselage + seat position
		local fuselageT = GetBodyTransform(fuselage)
		local seatWorldPos = TransformToParentPoint(fuselageT, seatOffset.pos)

		-- Apply dynamic vertical offset
		local targetPos = VecAdd(seatWorldPos, Vec(0, camDistance * 0.1, 0))

		-- Compute final camera position
		local camWorldPos = VecAdd(targetPos, orbitOffset)

		-- Look rotation
		local lookRot = QuatLookAt(camWorldPos, targetPos)

		-- Convert to fuselage-local transform
		local camWorldT = Transform(camWorldPos, lookRot)
		local camLocalT = TransformToLocalTransform(fuselageT, camWorldT)

		-- Attach and apply offset
		if camDistance>2 then
		AttachCameraTo(fuselage, false)
		SetCameraOffsetTransform(camLocalT)
		end
		-- Mouse aim position
		if not InputDown("alt",client.localPilot) then
        local pos = VecAdd(targetPos, VecScale(orbitOffset, -100))
        ServerCall("SetMouseAimPos", pos)
			else
		end
    end	
end
end


function SetMouseAimPos(pos)
    shared.mouseaimPos = pos
end

function client.tick()
			            if IsPlayerLocal(shared.pilot) then
                client.localPilot = true
				else
				client.localPilot = false
            end
end		
		
function SpawnProjectile(pos, dir, color, damage)
	table.insert(projectiles, {pos = pos, dir = VecNormalize(dir), color = color, life = projectileLifetime, dmg = damage})
end		

----TABS NPC INTEGRATION

function SerializeSpecialTable(Table)
    local Keys = {
        Main = {
            Primary = "~MainSeperation~",
            Type = "~TypeSeperation~",
            Arguments = "~ArgSeperation~",
            ArgumentType = "~ArgTypeSeperation~",
        },
        Transform = {
            Value = "~TransformValueSeperator~",
            TransformSeperator = "~TransformTypeSeperator~",
            Type = "~TransformVecSeperator~",
        },
        Table = {
            Type = "~TableTypeSeperator~",
            Values = "~TableValueSeperator~",
            
        },
    }
        
    local Strings = {}
    for i=1,#Table do
        local ArgTable = {}
        for j=1,#Table[i].Arguments do
                
            if Table[i].Arguments[j][1] == "Bool" or Table[i].Arguments[j][1] == "String" or Table[i].Arguments[j][1] == "Number" then
                table.insert(ArgTable, ""..Table[i].Arguments[j][1]..Keys.Main.ArgumentType..tostring(Table[i].Arguments[j][2]).."")
        
            elseif Table[i].Arguments[j][1] == "Vec" or Table[i].Arguments[j][1] == "Euler" then
                table.insert(ArgTable, ""..Table[i].Arguments[j][1]..Keys.Main.ArgumentType..table.concat(Table[i].Arguments[j][2],Keys.Transform.Value).."")
                
            elseif Table[i].Arguments[j][1] == "Transform" then
                local TransformTable = {}
                for k=1,#Table[i].Arguments[j][2] do
                    local Type = Table[i].Arguments[j][2][k][1]
                    local Value = Table[i].Arguments[j][2][k][2]
                    table.insert(TransformTable, ""..Type..Keys.Transform.Type..table.concat(Value, Keys.Transform.Value).."")
                end
                table.insert(ArgTable, ""..Table[i].Arguments[j][1]..Keys.Main.ArgumentType..table.concat(TransformTable, Keys.Transform.TransformSeperator).."")
                
            elseif Table[i].Arguments[j][1] == "Table" then
                local NewTable = {}
                for k=1,#Table[i].Arguments[j][2] do
                    local Type = Table[i].Arguments[j][2][k][1]
                    local Value = Table[i].Arguments[j][2][k][2]
                    CoolString = ""
                        
                    if Type == "Bool" or Type == "String" or Type == "Number" then
                        CoolString = ""..Type..Keys.Table.Type..tostring(Value)..""
                    
                    elseif Type == "Vec" then
                        CoolString = ""..Type..Keys.Table.Type..table.concat(Value, Keys.Transform.Value)..""
                        
                    elseif Type == "Euler" then
                        CoolString = ""..Type..Keys.Table.Type..table.concat(Value, Keys.Transform.Value)..""
                        
                    elseif Type == "Transform" then
                        local TransformTable = {}
                        for g=1,#Table[i].Arguments[j][2][k][2] do
                            local NewType = Table[i].Arguments[j][2][k][2][g][1]
                            local NewValue = Table[i].Arguments[j][2][k][2][g][2]
                            table.insert(TransformTable, ""..NewType..Keys.Transform.Type..table.concat(NewValue, Keys.Transform.Value).."")
                        end
                            
                        CoolString = ""..Type..Keys.Table.Type..table.concat(TransformTable, Keys.Transform.TransformSeperator)..""
                    end
                    table.insert(NewTable, CoolString)
                end
                table.insert(ArgTable, ""..Table[i].Arguments[j][1]..Keys.Main.ArgumentType..table.concat(NewTable,Keys.Table.Values).."")
            end    
        end
        local String = ''..Table[i].FunctionName..Keys.Main.Type..table.concat(ArgTable, Keys.Main.Arguments)..''
        table.insert(Strings, String)
    end
    
    return table.concat(Strings, Keys.Main.Primary)
end

function SendToListener(TBL, Listener)
    TriggerEvent(Listener, SerializeSpecialTable(TBL))
end

function npcDamage(body,damage,pos,dir)
			if HasTag(body,"pelvis") or HasTag(body,"stomach") or HasTag(body,"chest") or HasTag(body,"chest") 
			or HasTag(body,"neck") or HasTag(body,"head") or HasTag(body,"core") or HasTag(body,"shoulder_l") or 
			HasTag(body,"shoulder_r") or HasTag(body,"arm_upper_l") or HasTag(body,"arm_upper_r") 
			or HasTag(body,"arm_lower_l") or HasTag(body,"arm_lower_r") or HasTag(body,"hand_r") or HasTag(body,"hand_r") 
			or HasTag(body,"leg_upper_l") or HasTag(body,"leg_upper_r") or HasTag(body,"leg_lower_l") or HasTag(body,"hand_l") 
			or HasTag(body,"leg_upper_r") or HasTag(body,"foot_r") or HasTag(body,"foot_l")  then
			PlaySound(LoadSound("MOD/snd/bullethit4.ogg"), pos, 1)
			PlaySound(LoadSound("MOD/snd/hitsound.ogg"), GetPlayerTransform().pos, 1)
			--paint blood
			for i=1, 3 do
			PaintRGBA(pos, 0.05, 0.3, 0.08, 0.04, 1, 1)
			end
			--blood spray
			for i=1, 30 do
                        ParticleReset()
                        ParticleGravity(rnd(-2, -8))
                        ParticleRadius(math.random(6, 10) * .002, 0.0, "smooth")
                        ParticleColor(0.3, 0.08, 0.04)
                        ParticleTile(4)
						ParticleStretch(20)
                        ParticleDrag(rnd(0.2,0.5))
                        ParticleCollide(0, 1, "easeout")
                        SpawnParticle(pos, VecScale(VecAdd(dir,Vec(rnd(-0.2,0.2),rnd(-0.2,0.2),rnd(-0.2,0.2))),rnd(-1,-3)), 3)
						                        ParticleReset()
                        ParticleGravity(0)
                        ParticleRadius(math.random(4, 8) * .01,math.random(6, 12) * .02, "smooth")
                        ParticleColor(1, 0.16, 0.1)
						ParticleAlpha(0.3,0)
                        ParticleTile(0)
                        ParticleDrag(0, 0.2)
                        ParticleCollide(0, 1, "easeout")
                        SpawnParticle(pos, VecScale(dir,rnd(-1,-2)), 0.3)
			end
			-----BLOOD SPLATTER
			if HasTag(body,"head") then 		
			bloodhit, blooddist, bloodnormal, bloodshape = QueryRaycast(VecAdd(pos,VecScale(dir,0.5)),dir,3, 0, false)
			splatterpos=VecAdd(VecAdd(pos,VecScale(dir,0.5)),VecScale(dir,blooddist))
			if bloodhit then
			for i=1, 10 do
			PaintRGBA(VecAdd(splatterpos,Vec(rnd(-0.2,0.2),rnd(-0.2,0.2),rnd(-0.2,0.2))), rnd(1,2)*0.1, 0.3, 0.08, 0.04, 1, 1)
								for i=1, 15 do
                        ParticleReset()
                        ParticleGravity(rnd(-2, -8))
                        ParticleRadius(math.random(6, 10) * .002, 0.0, "smooth")
                        ParticleColor(0.3, 0.08, 0.04)
                        ParticleTile(4)
						ParticleSticky(rnd(5,1))
                        ParticleDrag(rnd(0.2,0.5))
                        ParticleCollide(0, 1, "easeout")
                        SpawnParticle(VecAdd(splatterpos,Vec(rnd(-0.2,0.2),rnd(-0.2,0.2),rnd(-0.2,0.2))), Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5)), 10)
						                        ParticleReset()
												end
			end
			end
			else
			bloodhit, blooddist, bloodnormal, bloodshape = QueryRaycast(VecAdd(pos,VecScale(dir,0.5)),dir,1.5, 0, false)
			splatterpos=VecAdd(VecAdd(pos,VecScale(dir,0.5)),VecScale(dir,blooddist))
			if bloodhit then
			for i=1, 5 do
			PaintRGBA(VecAdd(splatterpos,Vec(rnd(-0.2,0.2),rnd(-0.2,0.2),rnd(-0.2,0.2))), rnd(1,2)*0.1, 0.3, 0.08, 0.04, 1, 1)
											for i=1, 15 do
                        ParticleReset()
                        ParticleGravity(rnd(-2, -8))
                        ParticleRadius(math.random(6, 10) * .002, 0.0, "smooth")
                        ParticleColor(0.3, 0.08, 0.04)
                        ParticleTile(4)
						ParticleSticky(1)
                        ParticleDrag(rnd(0.2,0.5))
                        ParticleCollide(0, 1, "easeout")
                        SpawnParticle(VecAdd(splatterpos,Vec(rnd(-0.2,0.2),rnd(-0.2,0.2),rnd(-0.2,0.2))), Vec(rnd(-0.5,0.5),rnd(-0.5,0.5),rnd(-0.5,0.5)), 10)
						                        ParticleReset()
												end
			end
			end
			end
			
			--damage
			if HasTag(body,"head") then
			SetTag(body,"damage",damage*3.4)
			elseif HasTag(body,"neck") then
			SetTag(body,"damage",damage*1.6)
			elseif HasTag(body,"chest") then
			SetTag(body,"damage",damage*1)
			elseif HasTag(body,"stomach") then
			SetTag(body,"damage",damage*0.85)
			elseif HasTag(body,"pelvis") then
			SetTag(body,"damage",damage*0.7)
			else	
			SetTag(body,"damage",damage*0.5)
			end
			
			local previous_multiplier = tonumber(GetTagValue(body, "damage_multiplier")) or 1
			local new_multiplier=previous_multiplier+1
			SetTag(body,"damage_multiplier",new_multiplier)
			
			
			end
end