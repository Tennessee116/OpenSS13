
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

/obj/machinery/atmoalter/heater/proc/setstate()

	if(stat & NOPOWER)
		icon_state = "heater-p"
		return

	if (src.holding)
		src.icon_state = "heater1-h"
	else
		src.icon_state = "heater1"
	return

/obj/machinery/atmoalter/heater/process()

	if(stat & NOPOWER)	return
	use_power(5)

	var/turf/T = src.loc
	if (istype(T, /turf))
		if (locate(/obj/move, T))
			T = locate(/obj/move, T)
	else
		T = null
	if (src.h_status)
		var/t1 = src.gas.tot_gas()
		if ((t1 > 0 && src.gas.temperature < (src.h_tar+T0C)))
			var/increase = src.heatrate / t1
			var/n_temp = src.gas.temperature + increase
			src.gas.temperature = min(n_temp, (src.h_tar+T0C))
			use_power( src.h_tar*8)
	switch(src.t_status)
		if(1.0)
			if (src.holding)
				var/t1 = src.gas.tot_gas()
				var/t2 = t1
				var/t = src.t_per
				if (src.t_per > t2)
					t = t2
				src.holding.gas.transfer_from(src.gas, t)
			else
				src.t_status = 3
		if(2.0)
			if (src.holding)
				var/t1 = src.gas.tot_gas()
				var/t2 = src.maximum - t1
				var/t = src.t_per
				if (src.t_per > t2)
					t = t2
				src.gas.transfer_from(src.holding.gas, t)
			else
				src.t_status = 3
		else

	/*
	if(src.c_status == 1)				// 1 = release
		var/obj/machinery/connector/C = locate(/obj/machinery/connector, src.loc)
		if (C && C.connected == src)
			spawn( 0 )
				C.receive_gas(gas, c_per )
				return

		else
			src.c_status = 0
	else if(src.c_status == 2)			// 2 = accept
		var/obj/machinery/connector/C = locate(/obj/machinery/connector, src.loc)
		if (C && C.connected == src)
			spawn( 0 )
				C.send_gas(gas, c_per)	// connector will send gas to canister
				return
	*/


	for(var/mob/M in viewers(1, src))
		if ((M.client && M.machine == src))
			src.attack_hand(M)
		//Foreach goto(432)
	src.setstate()
	return

/obj/machinery/atmoalter/heater/New()

	..()
	src.gas = new /obj/substance/gas( src )
	src.gas.maximum = src.maximum
	return

/obj/machinery/atmoalter/heater/attack_paw(mob/user as mob)

	return src.attack_hand(user)
	return

/obj/machinery/atmoalter/heater/attack_hand(var/mob/user as mob)

	if(stat & NOPOWER)	return

	user.machine = src
	var/tt
	switch(src.t_status)
		if(1.0)
			tt = text("Releasing <A href='?src=\ref[];t=2'>Siphon</A> <A href='?src=\ref[];t=3'>Stop</A>", src, src)
		if(2.0)
			tt = text("<A href='?src=\ref[];t=1'>Release</A> Siphoning<A href='?src=\ref[];t=3'>Stop</A>", src, src)
		if(3.0)
			tt = text("<A href='?src=\ref[];t=1'>Release</A> <A href='?src=\ref[];t=2'>Siphon</A> Stopped", src, src)
		else
	var/ht = null
	if (src.h_status)
		ht = text("Heating <A href='?src=\ref[];h=2'>Stop</A>", src)
	else
		ht = text("<A href='?src=\ref[];h=1'>Heat</A> Stopped", src)
	var/ct = null
	switch(src.c_status)
		if(1.0)
			ct = text("Releasing <A href='?src=\ref[];c=2'>Accept</A> <A href='?src=\ref[];ct=3'>Stop</A>", src, src)
		if(2.0)
			ct = text("<A href='?src=\ref[];c=1'>Release</A> Accepting <A href='?src=\ref[];c=3'>Stop</A>", src, src)
		if(3.0)
			ct = text("<A href='?src=\ref[];c=1'>Release</A> <A href='?src=\ref[];c=2'>Accept</A> Stopped", src, src)
		else
			ct = "Disconnected"
	var/dat = text("<TT><B>Canister Valves</B><BR>\n<FONT color = 'blue'><B>Contains/Capacity</B> [] / []</FONT><BR>\nUpper Valve Status: [][]<BR>\n\t<A href='?src=\ref[];tp=-[]'>M</A> <A href='?src=\ref[];tp=-10000'>-</A> <A href='?src=\ref[];tp=-1000'>-</A> <A href='?src=\ref[];tp=-100'>-</A> <A href='?src=\ref[];tp=-1'>-</A> [] <A href='?src=\ref[];tp=1'>+</A> <A href='?src=\ref[];tp=100'>+</A> <A href='?src=\ref[];tp=1000'>+</A> <A href='?src=\ref[];tp=10000'>+</A> <A href='?src=\ref[];tp=[]'>M</A><BR>\nHeater Status: [] - []<BR>\n\tTrg Tmp: <A href='?src=\ref[];ht=-50'>-</A> <A href='?src=\ref[];ht=-5'>-</A> <A href='?src=\ref[];ht=-1'>-</A> [] <A href='?src=\ref[];ht=1'>+</A> <A href='?src=\ref[];ht=5'>+</A> <A href='?src=\ref[];ht=50'>+</A><BR>\n<BR>\nPipe Valve Status: []<BR>\n\t<A href='?src=\ref[];cp=-[]'>M</A> <A href='?src=\ref[];cp=-10000'>-</A> <A href='?src=\ref[];cp=-1000'>-</A> <A href='?src=\ref[];cp=-100'>-</A> <A href='?src=\ref[];cp=-1'>-</A> [] <A href='?src=\ref[];cp=1'>+</A> <A href='?src=\ref[];cp=100'>+</A> <A href='?src=\ref[];cp=1000'>+</A> <A href='?src=\ref[];cp=10000'>+</A> <A href='?src=\ref[];cp=[]'>M</A><BR>\n<BR>\n<A href='?src=\ref[];mach_close=canister'>Close</A><BR>\n</TT>", src.gas.tot_gas(), src.maximum, tt, (src.holding ? text("<BR><A href='?src=\ref[];tank=1'>Tank ([]</A>)", src, src.holding.gas.tot_gas()) : null), src, num2text(1000000.0, 7), src, src, src, src, src.t_per, src, src, src, src, src, num2text(1000000.0, 7), ht, (src.gas.tot_gas() ? (src.gas.temperature-T0C) : 20), src, src, src, src.h_tar, src, src, src, ct, src, num2text(1000000.0, 7), src, src, src, src, src.c_per, src, src, src, src, src, num2text(1000000.0, 7), user)
	user << browse(dat, "window=canister;size=600x300")
	return

/obj/machinery/atmoalter/heater/Topic(href, href_list)
	..()
	if (usr.stat || usr.restrained())
		return
	if ((get_dist(src, usr) <= 1 && istype(src.loc, /turf)))
		usr.machine = src
		if (href_list["c"])
			var/c = text2num(href_list["c"])
			switch(c)
				if(1.0)
					src.c_status = 1
				if(2.0)
					src.c_status = 2
				if(3.0)
					src.c_status = 3
				else
		else
			if (href_list["t"])
				var/t = text2num(href_list["t"])
				if (src.t_status == 0)
					return
				switch(t)
					if(1.0)
						src.t_status = 1
					if(2.0)
						src.t_status = 2
					if(3.0)
						src.t_status = 3
					else
			else
				if (href_list["h"])
					var/h = text2num(href_list["h"])
					if (h == 1)
						src.h_status = 1
					else
						src.h_status = null
				else
					if (href_list["tp"])
						var/tp = text2num(href_list["tp"])
						src.t_per += tp
						src.t_per = min(max(round(src.t_per), 0), 1000000.0)
					else
						if (href_list["cp"])
							var/cp = text2num(href_list["cp"])
							src.c_per += cp
							src.c_per = min(max(round(src.c_per), 0), 1000000.0)
						else
							if (href_list["ht"])
								var/cp = text2num(href_list["ht"])
								src.h_tar += cp
								src.h_tar = min(max(round(src.h_tar), 0), 500)
							else
								if (href_list["tank"])
									var/cp = text2num(href_list["tank"])
									if ((cp == 1 && src.holding))
										src.holding.loc = src.loc
										src.holding = null
										if (src.t_status == 2)
											src.t_status = 3
		for(var/mob/M in viewers(1, src))
			if ((M.client && M.machine == src))
				src.attack_hand(M)
			//Foreach goto(515)
		src.add_fingerprint(usr)
	else
		usr << browse(null, "window=canister")
		return
	return

/obj/machinery/atmoalter/heater/attackby(var/obj/W as obj, var/mob/user as mob)

	if (istype(W, /obj/item/weapon/tank))
		if (src.holding)
			return
		var/obj/item/weapon/tank/T = W
		user.drop_item()
		T.loc = src
		src.holding = T
	else
		if (istype(W, /obj/item/weapon/wrench))
			var/obj/machinery/connector/con = locate(/obj/machinery/connector, src.loc)

			if (src.c_status)
				src.anchored = 0
				src.c_status = 0
				user.show_message("\blue You have disconnected the heater.", 1)
				if(con)
					con.connected = null
			else
				if (con && !con.connected)
					src.anchored = 1
					src.c_status = 3
					user.show_message("\blue You have connected the heater.", 1)
					con.connected = src
				else
					user.show_message("\blue There is no connector here to attach the heater to.", 1)
	return


/obj/machinery/atmoalter/canister/proc/update_icon()

	var/air_in = src.gas.tot_gas()

	src.overlays = 0

	if (src.destroyed)
		src.icon_state = text("[]-1", src.color)

	else
		icon_state = "[color]"
		if(holding)
			overlays += image('canister.dmi', "can-oT")

		if (air_in < 10)
			overlays += image('canister.dmi', "can-o0")
		else if (air_in < (src.gas.maximum * 0.2))
			overlays += image('canister.dmi', "can-o1")
		else if (air_in < (src.maximum * 0.6))
			overlays += image('canister.dmi', "can-o2")
		else
			overlays += image('canister.dmi', "can-o3")
	return

/obj/machinery/atmoalter/canister/proc/healthcheck()

	if (src.health <= 10)
		var/T = src.loc
		if (!( istype(T, /turf) ))
			return
		src.gas.turf_add(T, -1.0)
		src.destroyed = 1
		src.density = 0
		update_icon()
		if (src.holding)
			src.holding.loc = src.loc
			src.holding = null
		if (src.t_status == 2)
			src.t_status = 3
	return

/obj/machinery/atmoalter/canister/process()

	if (src.destroyed)
		return
	var/T = src.loc
	if (istype(T, /turf))
		if (locate(/obj/move, T))
			T = locate(/obj/move, T)
	else
		T = null
	switch(src.t_status)
		if(1.0)
			if (src.holding)
				var/t1 = src.gas.tot_gas()
				var/t2 = t1
				var/t = src.t_per
				if (src.t_per > t2)
					t = t2
				src.holding.gas.transfer_from(src.gas, t)
			else
				if (T)
					var/t1 = src.gas.tot_gas()
					var/t2 = t1
					var/t = src.t_per
					if (src.t_per > t2)
						t = t2
					src.gas.turf_add(T, t)
			src.update_icon()
		if(2.0)
			if (src.holding)
				var/t1 = src.gas.tot_gas()
				var/t2 = src.maximum - t1
				var/t = src.t_per
				if (src.t_per > t2)
					t = t2
				src.gas.transfer_from(src.holding.gas, t)
			else
				src.t_status = 3
			src.update_icon()
		else


// new method does all transfers in connector ptick

/*	if(src.c_status == 1)				// 1 = release
		var/obj/machinery/connector/C = locate(/obj/machinery/connector, src.loc)
		if (C && C.connected == src)
			spawn( 0 )
				C.receive_gas(gas, c_per )
				return
			src.update_icon()
		else
			src.c_status = 0
	else if(src.c_status == 2)			// 2 = accept
		var/obj/machinery/connector/C = locate(/obj/machinery/connector, src.loc)
		if (C && C.connected == src)
			spawn( 0 )
				C.send_gas(gas, c_per)	// connector will send gas to canister
				return
			src.update_icon()
*/

	for(var/mob/M in viewers(1, src))
		if ((M.client && M.machine == src))
			src.attack_hand(M)
		//Foreach goto(450)
	src.update_icon()
	return

/obj/machinery/atmoalter/canister/New()

	..()
	src.gas = new /obj/substance/gas( src )
	src.gas.maximum = src.maximum
	return

/obj/machinery/atmoalter/canister/get_gas()
	return gas


/obj/machinery/atmoalter/canister/burn(fi_amount)

	src.health -= 1
	healthcheck()
	return

/obj/machinery/atmoalter/canister/blob_act()

	src.health -= 1
	healthcheck()
	return


/obj/machinery/atmoalter/canister/meteorhit(var/obj/O as obj)

	src.health = 0
	healthcheck()
	return

/obj/machinery/atmoalter/canister/attack_paw(var/mob/user as mob)

	return src.attack_hand(user)
	return

/obj/machinery/atmoalter/canister/attack_hand(var/mob/user as mob)

	if (src.destroyed)
		return
	user.machine = src
	var/tt
	switch(src.t_status)
		if(1.0)
			tt = text("Releasing <A href='?src=\ref[];t=2'>Siphon (only tank)</A> <A href='?src=\ref[];t=3'>Stop</A>", src, src)
		if(2.0)
			tt = text("<A href='?src=\ref[];t=1'>Release</A> Siphoning (only tank) <A href='?src=\ref[];t=3'>Stop</A>", src, src)
		if(3.0)
			tt = text("<A href='?src=\ref[];t=1'>Release</A> <A href='?src=\ref[];t=2'>Siphon (only tank)</A> Stopped", src, src)
		else
	var/ct = null
	switch(src.c_status)
		if(1.0)
			ct = text("Releasing <A href='?src=\ref[];c=2'>Accept</A> <A href='?src=\ref[];c=3'>Stop</A>", src, src)
		if(2.0)
			ct = text("<A href='?src=\ref[];c=1'>Release</A> Accepting <A href='?src=\ref[];c=3'>Stop</A>", src, src)
		if(3.0)
			ct = text("<A href='?src=\ref[];c=1'>Release</A> <A href='?src=\ref[];c=2'>Accept</A> Stopped", src, src)
		else
			ct = "Disconnected"


	var/dat = {"<TT><B>Canister Valves</B><BR>
<FONT color = 'blue'><B>Contains/Capacity</B> [num2text(src.gas.tot_gas(), 20)] / [num2text(src.maximum, 20)]</FONT><BR>
Upper Valve Status: [tt]<BR>
\t[(src.holding ? "<A href='?src=\ref[src];tank=1'>Tank ([src.holding.gas.tot_gas()]</A>)" : null)]<BR>
\t<A href='?src=\ref[src];tp=-[num2text(1000000.0, 7)]'>M</A> <A href='?src=\ref[src];tp=-10000'>-</A> <A href='?src=\ref[src];tp=-1000'>-</A> <A href='?src=\ref[src];tp=-100'>-</A> <A href='?src=\ref[src];tp=-1'>-</A> [src.t_per] <A href='?src=\ref[src];tp=1'>+</A> <A href='?src=\ref[src];tp=100'>+</A> <A href='?src=\ref[src];tp=1000'>+</A> <A href='?src=\ref[src];tp=10000'>+</A> <A href='?src=\ref[src];tp=[num2text(1000000.0, 7)]'>M</A><BR>
Pipe Valve Status: [ct]<BR>
\t<A href='?src=\ref[src];cp=-[num2text(1000000.0, 7)]'>M</A> <A href='?src=\ref[src];cp=-10000'>-</A> <A href='?src=\ref[src];cp=-1000'>-</A> <A href='?src=\ref[src];cp=-100'>-</A> <A href='?src=\ref[src];cp=-1'>-</A> [src.c_per] <A href='?src=\ref[src];cp=1'>+</A> <A href='?src=\ref[src];cp=100'>+</A> <A href='?src=\ref[src];cp=1000'>+</A> <A href='?src=\ref[src];cp=10000'>+</A> <A href='?src=\ref[src];cp=[num2text(1000000.0, 7)]'>M</A><BR>
<BR>
<A href='?src=\ref[user];mach_close=canister'>Close</A><BR>
</TT>"}



	/*

	var/dat = text({"<TT><B>Canister Valves</B><BR>
<FONT color = 'blue'><B>Contains/Capacity</B> [] / []</FONT><BR>
Upper Valve Status: []<BR>
\t[]<BR>
\t<A href='?src=\ref[];tp=-[]'>M</A> <A href='?src=\ref[];tp=-10000'>-</A> <A href='?src=\ref[];tp=-1000'>-</A> <A href='?src=\ref[];tp=-100'>-</A> <A href='?src=\ref[];tp=-1'>-</A> [] <A href='?src=\ref[];tp=1'>+</A> <A href='?src=\ref[];tp=100'>+</A> <A href='?src=\ref[];tp=1000'>+</A> <A href='?src=\ref[];tp=10000'>+</A> <A href='?src=\ref[];tp=[]'>M</A><BR>
Pipe Valve Status: []<BR>
\t<A href='?src=\ref[];cp=-[]'>M</A> <A href='?src=\ref[];cp=-10000'>-</A> <A href='?src=\ref[];cp=-1000'>-</A> <A href='?src=\ref[];cp=-100'>-</A> <A href='?src=\ref[];cp=-1'>-</A> [] <A href='?src=\ref[];cp=1'>+</A> <A href='?src=\ref[];cp=100'>+</A> <A href='?src=\ref[];cp=1000'>+</A> <A href='?src=\ref[];cp=10000'>+</A> <A href='?src=\ref[];cp=[]'>M</A><BR>
<BR>
<A href='?src=\ref[];mach_close=canister'>Close</A><BR>
</TT>"}, num2text(src.gas.tot_gas(), 20), num2text(src.maximum, 20), tt, (src.holding ? text("<A href='?src=\ref[];tank=1'>Tank ([]</A>)", src, src.holding.gas.tot_gas()) : null), src, num2text(1000000.0, 7), src, src, src, src, src.t_per, src, src, src, src, src, num2text(1000000.0, 7), ct, src, num2text(1000000.0, 7), src, src, src, src, src.c_per, src, src, src, src, src, num2text(1000000.0, 7), user)

*/
	user << browse(dat, "window=canister;size=600x300")
	return

/obj/machinery/atmoalter/canister/Topic(href, href_list)
	..()
	if (usr.stat || usr.restrained())
		return
	if ((get_dist(src, usr) <= 1 && istype(src.loc, /turf)))
		usr.machine = src
		if (href_list["c"])
			var/c = text2num(href_list["c"])
			switch(c)
				if(1.0)
					src.c_status = 1
				if(2.0)
					c_status = 2
				if(3.0)
					src.c_status = 3
		else
			if (href_list["t"])
				var/t = text2num(href_list["t"])
				if (src.t_status == 0)
					return
				switch(t)
					if(1.0)
						src.t_status = 1
					if(2.0)
						if (src.holding)
							src.t_status = 2
						else
							src.t_status = 3
					if(3.0)
						src.t_status = 3
			else
				if (href_list["tp"])
					var/tp = text2num(href_list["tp"])
					src.t_per += tp
					src.t_per = min(max(round(src.t_per), 0), 1000000.0)
				else
					if (href_list["cp"])
						var/cp = text2num(href_list["cp"])
						src.c_per += cp
						src.c_per = min(max(round(src.c_per), 0), 1000000.0)
					else
						if (href_list["tank"])
							var/cp = text2num(href_list["tank"])
							if ((cp == 1 && src.holding))
								src.holding.loc = src.loc
								src.holding = null
								if (src.t_status == 2)
									src.t_status = 3
		for(var/mob/M in viewers(1, src))
			if ((M.client && M.machine == src))
				src.attack_hand(M)
			//Foreach goto(423)
		src.add_fingerprint(usr)
		update_icon()
	else
		usr << browse(null, "window=canister")
		return
	return

/obj/machinery/atmoalter/canister/attackby(var/obj/item/weapon/W as obj, var/mob/user as mob)

	if ((istype(W, /obj/item/weapon/tank) && !( src.destroyed )))
		if (src.holding)
			return
		var/obj/item/weapon/tank/T = W
		user.drop_item()
		T.loc = src
		src.holding = T
		update_icon()
	else
		if ((istype(W, /obj/item/weapon/wrench)))
			var/obj/machinery/connector/con = locate(/obj/machinery/connector, src.loc)


			if (src.c_status)
				src.anchored = 0
				src.c_status = 0
				user.show_message("\blue You have disconnected the canister.", 1)
				if(con)
					con.connected = null
			else
				if(con && !con.connected && !destroyed)
					src.anchored = 1
					src.c_status = 3
					user.show_message("\blue You have connected the canister.", 1)
					con.connected = src
				else
					user.show_message("\blue There is nothing here with which to connect the canister.", 1)
		else
			switch(W.damtype)
				if("fire")
					src.health -= W.force
				if("brute")
					src.health -= W.force * 0.5
				else
			src.healthcheck()
			..()
	return

/obj/machinery/atmoalter/canister/las_act(flag)

	if (flag == "bullet")
		src.health = 0
		spawn( 0 )
			healthcheck()
			return
	if (flag)
		var/turf/T = src.loc
		if (!( istype(T, /turf) ))
			return
		else
			T.firelevel = T.poison
	else
		src.health = 0
		spawn( 0 )
			healthcheck()
			return
	return

/obj/machinery/atmoalter/canister/poisoncanister/New()

	..()
	src.update_icon()
	src.gas.plasma = 9.0E7*filled
	return

/obj/machinery/atmoalter/canister/oxygencanister/New()

	..()
	src.gas.oxygen = 1.0E8*filled
	return

/obj/machinery/atmoalter/canister/anesthcanister/New()

	..()
	src.gas.sl_gas = 1.0E8*filled
	return

/obj/machinery/atmoalter/canister/n2canister/New()

	..()
	src.gas.n2 = 1.0E8*filled
	return

/obj/machinery/atmoalter/canister/co2canister/New()

	..()
	src.gas.co2 = 1.0E8*filled
	return


/obj/machinery/atmoalter/canister/aircanister/New()

	..()
	src.gas.oxygen = 2.1e7*filled
	src.gas.n2 = 7.9e7*filled
	return

