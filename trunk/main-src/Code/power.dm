
// the power cell
// charge from 0 to 100%
// fits in PDU to provide backup power

/obj/item/weapon/cell/New()
	..()

	charge = charge * maxcharge/100.0		// map obj has charge as percentage, convert to real value here

	spawn(5)
		updateicon()


/obj/item/weapon/cell/proc/updateicon()

	if(maxcharge == 1000)
		icon_state = "cell"
	else
		icon_state = "hpcell"

	overlays = null

	if(charge < 0.01)
		return
	else if(charge/maxcharge >=0.995)
		overlays += image('power.dmi', "cell-o2")
	else
		overlays += image('power.dmi', "cell-o1")

/obj/item/weapon/cell/proc/percent()		// return % charge of cell
	return 100.0*charge/maxcharge

/obj/item/weapon/cell/examine()
	set src in view(1)
	if(usr && !usr.stat)
		if(maxcharge == 1000)
			usr << "[desc]\nThe charge meter reads [round(src.percent() )]%."
		else
			usr << "A high-capacity rechargable electrochemical power cell.\nThe charge meter reads [round(src.percent() )]%."



// common helper procs for all power machines

/obj/machinery/power/proc/add_avail(var/amount)
	if(powernet)
		powernet.newavail += amount

/obj/machinery/power/proc/add_load(var/amount)
	if(powernet)
		powernet.newload += amount

/obj/machinery/power/proc/surplus()
	if(powernet)
		return powernet.avail-powernet.load
	else
		return 0

/obj/machinery/power/proc/avail()
	if(powernet)
		return powernet.avail
	else
		return 0

// the Area Power Controller (APC), formerly Power Distribution Unit (PDU)
// one per area, needs wire conection to power network

// controls power to devices in that area
// may be opened to change power cell
// three different channels (lighting/equipment/environ) - may each be set to on, off, or auto

/obj/machinery/power/apc/New()
	..()

	// offset 24 pixels in direction of dir
	// this allows the APC to be embedded in a wall, yet still inside an area

	tdir = dir		// to fix Vars bug
	dir = SOUTH

	pixel_x = (tdir & 3)? 0 : (tdir == 4 ? 24 : -24)
	pixel_y = (tdir & 3)? (tdir ==1 ? 24 : -24) : 0


	// is starting with a power cell installed, create it and set its charge level
	if(cell_type)
		src.cell = new/obj/item/weapon/cell(src)
		cell.maxcharge = cell_type==1 ? 1000 : 5000				// if type=2, make a hp cell
		cell.charge = start_charge * cell.maxcharge / 100.0 		// (convert percentage to actual value)


	var/area/A = src.loc.loc

	if(isarea(A))
		src.area = A

	updateicon()

	// create a terminal object at the same position as original turf loc
	// wires will attach to this
	terminal = new/obj/machinery/power/terminal(src.loc)
	terminal.dir = tdir
	terminal.master = src

	spawn(5)
		src.update()

/obj/machinery/power/apc/examine()
	set src in oview(1)

	if(stat & BROKEN) return

	if(usr && !usr.stat)
		usr << "A control terminal for the area electrical systems."
		if(opened)
			usr << "The cover is open and the power cell is [ cell ? "installed" : "missing"]."
		else
			usr << "The cover is closed."



// update the APC icon to show the three base states
// also add overlays for indicator lights
/obj/machinery/power/apc/proc/updateicon()
	if(opened)
		icon_state = "[ cell ? "apc2" : "apc1" ]"		// if opened, show cell if it's inserted
		src.overlays = null								// also delete all overlays
	else
		icon_state = "apc0"

		// if closed, update overlays for channel status

		src.overlays = null

		overlays += image('power.dmi', "apcox-[locked]")	// 0=blue 1=red
		overlays += image('power.dmi', "apco3-[charging]") // 0=red, 1=yellow/black 2=green


		if(operating)
			overlays += image('power.dmi', "apco0-[equipment]")	// 0=red, 1=green, 2=blue
			overlays += image('power.dmi', "apco1-[lighting]")
			overlays += image('power.dmi', "apco2-[environ]")



//attack with an item - open/close cover, insert cell, or (un)lock interface

/obj/machinery/power/apc/attackby(obj/item/weapon/W, mob/user)

	if(stat & BROKEN) return

	if (istype(W, /obj/item/weapon/screwdriver))	// screwdriver means open or close the cover
		if(opened)
			opened = 0
			updateicon()
		else
			if(coverlocked)
				user << "The cover is locked and cannot be opened."
			else
				opened = 1
				updateicon()

	else if	(istype(W, /obj/item/weapon/cell) && opened)	// trying to put a cell inside
		if(cell)
			user << "There is a power cell already installed."
		else
			user.drop_item()
			W.loc = src
			cell = W
			user << "You insert the power cell."
			chargecount = 0

		updateicon()
	else if (istype(W, /obj/item/weapon/card/id) )			// trying to unlock the interface with an ID card

		if(opened)
			user << "You must close the cover to swipe an ID card."
		else
			var/obj/item/weapon/card/id/I = W
			if (I.check_access(access, allowed))
				locked = !locked
				user << "You [ locked ? "lock" : "unlock"] the APC interface."
				updateicon()
			else
				user << "\red Access denied."

	else if (istype(W, /obj/item/weapon/card/emag) )		// trying to unlock with an emag card

		if(opened)
			user << "You must close the cover to swipe an ID card."
		else
			flick("apc-spark", src)
			sleep(6)
			if(prob(50))
				locked = !locked
				user << "You [ locked ? "lock" : "unlock"] the APC interface."
				updateicon()
			else
				user << "You fail to [ locked ? "unlock" : "lock"] the APC interface."


// attack with hand - remove cell (if cover open) or interact with the APC

/obj/machinery/power/apc/attack_hand(mob/user)

	add_fingerprint(user)

	if(stat & BROKEN) return

	if(opened)
		if(cell)
			cell.loc = usr
			cell.layer = 20
			if (user.hand )
				user.l_hand = cell
			else
				user.r_hand = cell

			cell.add_fingerprint(user)
			cell.updateicon()

			src.cell = null
			user << "You remove the power cell."
			charging = 0
			src.updateicon()

	else
		// do APC interaction
		src.interact(user)



/obj/machinery/power/apc/proc/interact(mob/user)

	if ( (get_dist(src, user) > 1 ))
		user.machine = null
		user << browse(null, "window=apc")
		return

	user.machine = src
	var/t = "<TT><B>Area Power Controller</B> ([area.name])<HR>"

	if(locked)
		t += "<I>(Swipe ID card to unlock inteface.)</I><BR>"
		t += "Main breaker : <B>[operating ? "On" : "Off"]</B><BR>"
		t += "External power : <B>[ main_status ? (main_status ==2 ? "<FONT COLOR=#004000>Good</FONT>" : "<FONT COLOR=#D09000>Low</FONT>") : "<FONT COLOR=#F00000>None</FONT>"]</B><BR>"
		t += "Power cell: <B>[cell ? "[round(cell.percent())]%" : "<FONT COLOR=red>Not connected.</FONT>"]</B>"
		if(cell)
			t += " ([charging ? ( charging == 1 ? "Charging" : "Fully charged" ) : "Not charging"])"
			t += " ([chargemode ? "Auto" : "Off"])"

		t += "<BR><HR>Power channels<BR><PRE>"

		var/list/L = list ("Off","Off (Auto)", "On", "On (Auto)")

		t += "Equipment:    [add_lspace(lastused_equip, 6)] W : <B>[L[equipment+1]]</B><BR>"
		t += "Lighting:     [add_lspace(lastused_light, 6)] W : <B>[L[lighting+1]]</B><BR>"
		t += "Environmental:[add_lspace(lastused_environ, 6)] W : <B>[L[environ+1]]</B><BR>"

		t += "<BR>Total load: [lastused_light + lastused_equip + lastused_environ] W</PRE>"
		t += "<HR>Cover lock: <B>[coverlocked ? "Engaged" : "Disengaged"]</B>"

	else
		t += "<I>(Swipe ID card to lock interface.)</I><BR>"
		t += "Main breaker: [operating ? "<B>On</B> <A href='?src=\ref[src];breaker=1'>Off</A>" : "<A href='?src=\ref[src];breaker=1'>On</A> <B>Off</B>" ]<BR>"
		t += "External power : <B>[ main_status ? (main_status ==2 ? "<FONT COLOR=#004000>Good</FONT>" : "<FONT COLOR=#D09000>Low</FONT>") : "<FONT COLOR=#F00000>None</FONT>"]</B><BR>"
		if(cell)
			t += "Power cell: <B>[round(cell.percent())]%</B>"
			t += " ([charging ? ( charging == 1 ? "Charging" : "Fully charged" ) : "Not charging"])"
			t += " ([chargemode ? "<A href='?src=\ref[src];cmode=1'>Off</A> <B>Auto</B>" : "<B>Off</B> <A href='?src=\ref[src];cmode=1'>Auto</A>"])"

		else
			t += "Power cell: <B><FONT COLOR=red>Not connected.</FONT></B>"

		t += "<BR><HR>Power channels<BR><PRE>"


		t += "Equipment:    [add_lspace(lastused_equip, 6)] W : "
		switch(equipment)
			if(0)
				t += "<B>Off</B> <A href='?src=\ref[src];eqp=2'>On</A> <A href='?src=\ref[src];eqp=3'>Auto</A>"
			if(1)
				t += "<A href='?src=\ref[src];eqp=1'>Off</A> <A href='?src=\ref[src];eqp=2'>On</A> <B>Auto (Off)</B>"
			if(2)
				t += "<A href='?src=\ref[src];eqp=1'>Off</A> <B>On</B> <A href='?src=\ref[src];eqp=3'>Auto</A>"
			if(3)
				t += "<A href='?src=\ref[src];eqp=1'>Off</A> <A href='?src=\ref[src];eqp=2'>On</A> <B>Auto (On)</B>"
		t +="<BR>"

		t += "Lighting:     [add_lspace(lastused_light, 6)] W : "

		switch(lighting)
			if(0)
				t += "<B>Off</B> <A href='?src=\ref[src];lgt=2'>On</A> <A href='?src=\ref[src];lgt=3'>Auto</A>"
			if(1)
				t += "<A href='?src=\ref[src];lgt=1'>Off</A> <A href='?src=\ref[src];lgt=2'>On</A> <B>Auto (Off)</B>"
			if(2)
				t += "<A href='?src=\ref[src];lgt=1'>Off</A> <B>On</B> <A href='?src=\ref[src];lgt=3'>Auto</A>"
			if(3)
				t += "<A href='?src=\ref[src];lgt=1'>Off</A> <A href='?src=\ref[src];lgt=2'>On</A> <B>Auto (On)</B>"
		t +="<BR>"


		t += "Environmental:[add_lspace(lastused_environ, 6)] W : "
		switch(environ)
			if(0)
				t += "<B>Off</B> <A href='?src=\ref[src];env=2'>On</A> <A href='?src=\ref[src];env=3'>Auto</A>"
			if(1)
				t += "<A href='?src=\ref[src];env=1'>Off</A> <A href='?src=\ref[src];env=2'>On</A> <B>Auto (Off)</B>"
			if(2)
				t += "<A href='?src=\ref[src];env=1'>Off</A> <B>On</B> <A href='?src=\ref[src];env=3'>Auto</A>"
			if(3)
				t += "<A href='?src=\ref[src];env=1'>Off</A> <A href='?src=\ref[src];env=2'>On</A> <B>Auto (On)</B>"



		t += "<BR>Total load: [lastused_light + lastused_equip + lastused_environ] W</PRE>"
		t += "<HR>Cover lock: [coverlocked ? "<B><A href='?src=\ref[src];lock=1'>Engaged</A></B>" : "<B><A href='?src=\ref[src];lock=1'>Disengaged</A></B>"]"

	t += "<BR><HR><A href='?src=\ref[src];close=1'>Close</A>"

	t += "</TT>"
	user << browse(t, "window=apc")
	return

/obj/machinery/power/apc/proc/report()
	return "[area.name] : [equipment]/[lighting]/[environ] ([lastused_equip+lastused_light+lastused_environ]) : [cell? cell.percent() : "N/C"] ([charging])"




/obj/machinery/power/apc/proc/update()
	if(operating)
		area.power_light = (lighting > 1)
		area.power_equip = (equipment > 1)
		area.power_environ = (environ > 1)
	else
		area.power_light = 0
		area.power_equip = 0
		area.power_environ = 0

	area.power_change()


/obj/machinery/power/apc/Topic(href, href_list)

	..()

	if (usr.stat || usr.restrained() )
		return
	if ((!( istype(usr, /mob/human) ) && (!( ticker ) || (ticker && ticker.mode != "monkey"))))
		usr << "\red You don't have the dexterity to do this!"
		return

	if (( (get_dist(src, usr) <= 1 && istype(src.loc, /turf))))

		usr.machine = src
		if (href_list["lock"])
			coverlocked = !coverlocked

		else if (href_list["breaker"])
			operating = !operating
			src.update()
			updateicon()

		else if (href_list["cmode"])
			chargemode = !chargemode
			if(!chargemode)
				charging = 0
				updateicon()

		else if (href_list["eqp"])
			var/val = text2num(href_list["eqp"])

			equipment = (val==1) ? 0 : val

			updateicon()
			update()

		else if (href_list["lgt"])
			var/val = text2num(href_list["lgt"])

			lighting = (val==1) ? 0 : val

			updateicon()
			update()
		else if (href_list["env"])
			var/val = text2num(href_list["env"])

			environ = (val==1) ? 0 :val

			updateicon()
			update()
		else if( href_list["close"] )
			usr << browse(null, "window=apc")
			usr.machine = null
			return


		for(var/mob/M in viewers(1, src))
			if ((M.client && M.machine == src))
				src.interact(M)
			//Foreach goto(275)
	else
		usr << browse(null, "window=apc")
		usr.machine = null

	return



#define CHARGELEVEL 500

/obj/machinery/power/apc/surplus()
	if(terminal)
		return terminal.surplus()
	else
		return 0

/obj/machinery/power/apc/add_load(var/amount)
	if(terminal && terminal.powernet)
		terminal.powernet.newload += amount

/obj/machinery/power/apc/avail()
	if(terminal)
		return terminal.avail()
	else
		return 0

/obj/machinery/power/apc/process()

	if(stat & BROKEN)
		return

	if(!area.requires_power)
		return

	area.calc_lighting()

	lastused_light = area.usage(LIGHT)
	lastused_equip = area.usage(EQUIP)
	lastused_environ = area.usage(ENVIRON)
	area.clear_usage()

	lastused_total = lastused_light + lastused_equip + lastused_environ


	//store states to update icon if any change
	var/last_lt = lighting
	var/last_eq = equipment
	var/last_en = environ
	var/last_ch = charging


	var/excess = surplus()

	if(!src.avail())
		main_status = 0
	else if(excess < 0)
		main_status = 1
	else
		main_status = 2

	var/perapc = 0
	if(terminal && terminal.powernet)
		perapc = terminal.powernet.perapc

	if(cell)

		// draw power from cell as before

		var/cellused = min(cell.charge, CELLRATE * lastused_total)	// clamp deduction to a max, amount left in cell

		cell.charge -= cellused



		// set channels depending on how much charge we have left


		if(cell.charge <= 0)					// zero charge, turn all off
			equipment = autoset(equipment, 2)
			lighting = autoset(lighting, 2)
			environ = autoset(environ, 2)
		else if(cell.percent() < 15)				// <15%, turn off lighting & equipment
			equipment = autoset(equipment, 2)
			lighting = autoset(lighting, 2)
			environ = autoset(environ, 1)
		else if(cell.percent() < 30)			// <30%, turn off equipment
			equipment = autoset(equipment, 2)
			lighting = autoset(lighting, 1)
			environ = autoset(environ, 1)
		else									// otherwise all can be on
			equipment = autoset(equipment, 1)
			lighting = autoset(lighting, 1)
			environ = autoset(environ, 1)


		if(excess > 0 || perapc > lastused_total)		// if power excess, or enough anyway, recharge the cell
														// by the same amount just used

			cell.charge = min(cell.maxcharge, cell.charge + cellused)

			add_load(cellused/CELLRATE)		// add the load used to recharge the cell


		else		// no excess, and not enough per-apc

			if( (cell.charge/CELLRATE+perapc) >= lastused_total)		// can we draw enough from cell+grid to cover last usage?

				cell.charge = min(cell.maxcharge, cell.charge + CELLRATE * perapc)	//recharge with what we can

				add_load(perapc)		// so draw what we can from the grid
				charging = 0

			else	// not enough!
				charging = 0			// kill everything
				chargecount = 0
				equipment = autoset(equipment, 0)
				lighting = autoset(lighting, 0)
				environ = autoset(environ, 0)



		// now trickle-charge the cell


		if(chargemode && charging == 1)
			if(excess > 0)		// check to make sure we have enough to charge

				var/ch = min(CHARGELEVEL, (cell.maxcharge - cell.charge)/CELLRATE )	// clamp charging to max free in cell

				ch = min(ch, perapc)	// clamp charging to our share

				add_load(CHARGELEVEL)

				cell.charge += ch * CELLRATE		// actually recharge the cell

			else

				charging = 0		// stop charging
				chargecount = 0



		// show cell as fully charged if so

		if(cell.charge >= cell.maxcharge)
			charging = 2


		if(chargemode)
			if(!charging)
				if(excess > CHARGELEVEL)
					chargecount++
				else
					chargecount = 0


				if(chargecount == 5)

					chargecount = 0
					charging = 1

		else // chargemode off
			charging = 0
			chargecount = 0




	else
		// no cell

		// for now, switch everything off

		charging = 0
		chargecount = 0
		equipment = autoset(equipment, 0)
		lighting = autoset(lighting, 0)
		environ = autoset(environ, 0)



	// update icon & area power if anything changed


	if(last_lt != lighting || last_eq != equipment || last_en != environ || last_ch != charging)
		updateicon()
		update()



	for(var/mob/M in viewers(1, src))
		if ((M.client && M.machine == src))
			src.interact(M)


// val 0=off, 1=off(auto) 2=on 3=on(auto)
// on 0=off, 1=on, 2=autooff

/proc/autoset(var/val, var/on)

	if(on==0)
		if(val==2)			// if on, return off
			return 0
		else if(val==3)		// if auto-on, return auto-off
			return 1

	else if(on==1)
		if(val==1)			// if auto-off, return auto-on
			return 3

	else if(on==2)
		if(val==3)			// if auto-on, return auto-off
			return 1

	return val

// damage and destruction acts

/obj/machinery/power/apc/meteorhit(var/obj/O as obj)

	set_broken()
	return

/obj/machinery/power/apc/ex_act(severity)

	switch(severity)
		if(1.0)
			set_broken()
			del(src)
			return
		if(2.0)
			if (prob(50))
				set_broken()
		if(3.0)
			if (prob(25))
				set_broken()
		else
	return

/obj/machinery/power/apc/blob_act()
	if (prob(50))
		set_broken()


/obj/machinery/power/apc/proc/set_broken()
	stat |= BROKEN
	icon_state = "apc-b"
	overlays = null

	operating = 0
	update()

// the underfloor wiring terminal for the APC
// autogenerated when an APC is placed
// all conduit connects go to this object instead of the APC
// using this solves the problem of having the APC in a wall yet also inside an area

/obj/machinery/power/terminal/New()

	..()

	var/turf/T = src.loc

	if(level==1) hide(T.intact)


/obj/machinery/power/terminal/hide(var/i)

	if(i)
		invisibility = 101
		icon_state = "term-f"
	else
		invisibility = 0
		icon_state = "term"



// dummy generator object for testing

/*/obj/machinery/power/generator/verb/set_amount(var/g as num)
	set src in view(1)

	gen_amount = g

*/

/obj/machinery/power/generator/New()
	..()

	spawn(5)
		circ1 = locate(/obj/machinery/circulator) in get_step(src,WEST)
		circ2 = locate(/obj/machinery/circulator) in get_step(src,EAST)
		if(!circ1 || !circ2)
			stat |= BROKEN

		updateicon()

/obj/machinery/power/generator/proc/updateicon()

	if(stat & (NOPOWER|BROKEN))
		overlays = null
	else
		overlays = null

		if(lastgenlev != 0)
			overlays += image('power.dmi', "teg-op[lastgenlev]")

		overlays += image('power.dmi', "teg-oc[c1on][c2on]")

#define GENRATE 0.0015			// generator output coefficient from Q

/obj/machinery/power/generator/process()

/*	if(circ && circ.gas1)
		var/gen = circ.gas2.tot_gas()*max(0, circ.gas2.temperature - 298)/300
		circ.ngas2.temperature = max(298, circ.ngas2.temperature - 50)

		add_avail(gen)
*/

	if(circ1 && circ2)


		var/gc = circ1.gas2.shc()
		var/gh = circ2.gas2.shc()

		var/tc = circ1.gas2.temperature
		var/th = circ2.gas2.temperature
		var/deltat = th-tc

		var/eta = (1-tc/th)*0.65		// efficiency 65% of Carnot

		if(gc > 0 && deltat >0)		// require some cold gas (for sink) and a positive temp gradient
			var/ghoc = gh/gc

			//var/qc = gc*tc
			//var/qh = gh*th

			var/fdt = 1/( (1-eta)*ghoc + 1)	// min timestep

			fdt = min(fdt, 0.1)	// max timestep

			var/q = fdt*eta*gh*(deltat)	// heat generated

			var/thp = th - fdt * deltat
			var/tcp = tc + fdt * (1 - eta) * (ghoc) * deltat

			lastgen = q * GENRATE
			add_avail(lastgen)

			circ1.ngas2.temperature = tcp
			circ2.ngas2.temperature = thp

		else
			lastgen = 0





		// update icon overlays only if displayed level has changed

		var/genlev = max(0, min( round(11*lastgen / 100000), 11))
		if(genlev != lastgenlev)
			lastgenlev = genlev
			updateicon()

		for(var/mob/M in viewers(1, src))
			if ((M.client && M.machine == src))
				src.interact(M)

/obj/machinery/power/generator/attack_hand(mob/user)

	add_fingerprint(user)

	if(stat & (BROKEN|NOPOWER)) return

	interact(user)



/obj/machinery/power/generator/proc/interact(mob/user)

	if ( (get_dist(src, user) > 1 ))
		user.machine = null
		user << browse(null, "window=teg")
		return

	user.machine = src

	var/t = "<PRE><B>Thermo-Electric Generator</B><HR>"

	t += "Output : [round(lastgen)] W<BR><BR>"

	t += "<B>Cold loop</B><BR>"
	t += "Temperature Inlet: [round(circ1.ngas1.temperature, 0.1)] K  Outlet: [round(circ1.ngas2.temperature, 0.1)] K<BR>"

	t += "Circulator: [c1on ? "<B>On</B> <A href = '?src=\ref[src];c1p=1'>Off</A>" : "<A href = '?src=\ref[src];c1p=1'>On</A> <B>Off</B> "]<BR>"
	t += "Rate: <A href = '?src=\ref[src];c1r=-3'>M</A> <A href = '?src=\ref[src];c1r=-2'>-</A> <A href = '?src=\ref[src];c1r=-1'>-</A> [add_lspace(c1rate,3)]% <A href = '?src=\ref[src];c1r=1'>+</A> <A href = '?src=\ref[src];c1r=2'>+</A> <A href = '?src=\ref[src];c1r=3'>M</A><BR>"

	t += "<B>Hot loop</B><BR>"
	t += "Temperature Inlet: [round(circ2.ngas1.temperature, 0.1)] K  Outlet: [round(circ2.ngas2.temperature, 0.1)] K<BR>"

	t += "Circulator: [c2on ? "<B>On</B> <A href = '?src=\ref[src];c2p=1'>Off</A>" : "<A href = '?src=\ref[src];c2p=1'>On</A> <B>Off</B> "]<BR>"
	t += "Rate: <A href = '?src=\ref[src];c2r=-3'>M</A> <A href = '?src=\ref[src];c2r=-2'>-</A> <A href = '?src=\ref[src];c2r=-1'>-</A> [add_lspace(c2rate,3)]% <A href = '?src=\ref[src];c2r=1'>+</A> <A href = '?src=\ref[src];c2r=2'>+</A> <A href = '?src=\ref[src];c2r=3'>M</A><BR>"

	t += "<BR><HR><A href='?src=\ref[src];close=1'>Close</A>"

	t += "</PRE>"
	user << browse(t, "window=teg;size=460x300")
	return

/obj/machinery/power/generator/Topic(href, href_list)
	..()

	if (usr.stat || usr.restrained() )
		return
	if ((!( istype(usr, /mob/human) ) && (!( ticker ) || (ticker && ticker.mode != "monkey"))))
		usr << "\red You don't have the dexterity to do this!"
		return

	//world << "[href] ; [href_list[href]]"

	if (( usr.machine==src && (get_dist(src, usr) <= 1 && istype(src.loc, /turf))))


		if( href_list["close"] )
			usr << browse(null, "window=teg")
			usr.machine = null
			return

		else if( href_list["c1p"] )
			c1on = !c1on
			circ1.control(c1on, c1rate)
			updateicon()
		else if( href_list["c2p"] )
			c2on = !c2on
			circ2.control(c2on, c2rate)
			updateicon()

		else if( href_list["c1r"] )

			var/i = text2num(href_list["c1r"])

			var/d = 0
			switch(i)
				if(-3)
					c1rate = 0
				if(3)
					c1rate = 100

				if(1)
					d = 1
				if(-1)
					d = -1
				if(2)
					d = 10
				if(-2)
					d = -10

			c1rate += d
			c1rate = max(1, min(100, c1rate))	// clamp to range

			circ1.control(c1on, c1rate)
			updateicon()

		else if( href_list["c2r"] )

			var/i = text2num(href_list["c2r"])

			var/d = 0
			switch(i)
				if(-3)
					c2rate = 0
				if(3)
					c2rate = 100

				if(1)
					d = 1
				if(-1)
					d = -1
				if(2)
					d = 10
				if(-2)
					d = -10

			c2rate += d
			c2rate = max(1, min(100, c2rate))	// clamp to range

			circ2.control(c2on, c2rate)
			updateicon()

		for(var/mob/M in viewers(1, src))
			if ((M.client && M.machine == src))
				src.interact(M)
			//Foreach goto(275)
	else
		usr << browse(null, "window=teg")
		usr.machine = null

	return

/obj/machinery/power/generator/power_change()
	..()
	updateicon()



// attach a wire to a power machine - leads from the turf you are standing on

/obj/machinery/power/attackby(obj/item/weapon/W, mob/user)

	if(istype(W, /obj/item/weapon/cable_coil))

		var/obj/item/weapon/cable_coil/coil = W

		var/turf/T = user.loc

		if(T.intact || !istype(T, /turf/station/floor))
			return

		if(get_dist(src, user) > 1)
			return

		if(!directwired)		// only for attaching to directwired machines
			return

		var/dirn = get_dir(user, src)


		for(var/obj/cable/LC in T)
			if(LC.d1 == dirn || LC.d2 == dirn)
				user << "There's already a cable at that position."
				return

		var/obj/cable/NC = new(T)
		NC.d1 = 0
		NC.d2 = dirn
		NC.add_fingerprint()
		NC.updateicon()
		NC.update_network()
		coil.use(1)
		return
	else
		..()
	return


// the power cable object

/obj/cable/New()
	..()


	// ensure d1 & d2 reflect the icon_state for entering and exiting cable

	var/dash = findtext(icon_state, "-")

	d1 = text2num( copytext( icon_state, 1, dash ) )

	d2 = text2num( copytext( icon_state, dash+1 ) )

	var/turf/T = src.loc			// hide if turf is not intact

	if(level==1) hide(T.intact)


/obj/cable/Del()		// called when a cable is deleted

	if(!defer_powernet_rebuild)	// set if network will be rebuilt manually

		if(netnum && powernets && powernets.len >= netnum)		// make sure cable & powernet data is valid
			var/datum/powernet/PN = powernets[netnum]
			PN.cut_cable(src)									// updated the powernets
	else
		if(Debug) world.log << "Defered cable deletion at [x],[y]: #[netnum]"
	..()													// then go ahead and delete the cable

/obj/cable/hide(var/i)

	invisibility = i ? 101 : 0
	updateicon()

/obj/cable/proc/updateicon()
	if(invisibility)
		//icon_state = "[d1]-[d2]"
		//icon -= rgb(0,0,0,128)
		icon_state = "[d1]-[d2]-f"
	else
		//icon = initial(icon)
		icon_state = "[d1]-[d2]"


/obj/cable/attackby(obj/item/weapon/W, mob/user)

	var/turf/T = src.loc
	if(T.intact)
		return

	if(istype(W, /obj/item/weapon/wirecutters))

		if(src.d1)	// 0-X cables are 1 unit, X-X cables are 2 units long
			new/obj/item/weapon/cable_coil(T, 2)
		else
			new/obj/item/weapon/cable_coil(T, 1)

		for(var/mob/O in viewers(src, null))
			O.show_message("[user] cuts the cable.", 1)

		shock(user, 50)

		defer_powernet_rebuild = 0		// to fix no-action bug
		del(src)

		return	// not needed, but for clarity


	else if(istype(W, /obj/item/weapon/cable_coil))
		var/obj/item/weapon/cable_coil/coil = W

		coil.cable_join(src, user)
		//note do shock in cable_join
	else
		shock(user, 10)

	src.add_fingerprint(user)

// shock the user with probability prb

/obj/cable/proc/shock(mob/user, prb)

	if(!prob(prb))
		return

	if(!netnum)		// unconnected cable is unpowered
		return

	var/datum/powernet/PN			// find the powernet
	if(powernets && powernets.len >= netnum)
		PN = powernets[netnum]

	if(PN && PN.avail > 0)		// is it powered?



		var/prot = 0

		if(istype(user, /mob/human))
			var/mob/human/H = user
			if(H.gloves)
				var/obj/item/weapon/clothing/gloves/G = H.gloves

				prot = G.elec_protect

		if(prot == 10)		// elec insulted gloves protect completely
			return

		prot++

		var/obj/effects/sparks/O = new /obj/effects/sparks( src.loc )
		O.dir = pick(NORTH, SOUTH, EAST, WEST)
		spawn( 0 )
			O.Life()

		if(PN.avail > 10000)
			user.burn(5e7/prot)

		user << "\red <B>You feel a powerful shock course through your body!</B>"
		sleep(1)

		user.stunned = 120/prot
		user.weakened = 20/prot
		//Foreach goto(72)
		for(var/mob/M in hearers(src, null))
			if(M == user)
				continue
			if (!( M.blinded ))
				M << "\red [user.name] was shocked by the cable!"
			else
				M << "\red You hear a heavy electrical crack."





/obj/cable/ex_act(severity)

	switch(severity)
		if(1.0)
			del(src)
		if(2.0)
			if (prob(50))
				new/obj/item/weapon/cable_coil(src.loc, src.d1 ? 2 : 1)
				del(src)

		if(3.0)
			if (prob(25))
				new/obj/item/weapon/cable_coil(src.loc, src.d1 ? 2 : 1)
				del(src)
		else
	return

/obj/cable/burn(fi_amount)

	if(fi_amount > 1800000)
		var/turf/T = src.loc
		if(!T.intact)
			if(prob(10))
				defer_powernet_rebuild = 0
				del(src)




// the cable coil object, used for laying cable

/obj/item/weapon/cable_coil/New(loc, length = MAXCOIL)
	src.amount = length
	pixel_x = rand(-2,2)
	pixel_y = rand(-2,2)
	updateicon()
	..(loc)


/obj/item/weapon/cable_coil/proc/updateicon()
	if(amount == 1)
		icon_state = "coil1"
		name = "cable piece"
	else if(amount == 2)
		icon_state = "coil2"
		name = "cable piece"
	else
		icon_state = "coil"
		name = "cable coil"

/obj/item/weapon/cable_coil/examine()
	set src in view(1)

	if(amount == 1)
		usr << "A short piece of power cable."
	else if(amount == 1)
		usr << "A piece of power cable."
	else
		usr << "A coil of power cable. There are [amount] lengths of cable in the coil."



/obj/item/weapon/cable_coil/attackby(obj/item/weapon/W, mob/user)

	if( istype(W, /obj/item/weapon/wirecutters) && src.amount > 1)
		src.amount--
		new/obj/item/weapon/cable_coil(user.loc, 1)
		user << "You cut a piece off the cable coil."
		src.updateicon()
		return

	else if( istype(W, /obj/item/weapon/cable_coil) )
		var/obj/item/weapon/cable_coil/C = W
		if(C.amount == MAXCOIL)
			user << "The coil is too long, you cannot add any more cable to it."
			return

		if( (C.amount + src.amount <= MAXCOIL) )
			C.amount += src.amount
			user << "You join the cable coils together."
			C.updateicon()
			del(src)
			return

		else
			user << "You transfer [MAXCOIL - src.amount ] length\s of cable from one coil to the other."
			src.amount -= (MAXCOIL-C.amount)
			src.updateicon()
			C.amount = MAXCOIL
			C.updateicon()
			return



/obj/item/weapon/cable_coil/proc/use(var/used)
	if(src.amount < used)
		return 0
	else if (src.amount == used)
		del(src)
	else
		amount -= used
		updateicon()
		return 1



// called when cable_coil is clicked on a turf/station/floor

/obj/item/weapon/cable_coil/proc/turf_place(turf/station/floor/F, mob/user)

	if(!isturf(user.loc))
		return

	if(get_dist(F,user) > 1)
		user << "You can't lay cable at a place that far away."
		return

	if(F.intact)		// if floor is intact, complain
		user << "You can't lay cable there unless the floor tiles are removed."
		return

	else
		var/dirn

		if(user.loc == F)
			dirn = user.dir			// if laying on the tile we're on, lay in the direction we're facing
		else
			dirn = get_dir(F, user)

		for(var/obj/cable/LC in F)
			if(LC.d1 == dirn || LC.d2 == dirn)
				user << "There's already a cable at that position."
				return

		var/obj/cable/C = new(F)
		C.d1 = 0
		C.d2 = dirn
		C.add_fingerprint(user)
		C.updateicon()
		C.update_network()
		use(1)
		//src.laying = 1
		//last = C


// called when cable_coil is click on an installed obj/cable

/obj/item/weapon/cable_coil/proc/cable_join(obj/cable/C, mob/user)


	var/turf/U = user.loc
	if(!isturf(U))
		return

	var/turf/T = C.loc

	if(!isturf(T) || T.intact)		// sanity checks, also stop use interacting with T-scanner revealed cable
		return

	if(get_dist(C, user) > 1)		// make sure it's close enough
		user << "You can't lay cable at a place that far away."
		return


	if(U == T)		// do nothing if we clicked a cable we're standing on
		return		// may change later if can think of something logical to do

	var/dirn = get_dir(C, user)

	if(C.d1 == dirn || C.d2 == dirn)		// one end of the clicked cable is pointing towards us
		if(U.intact)						// can't place a cable if the floor is complete
			user << "You can't lay cable there unless the floor tiles are removed."
			return
		else
			// cable is pointing at us, we're standing on an open tile
			// so create a stub pointing at the clicked cable on our tile

			var/fdirn = turn(dirn, 180)		// the opposite direction

			for(var/obj/cable/LC in U)		// check to make sure there's not a cable there already
				if(LC.d1 == fdirn || LC.d2 == fdirn)
					user << "There's already a cable at that position."
					return

			var/obj/cable/NC = new(U)
			NC.d1 = 0
			NC.d2 = fdirn
			NC.add_fingerprint()
			NC.updateicon()
			NC.update_network()
			use(1)
			C.shock(user, 25)

			return
	else if(C.d1 == 0)		// exisiting cable doesn't point at our position, so see if it's a stub
							// if so, make it a full cable pointing from it's old direction to our dirn

		var/nd1 = C.d2	// these will be the new directions
		var/nd2 = dirn

		if(nd1 > nd2)		// swap directions to match icons/states
			nd1 = dirn
			nd2 = C.d2


		for(var/obj/cable/LC in T)		// check to make sure there's no matching cable
			if(LC == C)			// skip the cable we're interacting with
				continue
			if(LC.d1 == nd1 || LC.d2 == nd1 || LC.d1 == nd2 || LC.d2 == nd2)	// make sure no cable matches either direction
				user << "There's already a cable at that position."
				return
		C.shock(user, 25)
		del(C)
		var/obj/cable/NC = new(T)
		NC.d1 = nd1
		NC.d2 = nd2
		NC.add_fingerprint()
		NC.updateicon()
		NC.update_network()

		use(1)

		return


// called when a new cable is created
// can be 1 of 3 outcomes:
// 1. Isolated cable (or only connects to isolated machine) -> create new powernet
// 2. Joins to end or bridges loop of a single network (may also connect isolated machine) -> add to old network
// 3. Bridges gap between 2 networks -> merge the networks (must rebuild lists also)



/obj/cable/proc/update_network()
	// easy way: do /makepowernets again
	makepowernets()
	// do things more logically if this turns out to be too slow
	// may just do this for case 3 anyway (simpler than refreshing list)







// the powernet datum
// each contiguous network of cables & nodes


// rebuild all power networks from scratch

/proc/makepowernets()

	var/netcount = 0
	powernets = list()

	for(var/obj/cable/PC in world)
		PC.netnum = 0
	for(var/obj/machinery/power/M in machines)
		if(M.netnum >=0)
			M.netnum = 0


	for(var/obj/cable/PC in world)
		if(!PC.netnum)
			PC.netnum = ++netcount

			if(Debug) world.log << "Starting mpn at [PC.x],[PC.y] ([PC.d1]/[PC.d2]) #[netcount]"
			powernet_nextlink(PC, PC.netnum)

	if(Debug) world.log << "[netcount] powernets found"

	for(var/L = 1 to netcount)
		var/datum/powernet/PN = new()
		//PN.tag = "powernet #[L]"
		powernets += PN
		PN.number = L


	for(var/obj/cable/C in world)
		var/datum/powernet/PN = powernets[C.netnum]
		PN.cables += C

	for(var/obj/machinery/power/M in machines)
		if(M.netnum<=0)		// APCs have netnum=-1 so they don't count as network nodes directly
			continue

		M.powernet = powernets[M.netnum]
		M.powernet.nodes += M





// returns a list of all power-related objects (nodes, cable, junctions) in turf,
// excluding source, that match the direction d
// if unmarked==1, only return those with netnum==0

/proc/power_list(var/turf/T, var/source, var/d, var/unmarked=0)
	var/list/result = list()
	var/fdir = (!d)? 0 : turn(d, 180)	// the opposite direction to d (or 0 if d==0)

	for(var/obj/machinery/power/P in T)
		if(P.netnum < 0)	// exclude APCs
			continue

		if(P.directwired)	// true if this machine covers the whole turf (so can be joined to a cable on neighbour turf)
			if(!unmarked || !P.netnum)
				result += P
		else if(d == 0)		// otherwise, need a 0-X cable on same turf to connect
			if(!unmarked || !P.netnum)
				result += P


	for(var/obj/cable/C in T)
		if(C.d1 == fdir || C.d2 == fdir)
			if(!unmarked || !C.netnum)
				result += C

	result -= source

	return result


/obj/cable/proc/get_connections()

	var/list/res = list()	// this will be a list of all connected power objects

	var/turf/T
	if(!d1)
		T = src.loc		// if d1=0, same turf as src
	else
		T = get_step(src, d1)

	res += power_list(T, src , d1, 1)

	T = get_step(src, d2)

	res += power_list(T, src, d2, 1)

	return res


/obj/machinery/power/proc/get_connections()

	if(!directwired)
		return get_indirect_connections()

	var/list/res = list()
	var/cdir

	for(var/turf/T in orange(1, src))

		cdir = get_dir(T, src)

		for(var/obj/cable/C in T)

			if(C.netnum)
				continue

			if(C.d1 == cdir || C.d2 == cdir)
				res += C

	return res

/obj/machinery/power/proc/get_indirect_connections()

	var/list/res = list()

	for(var/obj/cable/C in src.loc)

		if(C.netnum)
			continue

		if(C.d1 == 0)
			res += C

	return res


/proc/powernet_nextlink(var/obj/O, var/num)

	var/list/P

	//world.log << "start: [O] at [O.x].[O.y]"


	while(1)

		if( istype(O, /obj/cable) )
			var/obj/cable/C = O

			C.netnum = num

		else if( istype(O, /obj/machinery/power) )

			var/obj/machinery/power/M = O

			M.netnum = num


		if( istype(O, /obj/cable) )
			var/obj/cable/C = O

			P = C.get_connections()

		else if( istype(O, /obj/machinery/power) )

			var/obj/machinery/power/M = O

			P = M.get_connections()

		if(P.len == 0)
			//world.log << "end1"
			return

		O = P[1]


		for(var/L = 2 to P.len)

			powernet_nextlink(P[L], num)

		//world.log << "next: [O] at [O.x].[O.y]"







// cut a powernet at this cable object

/datum/powernet/proc/cut_cable(var/obj/cable/C)

	var/turf/T1 = C.loc
	if(C.d1)
		T1 = get_step(C, C.d1)

	var/turf/T2 = get_step(C, C.d2)

	var/list/P1 = power_list(T1, C, C.d1)	// what joins on to cut cable in dir1

	var/list/P2 = power_list(T2, C, C.d2)	// what joins on to cut cable in dir2

	if(Debug)
		for(var/obj/O in P1)
			world.log << "P1: [O] at [O.x] [O.y] : [istype(O, /obj/cable) ? "[O:d1]/[O:d2]" : null] "
		for(var/obj/O in P2)
			world.log << "P2: [O] at [O.x] [O.y] : [istype(O, /obj/cable) ? "[O:d1]/[O:d2]" : null] "



	if(P1.len == 0 || P2.len ==0)			// if nothing in either list, then the cable was an endpoint
											// no need to rebuild the powernet, just remove cut cable from the list
		cables -= C
		if(Debug) world.log << "Was end of cable"
		return

	// zero the netnum of all cables & nodes in this powernet

	for(var/obj/cable/OC in cables)
		OC.netnum = 0
	for(var/obj/machinery/power/OM in nodes)
		OM.netnum = 0


	// remove the cut cable from the network
	C.netnum = -1
	C.loc = null
	cables -= C




	powernet_nextlink(P1[1], number)		// propagate network from 1st side of cable, using current netnum

	// now test to see if propagation reached to the other side
	// if so, then there's a loop in the network

	var/notlooped = 0
	for(var/obj/O in P2)
		if( istype(O, /obj/machinery/power) )
			var/obj/machinery/power/OM = O
			if(OM.netnum != number)
				notlooped = 1
				break
		else if( istype(O, /obj/cable) )
			var/obj/cable/OC = O
			if(OC.netnum != number)
				notlooped = 1
				break

	if(notlooped)

		// not looped, so make a new powernet

		var/datum/powernet/PN = new()
		//PN.tag = "powernet #[L]"
		powernets += PN
		PN.number = powernets.len

		if(Debug) world.log << "Was not looped: spliting PN#[number] ([cables.len];[nodes.len])"

		for(var/obj/cable/OC in cables)

			if(!OC.netnum)		// non-connected cables will have netnum==0, since they weren't reached by propagation

				OC.netnum = PN.number
				cables -= OC
				PN.cables += OC		// remove from old network & add to new one

		for(var/obj/machinery/power/OM in nodes)
			if(!OM.netnum)
				OM.netnum = PN.number
				OM.powernet = PN
				nodes -= OM
				PN.nodes += OM		// same for power machines

		if(Debug)
			world.log << "Old PN#[number] : ([cables.len];[nodes.len])"
			world.log << "New PN#[PN.number] : ([PN.cables.len];[PN.nodes.len])"

	else
		if(Debug)
			world.log << "Was looped."
		//there is a loop, so nothing to be done
		return

	return



/datum/powernet/proc/reset()
	load = newload
	newload = 0
	avail = newavail
	newavail = 0


	viewload = 0.8*viewload + 0.2*load

	viewload = round(viewload)

	var/numapc = 0

	for(var/obj/machinery/power/terminal/term in nodes)
		if( istype( term.master, /obj/machinery/power/apc ) )
			numapc++

	if(numapc)
		perapc = avail/numapc

	netexcess = avail - load

	if( netexcess > 100)		// if there was excess power last cycle
		for(var/obj/machinery/power/smes/S in nodes)	// find the SMESes in the network
			S.restore()				// and restore some of the power that was used



// the power monitoring computer
// for the moment, just report the status of all APCs in the same powernet

/obj/machinery/power/monitor/attack_hand(mob/user)
	add_fingerprint(user)

	if(stat & (BROKEN|NOPOWER))
		return
	interact(user)


/obj/machinery/power/monitor/proc/interact(mob/user)

	if ( (get_dist(src, user) > 1 ) || (stat & (BROKEN|NOPOWER)) )
		user.machine = null
		user << browse(null, "window=powcomp")
		return


	user.machine = src
	var/t = "<TT><B>Power Monitoring</B><HR>"


	if(!powernet)
		t += "\red No connection"
	else

		var/list/L = list()
		for(var/obj/machinery/power/terminal/term in powernet.nodes)
			if(istype(term.master, /obj/machinery/power/apc))
				var/obj/machinery/power/apc/A = term.master
				L += A

		t += "<PRE>Total power: [powernet.avail] W<BR>Total load:  [num2text(powernet.viewload,10)] W<BR>"

		t += "<FONT SIZE=-1>"

		if(L.len > 0)

			t += "Area                           Eqp./Lgt./Env.  Load   Cell<HR>"

			var/list/S = list(" Off","AOff","  On", " AOn")
			var/list/chg = list("N","C","F")

			for(var/obj/machinery/power/apc/A in L)

				t += copytext(add_tspace(A.area.name, 30), 1, 30)
				t += " [S[A.equipment+1]] [S[A.lighting+1]] [S[A.environ+1]] [add_lspace(A.lastused_total, 6)]  [A.cell ? "[add_lspace(round(A.cell.percent()), 3)]% [chg[A.charging+1]]" : "  N/C"]<BR>"

		t += "</FONT></PRE>"

	t += "<BR><HR><A href='?src=\ref[src];close=1'>Close</A></TT>"

	user << browse(t, "window=powcomp;size=420x700")


/obj/machinery/power/monitor/Topic(href, href_list)
	..()
	if( href_list["close"] )
		usr << browse(null, "window=powcomp")
		usr.machine = null
		return

/obj/machinery/power/monitor/process()
	if(!(stat & (NOPOWER|BROKEN)) )

		use_power(250)


	for(var/mob/M in viewers(1, src))
		if ((M.client && M.machine == src))
			src.interact(M)



/obj/machinery/power/monitor/power_change()

	if(stat & BROKEN)
		icon_state = "broken"
	else
		if( powered() )
			icon_state = initial(icon_state)
			stat &= ~NOPOWER
		else
			spawn(rand(0, 15))
				src.icon_state = "c_unpowered"
				stat |= NOPOWER


// the SMES
// stores power

/obj/machinery/power/smes/New()
	..()

	spawn(5)
		dir_loop:
			for(var/d in cardinal)
				var/turf/T = get_step(src, d)
				for(var/obj/machinery/power/terminal/term in T)
					if(term && term.dir == turn(d, 180))
						terminal = term
						break dir_loop

		if(!terminal)
			stat |= BROKEN
			return

		terminal.master = src

		updateicon()


/obj/machinery/power/smes/proc/updateicon()

	overlays = null
	if(stat & BROKEN)
		return


	overlays += image('power.dmi', "smes-op[online]")

	if(charging)
		overlays += image('power.dmi', "smes-oc1")
	else
		if(chargemode)
			overlays += image('power.dmi', "smes-oc0")

	var/clevel = chargedisplay()
	if(clevel>0)
		overlays += image('power.dmi', "smes-og[clevel]")

/obj/machinery/power/smes/proc/chargedisplay()
	return round(5.5*charge/capacity)

#define SMESRATE 0.05			// rate of internal charge to external power


/obj/machinery/power/smes/process()

	if(stat & BROKEN)
		return


	//store machine state to see if we need to update the icon overlays
	var/last_disp = chargedisplay()
	var/last_chrg = charging
	var/last_onln = online

	if(terminal)
		var/excess = terminal.surplus()

		if(charging)
			if(excess >= 0)		// if there's power available, try to charge

				var/load = min((capacity-charge)/SMESRATE, chargelevel)		// charge at set rate, limited to spare capacity

				charge += load * SMESRATE	// increase the charge

				add_load(load)		// add the load to the terminal side network

			else					// if not enough capcity
				charging = 0		// stop charging
				chargecount  = 0

		else
			if(chargemode)
				if(chargecount > rand(3,10))
					charging = 1
					chargecount = 0

				if(excess > chargelevel)
					chargecount++
				else
					chargecount = 0
			else
				chargecount = 0

	if(online)		// if outputting
		lastout = min( charge/SMESRATE, output)		//limit output to that stored

		charge -= lastout*SMESRATE		// reduce the storage (may be recovered in /restore() if excessive)

		add_avail(lastout)				// add output to powernet (smes side)

		if(charge < 0.0001)
			online = 0					// stop output if charge falls to zero

	// only update icon if state changed
	if(last_disp != chargedisplay() || last_chrg != charging || last_onln != online)
		updateicon()

	for(var/mob/M in viewers(1, src))
		if ((M.client && M.machine == src))
			src.interact(M)


// called after all power processes are finished
// restores charge level to smes if there was excess this ptick

/obj/machinery/power/smes/proc/restore()
	if(stat & BROKEN)
		return

	if(!online)
		loaddemand = 0
		return

	var/excess = powernet.netexcess		// this was how much wasn't used on the network last ptick, minus any removed by other SMESes

	excess = min(lastout, excess)				// clamp it to how much was actually output by this SMES last ptick

	excess = min((capacity-charge)/SMESRATE, excess)	// for safety, also limit recharge by space capacity of SMES (shouldn't happen)

	// now recharge this amount

	var/clev = chargedisplay()

	charge += excess * SMESRATE
	powernet.netexcess -= excess		// remove the excess from the powernet, so later SMESes don't try to use it

	loaddemand = lastout-excess

	if(clev != chargedisplay() )
		updateicon()


/obj/machinery/power/smes/add_load(var/amount)
	if(terminal && terminal.powernet)
		terminal.powernet.newload += amount

/obj/machinery/power/smes/attack_hand(mob/user)

	add_fingerprint(user)

	if(stat & BROKEN) return

	interact(user)



/obj/machinery/power/smes/proc/interact(mob/user)

	if ( (get_dist(src, user) > 1 ))
		user.machine = null
		user << browse(null, "window=smes")
		return

	user.machine = src


	var/t = "<TT><B>SMES Power Storage Unit</B> [n_tag? "([n_tag])" : null]<HR><PRE>"

	t += "Stored capacity : [round(100.0*charge/capacity, 0.1)]%<BR><BR>"

	t += "Input: [charging ? "Charging" : "Not Charging"]    [chargemode ? "<B>Auto</B> <A href = '?src=\ref[src];cmode=1'>Off</A>" : "<A href = '?src=\ref[src];cmode=1'>Auto</A> <B>Off</B> "]<BR>"


	t += "Input level:  <A href = '?src=\ref[src];input=-4'>M</A> <A href = '?src=\ref[src];input=-3'>-</A> <A href = '?src=\ref[src];input=-2'>-</A> <A href = '?src=\ref[src];input=-1'>-</A> [add_lspace(chargelevel,5)] <A href = '?src=\ref[src];input=1'>+</A> <A href = '?src=\ref[src];input=2'>+</A> <A href = '?src=\ref[src];input=3'>+</A> <A href = '?src=\ref[src];input=4'>M</A><BR>"

	t += "<BR><BR>"

	t += "Output: [online ? "<B>Online</B> <A href = '?src=\ref[src];online=1'>Offline</A>" : "<A href = '?src=\ref[src];online=1'>Online</A> <B>Offline</B> "]<BR>"

	t += "Output level: <A href = '?src=\ref[src];output=-4'>M</A> <A href = '?src=\ref[src];output=-3'>-</A> <A href = '?src=\ref[src];output=-2'>-</A> <A href = '?src=\ref[src];output=-1'>-</A> [add_lspace(output,5)] <A href = '?src=\ref[src];output=1'>+</A> <A href = '?src=\ref[src];output=2'>+</A> <A href = '?src=\ref[src];output=3'>+</A> <A href = '?src=\ref[src];output=4'>M</A><BR>"

	t += "Output load: [round(loaddemand)] W<BR>"

	t += "<BR></PRE><HR><A href='?src=\ref[src];close=1'>Close</A>"

	t += "</TT>"
	user << browse(t, "window=smes;size=460x300")
	return

/obj/machinery/power/smes/Topic(href, href_list)
	..()

	if (usr.stat || usr.restrained() )
		return
	if ((!( istype(usr, /mob/human) ) && (!( ticker ) || (ticker && ticker.mode != "monkey"))))
		usr << "\red You don't have the dexterity to do this!"
		return

	//world << "[href] ; [href_list[href]]"

	if (( usr.machine==src && (get_dist(src, usr) <= 1 && istype(src.loc, /turf))))


		if( href_list["close"] )
			usr << browse(null, "window=smes")
			usr.machine = null
			return

		else if( href_list["cmode"] )
			chargemode = !chargemode
			if(!chargemode)
				charging = 0
			updateicon()

		else if( href_list["online"] )
			online = !online
			updateicon()
		else if( href_list["input"] )

			var/i = text2num(href_list["input"])

			var/d = 0
			switch(i)
				if(-4)
					chargelevel = 0
				if(4)
					chargelevel = SMESMAXCHARGELEVEL		//30000

				if(1)
					d = 100
				if(-1)
					d = -100
				if(2)
					d = 1000
				if(-2)
					d = -1000
				if(3)
					d = 10000
				if(-3)
					d = -10000

			chargelevel += d
			chargelevel = max(0, min(SMESMAXCHARGELEVEL, chargelevel))	// clamp to range

		else if( href_list["output"] )

			var/i = text2num(href_list["output"])

			var/d = 0
			switch(i)
				if(-4)
					output = 0
				if(4)
					output = SMESMAXOUTPUT		//30000

				if(1)
					d = 100
				if(-1)
					d = -100
				if(2)
					d = 1000
				if(-2)
					d = -1000
				if(3)
					d = 10000
				if(-3)
					d = -10000

			output += d
			output = max(0, min(SMESMAXOUTPUT, output))	// clamp to range


		for(var/mob/M in viewers(1, src))
			if ((M.client && M.machine == src))
				src.interact(M)
			//Foreach goto(275)
	else
		usr << browse(null, "window=smes")
		usr.machine = null

	return


/obj/machinery/power/solar/New()
	..()
	spawn(10)
		updateicon()
		updatefrac()

		if(powernet)
			for(var/obj/machinery/power/solar_control/SC in powernet.nodes)
				if(SC.id == id)
					control = SC

/obj/machinery/power/solar/proc/updateicon()
	src.overlays = null
	if(stat & BROKEN)
		overlays += image('power.dmi', "solar_panel-b", FLY_LAYER)
	else
		overlays += image('power.dmi', "solar_panel", FLY_LAYER, adir)

/obj/machinery/power/solar/proc/updatefrac()

	if(obscured)
		sunfrac = 0
		return

	var/p_angle = dir2angle(adir) - sun.angle

	if(abs(p_angle) > 90)			// if facing more than 90deg from sun, zero output
		sunfrac = 0
		return

	sunfrac = cos(p_angle)*cos(p_angle)			//

#define SOLARGENRATE 1500

/obj/machinery/power/solar/process()

	if(stat & BROKEN)
		return

	if(!obscured)
		var/sgen = SOLARGENRATE * sunfrac
		add_avail(sgen)
		if(powernet && control)
			if(control in powernet.nodes)
				control.gen += sgen


	if(adir == ndir)
		turn_angle = 0
	else
		spawn(rand(0,10))
			adir = turn(adir, turn_angle)
			updateicon()
			updatefrac()

/obj/machinery/power/solar/proc/broken()
	stat |= BROKEN
	updateicon()

/obj/machinery/power/solar/meteorhit()

	broken()
	return

/obj/machinery/power/solar/ex_act(severity)

	switch(severity)
		if(1.0)
			//SN src = null
			del(src)
			return
		if(2.0)
			if (prob(50))
				broken()
		if(3.0)
			if (prob(25))
				broken()
	return

/obj/machinery/power/solar/blob_act()
	if (prob(50))
		broken()
		src.density = 0


/obj/machinery/power/solar_control/New()
	..()

	spawn(15)

		if(powernet)
			for(var/obj/machinery/power/solar/S in powernet.nodes)
				if(S.id == id)
					cdir = S.adir
						updateicon()



/obj/machinery/power/solar_control/proc/updateicon()
	if(stat & BROKEN)
		icon_state = "broken"
		overlays = null
		return
	if(stat & NOPOWER)
		icon_state = "c_unpowered"
		overlays = null
		return

	icon_state = "solar_con"
	overlays = null
	if(cdir > 0)
		overlays += image('enginecomputer.dmi', "solcon-o", FLY_LAYER, cdir)



/obj/machinery/power/solar_control/attack_hand(mob/user)

	add_fingerprint(user)

	if(stat & (BROKEN | NOPOWER)) return

	interact(user)

/obj/machinery/power/solar_control/process()
	lastgen = gen
	gen = 0

	if(stat & (NOPOWER | BROKEN))
		return

	use_power(250)

	if(track && nexttime < world.timeofday)
		if(trackdir)
			cdir = turn(cdir, -45)
		else
			cdir = turn(cdir, 45)
		set_panels(cdir)

		nexttime = world.timeofday + 10*trackrate
		updateicon()


	for(var/mob/M in viewers(1, src))
		if ((M.client && M.machine == src))
			src.interact(M)


/obj/machinery/power/solar_control/proc/interact(mob/user)

	if ( (get_dist(src, user) > 1 ))
		user.machine = null
		user << browse(null, "window=solcon")
		return

	user.machine = src

	var/t = "<TT><B>Solar Generator Control</B><HR><PRE>"

	t += "Generated power : [round(lastgen)] W<BR><BR>"

	t += "Current panel orientation: <B>[uppertext(dir2text(cdir))]</B><BR>"

	t += "<HR>Set orientation:<BR>"

	var/list/D = list(-1, NORTHWEST, NORTH, NORTHEAST, -1, WEST, 0, EAST, -1, SOUTHWEST, SOUTH, SOUTHEAST)
	var/list/disp = list("|", "|", "", "-", "/", "\\", "", "-", "\\", "/")

	for(var/d in D)
		if(d == 0)
			t += "  "
			continue
		if(d == -1)
			t += "<BR>          "
			continue

		if(d==cdir)
			t +=" [disp[d]]"
		else
			t +=" <A href='?src=\ref[src];dir=[d]'>O</A>"


	t += "<HR><BR><BR>"

	t += "Tracking: [ track ? "<A href='?src=\ref[src];track=1'>Off</A> <B>On</B>" : "<B>Off</B> <A href='?src=\ref[src];track=1'>On</A>"]"

	t += "   [trackdir ? "<A href='?src=\ref[src];tdir=1'>CCW</A> <B>CW</B>" : "<B>CCW</B> <A href='?src=\ref[src];tdir=1'>CW</A>"]<BR>"

	t += "Rate:     <A href='?src=\ref[src];trk=-3'>-</A> <A href='?src=\ref[src];trk=-2'>-</A> <A href='?src=\ref[src];trk=-1'>-</A> [trackrate] <A href='?src=\ref[src];trk=1'>+</A> <A href='?src=\ref[src];trk=2'>+</A> <A href='?src=\ref[src];trk=3'>+</A> (seconds per turn)<BR>"

	t += "</PRE><HR><A href='?src=\ref[src];close=1'>Close</A>"

	t += "</TT>"
	user << browse(t, "window=solcon")

	return

/obj/machinery/power/solar_control/Topic(href, href_list)
	..()

	if (usr.stat || usr.restrained() )
		return
	if ((!( istype(usr, /mob/human) ) && (!( ticker ) || (ticker && ticker.mode != "monkey"))))
		usr << "\red You don't have the dexterity to do this!"
		return

	//world << "[href] ; [href_list[href]]"

	if (( usr.machine==src && (get_dist(src, usr) <= 1 && istype(src.loc, /turf))))


		if( href_list["close"] )
			usr << browse(null, "window=solcon")
			usr.machine = null
			return

		else if( href_list["dir"] )
			cdir = text2num(href_list["dir"])

			spawn(1)
				set_panels(cdir)

			updateicon()
		else if( href_list["tdir"] )
			trackdir = !trackdir

		else if( href_list["track"] )
			track = !track
			nexttime = world.timeofday + 10*trackrate

		else if( href_list["trk"] )
			var/inc = text2num(href_list["trk"])

			switch(inc)
				if(1, -1)
					trackrate += inc
				if(2,-2)
					trackrate += 10*inc/abs(inc)
				if(3,-3)
					trackrate += 100*inc/abs(inc)

			trackrate = min( max(trackrate, 10), 900)
			nexttime = world.timeofday + 10*trackrate

		spawn(0)
			for(var/mob/M in viewers(1, src))
				if ((M.client && M.machine == src))
					src.interact(M)

	else
		usr << browse(null, "window=solcon")
		usr.machine = null

	return

/obj/machinery/power/solar_control/proc/set_panels(var/cdir)
	if(powernet)
		for(var/obj/machinery/power/solar/S in powernet.nodes)
			if(S.id == id)
				S.control = src

				var/delta = dir2angle(S.adir) - dir2angle(cdir)

				delta = (delta+360)%360

				if(delta>180)
					S.turn_angle = -45
				else
					S.turn_angle = 45

				S.ndir = cdir


/obj/machinery/power/solar_control/power_change()

	if( powered() )
		stat &= ~NOPOWER
		updateicon()
	else
		spawn(rand(0, 15))
			stat |= NOPOWER
			updateicon()



/obj/machinery/power/solar_control/proc/broken()
	stat |= BROKEN
	updateicon()

/obj/machinery/power/solar_control/meteorhit()

	broken()
	return

/obj/machinery/power/solar_control/ex_act(severity)

	switch(severity)
		if(1.0)
			//SN src = null
			del(src)
			return
		if(2.0)
			if (prob(50))
				broken()
		if(3.0)
			if (prob(25))
				broken()
	return

/obj/machinery/power/solar_control/blob_act()
	if (prob(50))
		broken()
		src.density = 0


// the inlet stage of the gas turbine electricity generator

/obj/machinery/compressor/New()
	..()

	gas = new/obj/substance/gas(src)
	gas.maximum = capacity
	inturf = get_step(src, WEST)

	spawn(5)
		turbine = locate() in get_step(src, EAST)
		if(!turbine)
			stat |= BROKEN


#define COMPFRICTION 5e5
#define COMPSTARTERLOAD 2800

/obj/machinery/compressor/process()

	overlays = null
	if(stat & BROKEN)
		return

	rpm = 0.9* rpm + 0.1 * rpmtarget


	gas.turf_take(inturf, rpm/30000*capacity)


	rpm = max(0, rpm - (rpm*rpm)/COMPFRICTION)


	if(starter && !(stat & NOPOWER))
		use_power(2800)
		if(rpm<1000)
			rpmtarget = 1000
		else
			starter = 0
	else
		if(rpm<1000)
			rpmtarget = 0



	if(rpm>50000)
		overlays += image('pipes.dmi', "comp-o4", FLY_LAYER)
	else if(rpm>10000)
		overlays += image('pipes.dmi', "comp-o3", FLY_LAYER)
	else if(rpm>2000)
		overlays += image('pipes.dmi', "comp-o2", FLY_LAYER)
	if(rpm>500)
		overlays += image('pipes.dmi', "comp-o1", FLY_LAYER)


/obj/machinery/power/turbine/New()
	..()

	outturf = get_step(src, EAST)

	spawn(5)

		compressor = locate() in get_step(src, WEST)
		if(!compressor)
			stat |= BROKEN


#define TURBPRES 90000000
#define TURBGENQ 20000
#define TURBGENG 0.8

/obj/machinery/power/turbine/process()

	overlays = null
	if(stat & BROKEN)
		return

	lastgen = ((compressor.rpm / TURBGENQ)**TURBGENG) *TURBGENQ
	add_avail(lastgen)

	if(compressor.gas.temperature > (T20C+50))
		var/newrpm = ((compressor.gas.temperature-T20C-50) * compressor.gas.tot_gas() / TURBPRES)*30000
		newrpm = max(0, newrpm)

		if(!compressor.starter || newrpm > 1000)
			compressor.rpmtarget = newrpm

	var/oamount = min(compressor.gas.tot_gas(), compressor.rpm/32000*compressor.capacity)

	compressor.gas.turf_add(outturf, oamount)

	outturf.firelevel = outturf.poison

	if(lastgen > 100)
		overlays += image('pipes.dmi', "turb-o", FLY_LAYER)


	for(var/mob/M in viewers(1, src))
		if ((M.client && M.machine == src))
			src.interact(M)


/obj/machinery/power/turbine/attack_hand(mob/user)

	add_fingerprint(user)

	if(stat & (BROKEN | NOPOWER)) return

	interact(user)

/obj/machinery/power/turbine/proc/interact(mob/user)

	if ( (get_dist(src, user) > 1 ) || (stat & (NOPOWER|BROKEN)) )
		user.machine = null
		user << browse(null, "window=turbine")
		return

	user.machine = src

	var/t = "<TT><B>Gas Turbine Generator</B><HR><PRE>"

	var/gen = max(0, lastgen - (compressor.starter * COMPSTARTERLOAD) )
	t += "Generated power : [round(gen)] W<BR><BR>"

	t += "Turbine: [round(compressor.rpm)] RPM<BR>"

	t += "Starter: [ compressor.starter ? "<A href='?src=\ref[src];str=1'>Off</A> <B>On</B>" : "<B>Off</B> <A href='?src=\ref[src];str=1'>On</A>"]<BR>"

	//t += "Gas: [compressor.gas.tostring()]<BR>"

	t += "</PRE><HR><A href='?src=\ref[src];close=1'>Close</A>"

	t += "</TT>"
	user << browse(t, "window=turbine")

	return

/obj/machinery/power/turbine/Topic(href, href_list)
	..()
	if(stat & BROKEN)
		return
	if (usr.stat || usr.restrained() )
		return
	if ((!( istype(usr, /mob/human) ) && (!( ticker ) || (ticker && ticker.mode != "monkey"))))
		usr << "\red You don't have the dexterity to do this!"
		return

	if (( usr.machine==src && (get_dist(src, usr) <= 1 && istype(src.loc, /turf))))


		if( href_list["close"] )
			usr << browse(null, "window=turbine")
			usr.machine = null
			return

		else if( href_list["str"] )
			compressor.starter = !compressor.starter

		spawn(0)
			for(var/mob/M in viewers(1, src))
				if ((M.client && M.machine == src))
					src.interact(M)

	else
		usr << browse(null, "window=turbine")
		usr.machine = null

	return