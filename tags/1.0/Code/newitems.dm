/obj/item/weapon/t_scanner/attack_self(mob/user)

	on = !on
	icon_state = "t-scanner[on]"

	if(on)
		src.process()


/obj/item/weapon/t_scanner/proc/process()

	while(on)
		for(var/turf/T in range(1, src.loc) )

			if(!T.intact)
				continue

			for(var/obj/O in T.contents)

				if(O.level != 1)
					continue

				if(O.invisibility == 101)
					O.invisibility = 0
					spawn(10)
						if(O)
							var/turf/U = O.loc
							if(U.intact)
								O.invisibility = 101

			var/mob/human/M = locate() in T
			if(M && M.invisibility == 2)
				M.invisibility = 0
				spawn(2)
					if(M)
						M.invisibility = 2


		sleep(10)



// test flashlight object
/obj/item/weapon/flashlight/attack_self(mob/user)

	on = !on
	icon_state = "flight[on]"
	if(on)
		src.process()

/obj/item/weapon/flashlight/proc/process()
	lastHolder = null

	while(on)
		var/atom/holder = loc
		var/isHeld = 0
		if (ismob(holder))
			isHeld=1
		else
			isHeld=0
			if (lastHolder!=null)
				lastHolder:luminosity = 0
				lastHolder = null
		if (isHeld==1)
			if (holder!=lastHolder && lastHolder!=null)
				lastHolder:luminosity = 0
			holder:luminosity = 5
			lastHolder = holder

		luminosity = 5

		sleep(10)
	if (lastHolder!=null)
		lastHolder:luminosity = 0
		lastHolder = null
	luminosity = 0;


