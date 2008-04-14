
/obj/move/airtunnel/process()

	if (!( src.deployed ))
		return null
	else
		..()
	return

/obj/move/airtunnel/connector/create()

	src.current = src
	src.next = new /obj/move/airtunnel( null )
	src.next.master = src.master
	src.next.previous = src
	spawn( 0 )
		src.next.create(36, src.y)
		return
	return

/obj/move/airtunnel/connector/wall/create()

	src.current = src
	src.next = new /obj/move/airtunnel/wall( null )
	src.next.master = src.master
	src.next.previous = src
	spawn( 0 )
		src.next.create(36, src.y)
		return
	return

/obj/move/airtunnel/connector/wall/process()

	return

/obj/move/airtunnel/wall/create(num, y_coord)

	if (((num < 7 || (num > 14 && num < 21)) && y_coord == 72))
		src.next = new /obj/move/airtunnel( null )
	else
		src.next = new /obj/move/airtunnel/wall( null )
	src.next.master = src.master
	src.next.previous = src
	if (num > 1)
		spawn( 0 )
			src.next.create(num - 1, y_coord)
			return
	return

/obj/move/airtunnel/wall/move_right()

	flick("wall-m", src)
	return ..()
	return

/obj/move/airtunnel/wall/move_left()

	flick("wall-m", src)
	return ..()
	return

/obj/move/airtunnel/wall/process()

	return

/obj/move/airtunnel/proc/move_left()

	src.relocate(get_step(src, WEST))
	if ((src.next && src.next.deployed))
		return src.next.move_left()
	else
		return src.next
	return

/obj/move/airtunnel/proc/move_right()

	src.relocate(get_step(src, EAST))
	if ((src.previous && src.previous.deployed))
		src.previous.move_right()
	return src.previous
	return

/obj/move/airtunnel/proc/create(num, y_coord)

	if (y_coord == 72)
		if ((num < 7 || (num > 14 && num < 21)))
			src.next = new /obj/move/airtunnel( null )
		else
			src.next = new /obj/move/airtunnel/wall( null )
	else
		src.next = new /obj/move/airtunnel( null )
	src.next.master = src.master
	src.next.previous = src
	if (num > 1)
		spawn( 0 )
			src.next.create(num - 1, y_coord)
			return
	return



/obj/machinery/computer/airtunnel/ex_act(severity)

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
		if(3.0)
			if (prob(25))
				for(var/x in src.verbs)
					src.verbs -= x
					//Foreach goto(109)
				src.icon_state = "broken"
		else
	return

/obj/machinery/computer/airtunnel/attack_paw(user as mob)

	return src.attack_hand(user)
	return

/obj/machinery/computer/airtunnel/attack_hand(var/mob/user as mob)

	if(stat & (NOPOWER|BROKEN) )
		return

	var/dat = "<HTML><BODY><TT><B>Air Tunnel Controls</B><BR>"
	user.machine = src
	if (SS13_airtunnel.operating == 1)
		dat += "<B>Status:</B> RETRACTING<BR>"
	else
		if (SS13_airtunnel.operating == 2)
			dat += "<B>Status:</B> EXPANDING<BR>"
		else
			var/obj/move/airtunnel/connector/C = pick(SS13_airtunnel.connectors)
			if (C.current == C)
				dat += "<B>Status:</B> Fully Retracted<BR>"
			else
				if (!( C.current.next ))
					dat += "<B>Status:</B> Fully Extended<BR>"
				else
					dat += "<B>Status:</B> Stopped Midway<BR>"
	dat += text("<A href='?src=\ref[];retract=1'>Retract</A> <A href='?src=\ref[];stop=1'>Stop</A> <A href='?src=\ref[];extend=1'>Extend</A><BR>", src, src, src)
	dat += text("<BR><B>Air Level:</B> []<BR>", (SS13_airtunnel.air_stat ? "Acceptable" : "DANGEROUS"))
	dat += "<B>Air System Status:</B> "
	switch(SS13_airtunnel.siphon_status)
		if(0.0)
			dat += "Stopped "
		if(1.0)
			dat += "Siphoning (Siphons only) "
		if(2.0)
			dat += "Regulating (BOTH) "
		if(3.0)
			dat += "RELEASING MAX (Siphons only) "
		else
	dat += text("<A href='?src=\ref[];refresh=1'>(Refresh)</A><BR>", src)
	dat += text("<A href='?src=\ref[];release=1'>RELEASE (Siphons only)</A> <A href='?src=\ref[];siphon=1'>Siphon (Siphons only)</A> <A href='?src=\ref[];stop_siph=1'>Stop</A> <A href='?src=\ref[];auto=1'>Regulate</A><BR>", src, src, src, src)
	dat += text("<BR><BR><A href='?src=\ref[];mach_close=computer'>Close</A></TT></BODY></HTML>", user)
	user << browse(dat, "window=computer;size=400x500")
	return

/obj/machinery/computer/airtunnel/proc/update_icon()

	if(stat & BROKEN)
		icon_state = "broken"
		return

	if(stat & NOPOWER)
		icon_state = "c_unpowered"
		return

	var/status = 0
	if (SS13_airtunnel.operating == 1)
		status = "r"
	else
		if (SS13_airtunnel.operating == 2)
			status = "e"
		else
			var/obj/move/airtunnel/connector/C = pick(SS13_airtunnel.connectors)
			if (C.current == C)
				status = 0
			else
				if (!( C.current.next ))
					status = 2
				else
					status = 1
	src.icon_state = text("console[][]", (SS13_airtunnel.siphon_status >= 2 ? "1" : "0"), status)
	return

/obj/machinery/computer/airtunnel/process()

	src.update_icon()
	if(stat & (NOPOWER|BROKEN) )
		return
	use_power(250)
	for(var/mob/M in viewers(1, src))
		if ((M.client && M.machine == src))
			src.attack_hand(M)
		//Foreach goto(27)
	return

/obj/machinery/computer/airtunnel/Topic(href, href_list)
	..()

	if ((!( istype(usr, /mob/human) ) && (!( ticker ) || (ticker && ticker.mode != "monkey"))))
		usr << "\red You don't have the dexterity to do this!"
		return
	if ((usr.stat || usr.restrained()))
		return
	if ((usr.contents.Find(src) || (get_dist(src, usr) <= 1 && istype(src.loc, /turf))))
		usr.machine = src
		if (href_list["retract"])
			SS13_airtunnel.retract()
		else
			if (href_list["stop"])
				SS13_airtunnel.operating = 0
			else
				if (href_list["extend"])
					SS13_airtunnel.extend()
				else
					if (href_list["release"])
						SS13_airtunnel.siphon_status = 3
						SS13_airtunnel.siphons()
					else
						if (href_list["siphon"])
							SS13_airtunnel.siphon_status = 1
							SS13_airtunnel.siphons()
						else
							if (href_list["stop_siph"])
								SS13_airtunnel.siphon_status = 0
								SS13_airtunnel.siphons()
							else
								if (href_list["auto"])
									SS13_airtunnel.siphon_status = 2
									SS13_airtunnel.siphons()
								else
									if (href_list["refresh"])
										SS13_airtunnel.siphons()
		src.add_fingerprint(usr)
		for(var/mob/M in viewers(1, src))
			if ((M.client && M.machine == src))
				src.attack_hand(M)
			//Foreach goto(346)
	return








/datum/air_tunnel/air_tunnel1/New()

	..()
	for(var/obj/move/airtunnel/A in locate(/area/airtunnel1))
		A.master = src
		A.create()
		src.connectors += A
		//Foreach goto(21)
	return

/datum/air_tunnel/proc/siphons()

	switch(src.siphon_status)
		if(0.0)
			for(var/obj/machinery/atmoalter/siphs/S in locate(/area/airtunnel1))
				S.t_status = 3
				//Foreach goto(42)
		if(1.0)
			for(var/obj/machinery/atmoalter/siphs/fullairsiphon/S in locate(/area/airtunnel1))
				S.t_status = 2
				S.t_per = 1000000.0
				//Foreach goto(86)
			for(var/obj/machinery/atmoalter/siphs/scrubbers/S in locate(/area/airtunnel1))
				S.t_status = 3
				//Foreach goto(136)
		if(2.0)
			for(var/obj/machinery/atmoalter/siphs/S in locate(/area/airtunnel1))
				S.t_status = 4
				//Foreach goto(180)
		if(3.0)
			for(var/obj/machinery/atmoalter/siphs/fullairsiphon/S in locate(/area/airtunnel1))
				S.t_status = 1
				S.t_per = 1000000.0
				//Foreach goto(224)
			for(var/obj/machinery/atmoalter/siphs/scrubbers/S in locate(/area/airtunnel1))
				S.t_status = 3
				//Foreach goto(274)
		else
	return

/datum/air_tunnel/proc/stop()

	src.operating = 0
	return

/datum/air_tunnel/proc/extend()

	if (src.operating)
		return
	src.operating = 2
	while(src.operating == 2)
		var/ok = 1
		for(var/obj/move/airtunnel/connector/A in src.connectors)
			if (!( A.current.next ))
				src.operating = 0
				return
			if (!( A.move_left() ))
				ok = 0
			//Foreach goto(56)
		if (!( ok ))
			src.operating = 0
		else
			for(var/obj/move/airtunnel/connector/A in src.connectors)
				if (A.current)
					A.current.next.loc = get_step(A.current.loc, EAST)
					A.current = A.current.next
					A.current.deployed = 1
				else
					src.operating = 0
				//Foreach goto(150)
		sleep(20)
	return

/datum/air_tunnel/proc/retract()

	if (src.operating)
		return
	src.operating = 1
	while(src.operating == 1)
		var/ok = 1
		for(var/obj/move/airtunnel/connector/A in src.connectors)
			if (A.current == A)
				src.operating = 0
				return
			if (A.current)
				A.current.loc = null
				A.current.deployed = 0
				A.current = A.current.previous
			else
				ok = 0
			//Foreach goto(56)
		if (!( ok ))
			src.operating = 0
		else
			for(var/obj/move/airtunnel/connector/A in src.connectors)
				if (!( A.current.move_right() ))
					src.operating = 0
				//Foreach goto(188)
		sleep(20)
	return
