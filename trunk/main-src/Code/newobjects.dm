/obj/New()
	..()
//	mod = new(src)			// creates a module datum for this obj of type




/obj/machinery/cell_charger/attackby(obj/item/weapon/W, mob/user)

	if(stat & BROKEN) return

	if(istype(W, /obj/item/weapon/cell))
		if(charging)
			user << "There is already a cell in the charger."
			return
		else
			user.drop_item()
			W.loc = src
			charging = W
			user << "You insert the cell into the charger."
			chargelevel = -1


		updateicon()


/obj/machinery/cell_charger/proc/updateicon()

	icon_state = "ccharger[charging ? 1 : 0]"

	if(charging && !(stat & (BROKEN|NOPOWER)) )

		var/newlevel = 	round( charging.percent() * 4.0 / 99 )
		//world << "nl: [newlevel]"

		if(chargelevel != newlevel)

			overlays = null
			overlays += image('power.dmi', "ccharger-o[newlevel]")

			chargelevel = newlevel

	else
		overlays = null



/obj/machinery/cell_charger/attack_hand(mob/user)

	add_fingerprint(user)

	if(stat & BROKEN) return

	if(charging)
		charging.loc = usr
		charging.layer = 20
		if (user.hand )
			user.l_hand = charging
		else
			user.r_hand = charging

		charging.add_fingerprint(user)
		charging.updateicon()

		src.charging = null
		user << "You remove the cell from the charger."
		chargelevel = -1
		updateicon()


/obj/machinery/cell_charger/process()

	//world << "ccpt [charging] [stat]"
	if(!charging || (stat & (BROKEN|NOPOWER)) )
		return

	var/newch = charging.charge + 5

	newch = min(newch, charging.maxcharge)



	use_power((newch - charging.charge) / CELLRATE)


	//world << "ccpt: [newch], used [(newch - charging.charge) / CELLRATE]"

	charging.charge = newch

	updateicon()


