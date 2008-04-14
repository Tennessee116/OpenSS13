
/obj/machinery/computer/atmosphere/proc/returnarea()

	return

/obj/machinery/computer/atmosphere/ex_act(severity)

	switch(severity)
		if(1.0)
			//SN src = null
			del(src)
			return
		if(2.0)
			if (prob(50))
				for(var/x in src.verbs)
					src.verbs -= x
					//Foreach goto(58)
				src.icon_state = "broken"
				stat |= BROKEN
		if(3.0)
			if (prob(25))
				for(var/x in src.verbs)
					src.verbs -= x
					//Foreach goto(109)
				src.icon_state = "broken"
				stat |= BROKEN
		else
	return

/obj/machinery/computer/atmosphere/siphonswitch/New()
	..()

	spawn(5)
		src.area = src.loc.loc

		if(otherarea)
			src.area = locate(text2path("/area/[otherarea]"))

/obj/machinery/computer/atmosphere/siphonswitch/returnarea()

	return area.contents


/obj/machinery/computer/atmosphere/siphonswitch/verb/siphon_all()
	set src in oview(1)
	if(stat & NOPOWER)	return
	if (usr.stat)
		return
	usr << "Starting all siphon systems."
	for(var/obj/machinery/atmoalter/siphs/S in src.returnarea())
		S.reset(1, 0)
		//Foreach goto(39)
	src.add_fingerprint(usr)
	return

/obj/machinery/computer/atmosphere/siphonswitch/verb/stop_all()
	set src in oview(1)
	if(stat & NOPOWER)	return
	if (usr.stat)
		return
	usr << "Stopping all siphon systems."
	for(var/obj/machinery/atmoalter/siphs/S in src.returnarea())
		S.reset(0, 0)
		//Foreach goto(39)
	src.add_fingerprint(usr)
	return

/obj/machinery/computer/atmosphere/siphonswitch/verb/auto_on()
	set src in oview(1)
	if(stat & NOPOWER)	return
	if (usr.stat)
		return
	usr << "Starting automatic air control systems."
	for(var/obj/machinery/atmoalter/siphs/S in src.returnarea())
		S.reset(0, 1)
		//Foreach goto(39)
	src.add_fingerprint(usr)
	return

/obj/machinery/computer/atmosphere/siphonswitch/verb/release_scrubbers()
	set src in oview(1)

	if(stat & NOPOWER)	return
	if (usr.stat)
		return
	usr << "Releasing all scrubber toxins."
	for(var/obj/machinery/atmoalter/siphs/scrubbers/S in src.returnarea())
		S.reset(-1.0, 0)
		//Foreach goto(39)
	src.add_fingerprint(usr)
	return

/obj/machinery/computer/atmosphere/siphonswitch/verb/release_all()

	if(stat & NOPOWER)	return
	if (usr.stat)
		return
	usr << "Releasing all stored air."
	for(var/obj/machinery/atmoalter/siphs/S in src.returnarea())
		S.reset(-1.0, 0)
		//Foreach goto(37)
	src.add_fingerprint(usr)
	return

/obj/machinery/computer/atmosphere/siphonswitch/mastersiphonswitch/returnarea()

	return world
	return

