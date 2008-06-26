/obj/item/weapon/weldingtool
	flags = 322.0
	force = 3.0
	icon_state = "welder"
	name = "weldingtool"
	throwforce = 5.0
	throwspeed = 5.0
	w_class = 2.0
	var/welding = 0.0
	var/weldfuel = 20.0
	
	afterattack(obj/O, mob/user)
		if (src.welding)
			src.weldfuel--
			if (src.weldfuel <= 0)
				usr << "\blue Need more fuel!"
				src.welding = 0
				src.force = 3
				src.damtype = "brute"
				src.icon_state = "welder"
			var/turf/location = user.loc
			if (!( istype(location, /turf) ))
				return
			location.firelevel = location.poison + 1
	
	attack_self(mob/user)
		src.welding = !( src.welding )
		if (src.welding)
			if (src.weldfuel <= 0)
				user << "\blue Need more fuel!"
				src.welding = 0
				return 0
			user << "\blue You will now weld when you attack."
			src.force = 15
			src.damtype = "fire"
			src.icon_state = "welder1"
		else
			user << "\blue Not welding anymore."
			src.force = 3
			src.damtype = "brute"
			src.icon_state = "welder"
	
	examine()
		set src in usr
		usr << text("\icon[] [] contains [] units of fuel left!", src,src.name, src.weldfuel)

