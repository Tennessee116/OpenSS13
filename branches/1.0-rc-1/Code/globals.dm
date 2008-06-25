var

	world_message = "Welcome to OpenSS13!"
	savefile_ver = "4"
	SS13_version = "1.0 RC 2"
	changes = {"<FONT color='blue'><B>Changes from previous version.</B></FONT><BR>
<HR><PRE>
Features
========
Map changed to a version similar to GoonStation 13.
Added an AI role to the station, with suitable equipment.

Bug-fixes
=========
Submitted By	Fixed By	Description
Cecilff2	Stephen001	Grab stages would not advance past passive.
Kurper		Stephen001	DNA Add would not append data properly.
Animay		Trafalgar	Attack delays were removed.
Trafalgar	Trafalgar	Disconnecting cameras would not cut off viewers.
Trafalgar	Trafalgar	Humans and AI could open each others inventory window.
Murrawhip	Stephen001	You could move into many objects through obstacles.
Darkman1920	Stephen001	Inventory Windows would not close on URL-unsafe names.
Animay		Murrawhip	Monkeys could talk while sleeping.
Animay		Trafalgar	Closets could be used to bypass window doors.
Animay		Hobnob		Vote toggling provided misleading messages.
Animay		Stephen001	Spawning 50 glass in Sandbox mode spawned 50 metal.
Animay		Trafalgar	It was possible to attack through windows.
Animay		Stephen001	World log would not trim say and OOC text.
Trafalgar	Trafalgar	Game ticker would count at double the intended speed.
Trafalgar	Trafalgar	Timers would not actually secure to igniters.
Trafalgar	Trafalgar	Ranks were not always consistent with access numbers.
Trafalgar	Trafalgar	Fixed bad grammar on some admin messages.
Trafalgar	Trafalgar	The AI could perform all the actions a human could.
Trafalgar	Trafalgar	The AI could not see it's APC if the APC was turned off.
Trafalgar	Trafalgar	The AI did not lose health below 0.
Trafalgar	Trafalgar	Fixed typos with shuttle messages.
Trafalgar	Trafalgar	The AI did not receive dialog updates.
Trafalgar	Trafalgar	Monkeys could be attacked before the game started.
Trafalgar	Trafalgar	Health equipment could be wasted on non-humans.
</PRE>"}
	datum/air_tunnel/air_tunnel1/SS13_airtunnel = null
	datum/control/cellular/cellcontrol = null
	datum/control/gameticker/ticker = null
	obj/datacore/data_core = null
	obj/overlay/plmaster = null
	obj/overlay/slmaster = null
	going = 1.0
	master_mode = "random"//"extended"

	persistent_file = "mode.txt"

	obj/ctf_assist/ctf = null
	nuke_code = null
	poll_controller = null
	datum/engine_eject/engine_eject_control = null
	host = null
	obj/hud/main_hud = null
	obj/hud/hud2/main_hud2 = null
	ooc_allowed = 1.0
	dna_ident = 1.0
	abandon_allowed = 1.0
	enter_allowed = 1.0
	shuttle_frozen = 0.0
	prison_entered = null

	list/html_colours = new/list(0)
	list/occupations = list( "Engineer", "Engineer", "Security Officer", "Security Officer", "Forensic Technician", "Medical Researcher", "Research Technician", "Toxin Researcher", "Atmospheric Technician", "Medical Doctor", "Station Technician", "Head of Personnel", "Head of Research", "Prison Security", "Prison Security", "Prison Doctor", "Prison Warden", "AI" )
	list/assistant_occupations = list( "Technical Assistant", "Medical Assistant", "Research Assistant", "Staff Assistant" )
	list/bombers = list(  )
	list/admins = list(  )
	list/shuttles = list(  )
	list/reg_dna = list(  )
	list/banned = list(  )
	shuttle_z = 10	//default
	list/monkeystart = list()
	list/blobstart = list()
	list/blobs = list()
	list/cardinal = list( NORTH, EAST, SOUTH, WEST )


	datum/station_state/start_state = null
	datum/config/config = null
	datum/vote/vote = null
	datum/sun/sun = null

	list/plines = list()
	list/gasflowlist = list()
	list/machines = list()

	list/powernets = null

	defer_powernet_rebuild = 0		// true if net rebuild will be called manually after an event

	Debug = 0	// global debug switch

	datum/debug/debugobj

	datum/moduletypes/mods = new()

	wavesecret = 0

	//airlockWireColorToIndex takes a number representing the wire color, e.g. the orange wire is always 1, the dark red wire is always 2, etc. It returns the index for whatever that wire does.
	//airlockIndexToWireColor does the opposite thing - it takes the index for what the wire does, for example AIRLOCK_WIRE_IDSCAN is 1, AIRLOCK_WIRE_POWER1 is 2, etc. It returns the wire color number.
	//airlockWireColorToFlag takes the wire color number and returns the flag for it (1, 2, 4, 8, 16, etc)
	list/airlockWireColorToFlag = RandomAirlockWires()
	list/airlockIndexToFlag
	list/airlockIndexToWireColor
	list/airlockWireColorToIndex
	list/airlockFeatureNames = list("IdScan", "Main power In", "Main power Out", "Drop door bolts", "Backup power In", "Backup power Out", "Power assist", "AI Control", "Electrify")

world
	mob = /mob/human
	turf = /turf/space
	area = /area
	view = "15x15"

	hub = "Exadv1.spacestation13"
	hub_password = "kMZy3U5jJHSiBQjr"
	name = "Space Station 13"
