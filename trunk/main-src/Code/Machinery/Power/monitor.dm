/*
 *	Power Monitor - reports the available power, load, and status of APCs on the same power network.
 *
 *	TODO: Make the power monitor also able to remote-control APCs (with sufficient ID access) to shut down things remotely.
 */

obj/machinery/power/monitor
	name = "power monitoring computer"
	icon = 'stationobjs.dmi'
	icon_state = "power_computer"
	density = 1
	anchored = 1


	// Attack with hand, show report window

	attack_hand(mob/user)
		add_fingerprint(user)

		if(stat & (BROKEN|NOPOWER))
			return
		interact(user)


	// Show the interaction window to the user

	proc/interact(mob/user)

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


	// Handle topic links from the interaction window (close only at the moment)

	Topic(href, href_list)
		..()
		if( href_list["close"] )
			usr << browse(null, "window=powcomp")
			usr.machine = null
			return

	// Timed process - use power, update window to viewers

	process()
		if(!(stat & (NOPOWER|BROKEN)) )

			use_power(250)


		for(var/mob/M in viewers(1, src))
			if ((M.client && M.machine == src))
				src.interact(M)


	// Power changed in location area - update icon to unpowered state, set stat

	power_change()

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
